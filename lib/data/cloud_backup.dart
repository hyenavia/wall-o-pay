import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart'
    show CollectionReference, FirebaseFirestore;
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_database.dart';
import '../core/l10n.dart';
import 'cloud.dart';
import 'profile.dart';
import 'budget_rule.dart';
import 'prefs.dart';
import 'providers.dart';

class NoCloudBackupException implements Exception {
  const NoCloudBackupException();

  @override
  String toString() => trG('No backup found in the cloud for this account.');
}

/// Backup dan restore manual ke Firestore: users/{uid}/{tabel}/{id}.
/// Hanya berjalan saat pengguna menekan tombol; tidak ada sinkronisasi otomatis.
class CloudBackupService {
  CloudBackupService(this._db);

  final AppDatabase _db;

  static const _timeout = Duration(seconds: 30);
  static final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0);

  static String _key(String uid) => 'last_backup_$uid';

  static Future<DateTime?> lastBackup(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_key(uid));
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> saveLastBackup(String uid, DateTime at) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(uid), at.millisecondsSinceEpoch);
  }

  /// Unggah data lokal yang belum ada atau lebih baru dibanding di cloud.
  /// Data cloud yang lebih baru tidak akan tertimpa. Mengembalikan jumlah
  /// baris yang diunggah.
  Future<int> backup(String uid) async {
    final root = FirebaseFirestore.instance.collection('users').doc(uid);
    var uploaded = 0;

    for (final t in _db.syncTables) {
      final col = root.collection(t.name);

      final remote = <String, int>{};
      final snap = await col.get().timeout(_timeout);
      for (final doc in snap.docs) {
        remote[doc.id] = (doc.data()['updatedAt'] as num?)?.toInt() ?? 0;
      }

      final rows = await t.changed(_epoch);
      final toUpload = rows.where((r) {
        final remoteMs = remote[r['id'] as String];
        return remoteMs == null || (r['updatedAt'] as num).toInt() > remoteMs;
      }).toList();

      await _push(col, toUpload);
      uploaded += toUpload.length;
    }
    return uploaded;
  }

  /// Tarik data dari cloud lalu gabungkan ke database lokal.
  /// Jika ada data yang sama, yang terakhir diubah menang. Mengembalikan
  /// jumlah baris lokal yang ditambah atau diperbarui.
  Future<int> restore(String uid) async {
    final root = FirebaseFirestore.instance.collection('users').doc(uid);
    var found = 0;
    var applied = 0;

    for (final t in _db.syncTables) {
      final snap = await root.collection(t.name).get().timeout(_timeout);
      found += snap.docs.length;
      for (final doc in snap.docs) {
        if (await t.applyRemote(doc.data())) applied++;
      }
    }
    if (found == 0) throw const NoCloudBackupException();
    return applied;
  }

  Future<void> _push(
    CollectionReference<Map<String, dynamic>> col,
    List<Map<String, dynamic>> rows,
  ) async {
    for (var i = 0; i < rows.length; i += 400) {
      final batch = FirebaseFirestore.instance.batch();
      for (final r in rows.skip(i).take(400)) {
        batch.set(col.doc(r['id'] as String), r);
      }
      await batch.commit().timeout(_timeout);
    }
  }
}

class BackupState {
  const BackupState({this.working = false, this.lastBackup});

  final bool working;
  final DateTime? lastBackup;
}

/// Menjalankan backup/restore cloud atas permintaan pengguna dan
/// mengembalikan pesan hasil untuk ditampilkan di UI.
class CloudBackupController extends Notifier<BackupState> {
  DateTime? _last;

  @override
  BackupState build() {
    final user = ref.watch(currentUserProvider);
    if (user != null) {
      Future.microtask(() async {
        _last = await CloudBackupService.lastBackup(user.uid);
        state = BackupState(working: state.working, lastBackup: _last);
      });
    }
    return const BackupState();
  }

  Future<String> backup() {
    return _run((service, uid) async {
      final n = await service.backup(uid);
      await ref.read(profileProvider.notifier).uploadToCloud(uid);
      await ref.read(budgetRuleProvider.notifier).uploadToCloud(uid);
      await ref.read(appPrefsProvider.notifier).uploadToCloud(uid);
      _last = DateTime.now();
      await CloudBackupService.saveLastBackup(uid, _last!);
      if (n == 0) return trG('Your cloud backup is already up to date.');
      return n == 1
          ? trG('Backed up 1 item to the cloud.')
          : trG('Backed up {n} items to the cloud.', {'n': n});
    });
  }

  Future<String> restore() {
    return _run((service, uid) async {
      final n = await service.restore(uid);
      await ref.read(profileProvider.notifier).restoreFromCloud(uid);
      await ref.read(budgetRuleProvider.notifier).restoreFromCloud(uid);
      await ref.read(appPrefsProvider.notifier).restoreFromCloud(uid);
      if (n == 0) return trG('This device already has everything from your cloud backup.');
      return n == 1
          ? trG('Restored 1 item from the cloud.')
          : trG('Restored {n} items from the cloud.', {'n': n});
    });
  }

  Future<String> _run(
    Future<String> Function(CloudBackupService service, String uid) body,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return trG('Please log in first.');
    if (state.working) return trG('Another operation is still running.');

    state = BackupState(working: true, lastBackup: _last);
    try {
      return await body(CloudBackupService(ref.read(databaseProvider)), user.uid);
    } catch (e) {
      return trG('Failed: {error}', {'error': _friendly(e)});
    } finally {
      state = BackupState(working: false, lastBackup: _last);
    }
  }

  String _friendly(Object e) {
    if (e is TimeoutException) return trG('No internet connection.');
    if (e is NoCloudBackupException) return e.toString();
    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        return trG('Access denied. Check your Firestore rules.');
      }
      if (e.code == 'unavailable') return trG('Server unreachable.');
      return e.message ?? e.code;
    }
    return '$e';
  }
}

final cloudBackupProvider =
    NotifierProvider<CloudBackupController, BackupState>(CloudBackupController.new);
