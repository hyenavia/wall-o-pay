/// Layanan sinkronisasi dua arah otomatis (real-time & latar belakang) antara Drift SQLite lokal
/// dan Cloud Firestore, termasuk penanganan pergantian akun dan pemulihan saat internet aktif kembali.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_database.dart';
import '../core/l10n.dart';
import 'cloud.dart';
import 'cloud_backup.dart';
import 'profile.dart';
import 'providers.dart';
import 'budget_rule.dart';
import 'lock.dart';
import 'prefs.dart';
import 'recurring_service.dart';

/// Status sinkronisasi real-time otomatis.
enum SyncStatus { idle, syncing, synced, error }

class SyncState {
  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSynced,
    this.errorMessage,
  });

  final SyncStatus status;
  final DateTime? lastSynced;
  final String? errorMessage;

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSynced,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSynced: lastSynced ?? this.lastSynced,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Service untuk menangani sinkronisasi dua arah otomatis antara Drift SQLite lokal
/// dan Firebase Firestore di latar belakang secara transparan dan real-time.
class AutoSyncService {
  AutoSyncService(this._ref);

  final Ref _ref;
  AppDatabase get _db => _ref.read(databaseProvider);

  bool _isApplyingRemote = false;
  bool _isSyncing = false;
  bool discardGuestDataOnNextLogin = false;
  Timer? _debounceTimer;
  final List<StreamSubscription> _subscriptions = [];
  String? _currentUid;
  DateTime _lastPushedAt = DateTime.fromMillisecondsSinceEpoch(0);

  static const _timeout = Duration(seconds: 20);
  static const _cursorOverlapMs = 30000;

  /// Kunci SharedPreferences untuk menyimpan cursor incremental pull Firestore per akun.
  static String pullCursorKey(String uid) => 'sync_pull_cursor_$uid';

  /// Menghitung batas waktu `updatedAt` (ms) untuk query incremental pull Firestore
  /// dengan overlap buffer 30 detik guna mengantisipasi clock skew antar perangkat.
  /// Mengembalikan `null` jika belum ada cursor (menandakan pull penuh pertama kali).
  static int? computeIncrementalPullSinceMs(
    int? lastCursorMs, {
    int overlapMs = _cursorOverlapMs,
  }) {
    if (lastCursorMs == null || lastCursorMs <= 0) return null;
    final shifted = lastCursorMs - overlapMs;
    return shifted < 0 ? 0 : shifted;
  }

  /// Menghitung nilai cursor berikutnya berdasarkan cursor sebelumnya, max `updatedAt`
  /// dokumen yang ditarik, dan timestamp dimulainya sinkronisasi.
  static int computeNextPullCursorMs({
    required int previousCursorMs,
    required Iterable<int> pulledUpdatedAtMs,
    required int syncStartedMs,
  }) {
    var maxCursor = previousCursorMs > syncStartedMs ? previousCursorMs : syncStartedMs;
    for (final ms in pulledUpdatedAtMs) {
      if (ms > maxCursor) maxCursor = ms;
    }
    return maxCursor;
  }

  /// Menghapus cursor incremental pull agar sinkronisasi berikutnya menarik penuh.
  static Future<void> clearPullCursor(SharedPreferences prefs, String uid) =>
      prefs.remove(pullCursorKey(uid));

  /// Memulai sinkronisasi otomatis untuk user yang sedang aktif.
  void startSync(String uid) async {
    if (_currentUid == uid && _subscriptions.isNotEmpty) return;
    stopSync();

    _currentUid = uid;
    debugPrint('[AutoSync] Starting sync session for user: $uid');

    // Muat riwayat push terakhir untuk membatasi query push lokal
    try {
      final lastBackup = await CloudBackupService.lastBackup(uid);
      _lastPushedAt = lastBackup ?? DateTime.fromMillisecondsSinceEpoch(0);
    } catch (_) {}

    // Cek apakah terjadi pergantian akun atau sesi baru pada perangkat ini
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final lastUid = prefs.getString('current_sync_user_id');
      if (lastUid != uid) {
        debugPrint('[AutoSync] Account switch or new session ($lastUid -> $uid). Preparing local data...');
        if (lastUid != null) {
          await clearPullCursor(prefs, lastUid);
          await _db.resetAllData();
        } else if (discardGuestDataOnNextLogin) {
          discardGuestDataOnNextLogin = false;
          await _db.resetAllData();
          await _ref.read(profileProvider.notifier).clearLocal(ProfileController.guestId);
          await _ref.read(budgetRuleProvider.notifier).clearLocal();
          await Lock.instance.clearLocal('guest');
          await prefs.remove('onboarding_done_local');
        } else {
          await _ref.read(profileProvider.notifier).migrateGuestToUser(uid);
          await _ref.read(budgetRuleProvider.notifier).migrateGuestToUser(uid);
          await Lock.instance.migrateGuestToUser(uid);
          if (prefs.getBool('onboarding_done_local') == true) {
            await prefs.setBool('onboarding_done_$uid', true);
            await prefs.remove('onboarding_done_local');
          }
        }
        _ref.read(appPrefsProvider.notifier).loadForUser(uid);
        _ref.read(budgetRuleProvider.notifier).loadForUser(uid);
        await Lock.instance.syncWithCloud(uid);
      }
      discardGuestDataOnNextLogin = false;
      await _ref.read(skipAuthProvider.notifier).reset();
      await prefs.setString('current_sync_user_id', uid);
    } catch (e) {
      debugPrint('[AutoSync] Error during account switch check: $e');
    }

    // 1. Dengarkan perubahan tabel lokal Drift untuk auto-push ke cloud
    final localSub = _db.tableUpdates().listen((updates) {
      if (_isApplyingRemote) return;
      final syncTableNames = {
        'categories',
        'wallets',
        'transactions',
        'budgets',
        'savings_goals',
        'savingsGoals',
        'recurring_rules',
        'recurringRules',
        'debts',
        'debt_payments',
        'debtPayments',
        'pending_transactions',
        'pendingTransactions',
        'tx_templates',
        'txTemplates',
      };
      final hasSyncTable = updates.any((u) => syncTableNames.contains(u.table));
      if (hasSyncTable) {
        schedulePush();
      }
    });
    _subscriptions.add(localSub);

    // 2. Dengarkan snapshot Firestore secara real-time untuk setiap tabel
    final root = FirebaseFirestore.instance.collection('users').doc(uid);
    for (final t in _db.syncTables) {
      final snapSub = root.collection(t.name).snapshots().listen((snap) async {
        for (final change in snap.docChanges) {
          // Abaikan perubahan lokal yang belum selesai ditulis ke server
          if (change.doc.metadata.hasPendingWrites) continue;
          if (change.type != DocumentChangeType.removed) {
            final data = change.doc.data();
            if (data != null) {
              _isApplyingRemote = true;
              try {
                await t.applyRemote(data);
              } catch (e) {
                debugPrint('[AutoSync] Error applying remote change for ${t.name}: $e');
              } finally {
                _isApplyingRemote = false;
              }
            }
          }
        }
      }, onError: (err) {
        debugPrint('[AutoSync] Real-time listener error for ${t.name}: $err');
      });
      _subscriptions.add(snapSub);
    }

    // 3. Dengarkan snapshot profil (nickname & foto)
    final profileSub = root
        .collection('meta')
        .doc('profile')
        .snapshots()
        .listen((snap) async {
      if (snap.metadata.hasPendingWrites) return;
      if (snap.exists) {
        try {
          await _ref.read(profileProvider.notifier).restoreFromCloud(uid);
        } catch (e) {
          debugPrint('[AutoSync] Error restoring profile snapshot: $e');
        }
      }
    }, onError: (err) {
      debugPrint('[AutoSync] Profile snapshot error: $err');
    });
    _subscriptions.add(profileSub);

    // 3b. Dengarkan snapshot konfigurasi anggaran
    final budgetSub = root
        .collection('meta')
        .doc('budgetConfig')
        .snapshots()
        .listen((snap) async {
      if (snap.metadata.hasPendingWrites) return;
      if (snap.exists && snap.data() != null) {
        try {
          _ref.read(budgetRuleProvider.notifier).applyRemoteData(snap.data()!, uid);
        } catch (e) {
          debugPrint('[AutoSync] Error restoring budgetConfig snapshot: $e');
        }
      }
    }, onError: (err) {
      debugPrint('[AutoSync] BudgetConfig snapshot error: $err');
    });
    _subscriptions.add(budgetSub);

    // 3c. Dengarkan snapshot personalisasi pengguna (tema, bahasa, periode, hari gajian)
    final prefSub = root
        .collection('meta')
        .doc('preferences')
        .snapshots()
        .listen((snap) async {
      if (snap.metadata.hasPendingWrites) return;
      if (snap.exists && snap.data() != null) {
        try {
          await _ref.read(appPrefsProvider.notifier).applyRemoteData(snap.data()!, uid);
        } catch (e) {
          debugPrint('[AutoSync] Error restoring preferences snapshot: $e');
        }
      }
    }, onError: (err) {
      debugPrint('[AutoSync] Preferences snapshot error: $err');
    });
    _subscriptions.add(prefSub);

    // 4. Dengarkan perubahan konektivitas jaringan (deteksi internet kembali aktif)
    final connSub = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        debugPrint('[AutoSync] Network reconnected! Triggering instant auto-sync...');
        triggerTwoWaySync();
      }
    });
    _subscriptions.add(connSub);

    // 5. Jalankan sinkronisasi awal dua arah (pull remote + push local)
    triggerTwoWaySync();
  }

  /// Menghentikan seluruh listener saat user logout.
  void stopSync() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _currentUid = null;
    debugPrint('[AutoSync] Stopped sync session');
  }

  /// Menjadwalkan push data lokal ke cloud dengan jeda debounce (1.5 detik).
  void schedulePush() {
    final uid = _currentUid;
    if (uid == null) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      _pushLocalOnly(uid);
    });
  }

  /// Melakukan sinkronisasi dua arah penuh (Pull Remote lalu Push Local).
  Future<void> triggerTwoWaySync() async {
    final uid = _currentUid ?? _ref.read(currentUserProvider)?.uid;
    if (uid == null || _isSyncing) return;
    _currentUid ??= uid;

    _isSyncing = true;
    _ref.read(syncStateProvider.notifier).update(
          _ref.read(syncStateProvider).copyWith(status: SyncStatus.syncing),
        );

    try {
      final root = FirebaseFirestore.instance.collection('users').doc(uid);
      final prefs = _ref.read(sharedPreferencesProvider);
      final syncStartedMs = DateTime.now().millisecondsSinceEpoch;
      final prevCursorMs = prefs.getInt(pullCursorKey(uid)) ?? 0;
      final candidateSinceMs = computeIncrementalPullSinceMs(prevCursorMs);
      final isIncrementalPull =
          candidateSinceMs != null && _lastPushedAt.millisecondsSinceEpoch > 0;
      final pulledUpdatedAtMs = <int>[];
      var allPullSucceeded = true;
      final remoteUpdatedMaps = <String, Map<String, int>>{};

      // Langkah 1: PULL (Tarik delta/penuh data cloud ke lokal dan rekam timestamp remote)
      try {
        await _ref.read(profileProvider.notifier).restoreFromCloud(uid);
      } catch (e) {
        debugPrint('[AutoSync] Warning restoring profile: $e');
      }

      try {
        await _ref.read(budgetRuleProvider.notifier).restoreFromCloud(uid);
      } catch (e) {
        debugPrint('[AutoSync] Warning restoring budgetConfig: $e');
      }

      try {
        await _ref.read(appPrefsProvider.notifier).restoreFromCloud(uid);
      } catch (e) {
        debugPrint('[AutoSync] Warning restoring preferences: $e');
      }

      for (final t in _db.syncTables) {
        try {
          final col = root.collection(t.name);
          final QuerySnapshot<Map<String, dynamic>> snap = isIncrementalPull
              ? await col
                  .where('updatedAt', isGreaterThan: candidateSinceMs)
                  .get()
                  .timeout(_timeout)
              : await col.get().timeout(_timeout);
          final remoteMap = <String, int>{};
          _isApplyingRemote = true;
          try {
            for (final doc in snap.docs) {
              final data = doc.data();
              final updatedMs = (data['updatedAt'] as num?)?.toInt() ?? 0;
              remoteMap[doc.id] = updatedMs;
              pulledUpdatedAtMs.add(updatedMs);
              await t.applyRemote(data);
            }
          } finally {
            _isApplyingRemote = false;
          }
          remoteUpdatedMaps[t.name] = remoteMap;
        } catch (e) {
          allPullSucceeded = false;
          debugPrint('[AutoSync] Warning pulling table ${t.name}: $e');
        }
      }

      if (allPullSucceeded) {
        final nextCursor = computeNextPullCursorMs(
          previousCursorMs: prevCursorMs,
          pulledUpdatedAtMs: pulledUpdatedAtMs,
          syncStartedMs: syncStartedMs,
        );
        await prefs.setInt(pullCursorKey(uid), nextCursor);
      }

      // Langkah 2: PUSH (Unggah data lokal yang belum ada / lebih baru di cloud)
      try {
        await _ref.read(profileProvider.notifier).uploadToCloud(uid);
      } catch (e) {
        debugPrint('[AutoSync] Warning uploading profile: $e');
      }

      try {
        await _ref.read(budgetRuleProvider.notifier).uploadToCloud(uid);
      } catch (e) {
        debugPrint('[AutoSync] Warning uploading budgetConfig: $e');
      }

      try {
        await _ref.read(appPrefsProvider.notifier).uploadToCloud(uid);
      } catch (e) {
        debugPrint('[AutoSync] Warning uploading preferences: $e');
      }

      final localPushSince = isIncrementalPull
          ? _lastPushedAt.subtract(const Duration(seconds: 5))
          : DateTime.fromMillisecondsSinceEpoch(0);

      for (final t in _db.syncTables) {
        try {
          final col = root.collection(t.name);
          // Pakai cache remote map dari Langkah 1 agar efisien biaya read Firestore
          final remote = remoteUpdatedMaps[t.name] ?? const {};

          final rows = await t.changed(localPushSince);
          final toUpload = rows.where((r) {
            final remoteMs = remote[r['id'] as String];
            return remoteMs == null || (r['updatedAt'] as num).toInt() > remoteMs;
          }).toList();

          if (toUpload.isNotEmpty) {
            for (var i = 0; i < toUpload.length; i += 400) {
              final batch = FirebaseFirestore.instance.batch();
              for (final r in toUpload.skip(i).take(400)) {
                batch.set(col.doc(r['id'] as String), r);
              }
              await batch.commit().timeout(_timeout);
            }
          }
        } catch (e) {
          debugPrint('[AutoSync] Warning pushing table ${t.name}: $e');
        }
      }

      // Periksa transaksi berulang yang jatuh tempo
      await RecurringService.checkAndGenerateDue(_db);

      final now = DateTime.now();
      _lastPushedAt = now;
      await CloudBackupService.saveLastBackup(uid, now);
      _ref.read(syncStateProvider.notifier).update(SyncState(
            status: SyncStatus.synced,
            lastSynced: now,
          ));
    } catch (e) {
      debugPrint('[AutoSync] Sync error: $e');
      _ref.read(syncStateProvider.notifier).update(
            _ref.read(syncStateProvider).copyWith(
                  status: SyncStatus.error,
                  errorMessage: e.toString(),
                ),
          );
    } finally {
      _isSyncing = false;
    }
  }

  /// Mengunggah paksa seluruh data lokal (profil, preferensi, anggaran, dan seluruh tabel SQLite) ke cloud Firestore.
  /// Mengembalikan jumlah baris data yang berhasil diunggah.
  Future<int> pushAllLocalToCloud() async {
    final uid = _currentUid ?? _ref.read(currentUserProvider)?.uid;
    if (uid == null) {
      throw Exception(trG('Please log in first.'));
    }
    _currentUid ??= uid;
    if (_isSyncing) {
      throw Exception(trG('Another operation is still running.'));
    }

    _isSyncing = true;
    _ref.read(syncStateProvider.notifier).update(
          _ref.read(syncStateProvider).copyWith(status: SyncStatus.syncing),
        );

    try {
      final root = FirebaseFirestore.instance.collection('users').doc(uid);
      var totalUploaded = 0;

      // 1. Profil, anggaran, dan preferensi
      await _ref.read(profileProvider.notifier).uploadToCloud(uid);
      await _ref.read(budgetRuleProvider.notifier).uploadToCloud(uid);
      await _ref.read(appPrefsProvider.notifier).uploadToCloud(uid);
      totalUploaded += 3;

      // 2. Seluruh tabel Drift SQLite
      for (final t in _db.syncTables) {
        final col = root.collection(t.name);
        final rows = await t.changed(DateTime.fromMillisecondsSinceEpoch(0));
        if (rows.isNotEmpty) {
          for (var i = 0; i < rows.length; i += 400) {
            final batch = FirebaseFirestore.instance.batch();
            for (final r in rows.skip(i).take(400)) {
              batch.set(col.doc(r['id'] as String), r);
            }
            await batch.commit().timeout(_timeout);
          }
          totalUploaded += rows.length;
        }
      }

      await RecurringService.checkAndGenerateDue(_db);

      final now = DateTime.now();
      await CloudBackupService.saveLastBackup(uid, now);
      _ref.read(syncStateProvider.notifier).update(SyncState(
            status: SyncStatus.synced,
            lastSynced: now,
          ));
      return totalUploaded;
    } catch (e) {
      debugPrint('[AutoSync] Error during pushAllLocalToCloud: $e');
      _ref.read(syncStateProvider.notifier).update(
            _ref.read(syncStateProvider).copyWith(
                  status: SyncStatus.error,
                  errorMessage: e.toString(),
                ),
          );
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Menarik paksa seluruh data dari Firestore ke database lokal.
  /// Mengembalikan jumlah baris yang berhasil diterapkan ke database lokal.
  Future<int> pullAllRemoteToLocal() async {
    final uid = _currentUid ?? _ref.read(currentUserProvider)?.uid;
    if (uid == null) {
      throw Exception(trG('Please log in first.'));
    }
    _currentUid ??= uid;
    if (_isSyncing) {
      throw Exception(trG('Another operation is still running.'));
    }

    _isSyncing = true;
    _ref.read(syncStateProvider.notifier).update(
          _ref.read(syncStateProvider).copyWith(status: SyncStatus.syncing),
        );

    try {
      final root = FirebaseFirestore.instance.collection('users').doc(uid);
      final prefs = _ref.read(sharedPreferencesProvider);
      final syncStartedMs = DateTime.now().millisecondsSinceEpoch;
      await clearPullCursor(prefs, uid);
      final pulledUpdatedAtMs = <int>[];
      var totalRestored = 0;

      await _ref.read(profileProvider.notifier).restoreFromCloud(uid);
      await _ref.read(budgetRuleProvider.notifier).restoreFromCloud(uid);
      await _ref.read(appPrefsProvider.notifier).restoreFromCloud(uid);

      for (final t in _db.syncTables) {
        final snap = await root.collection(t.name).get().timeout(_timeout);
        _isApplyingRemote = true;
        try {
          for (final doc in snap.docs) {
            final data = doc.data();
            pulledUpdatedAtMs.add((data['updatedAt'] as num?)?.toInt() ?? 0);
            final applied = await t.applyRemote(data);
            if (applied) totalRestored++;
          }
        } finally {
          _isApplyingRemote = false;
        }
      }

      await prefs.setInt(
        pullCursorKey(uid),
        computeNextPullCursorMs(
          previousCursorMs: 0,
          pulledUpdatedAtMs: pulledUpdatedAtMs,
          syncStartedMs: syncStartedMs,
        ),
      );

      await RecurringService.checkAndGenerateDue(_db);

      final now = DateTime.now();
      await CloudBackupService.saveLastBackup(uid, now);
      _ref.read(syncStateProvider.notifier).update(SyncState(
            status: SyncStatus.synced,
            lastSynced: now,
          ));
      return totalRestored;
    } catch (e) {
      debugPrint('[AutoSync] Error during pullAllRemoteToLocal: $e');
      _ref.read(syncStateProvider.notifier).update(
            _ref.read(syncStateProvider).copyWith(
                  status: SyncStatus.error,
                  errorMessage: e.toString(),
                ),
          );
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Menghapus seluruh data pengguna dari Cloud Firestore (dipanggil saat 'Keluar & hapus data').
  static Future<void> wipeCloudUserData(String uid) async {
    try {
      final root = FirebaseFirestore.instance.collection('users').doc(uid);
      final collections = [
        'categories',
        'wallets',
        'transactions',
        'budgets',
        'savingsGoals',
        'savings_goals',
        'recurringRules',
        'recurring_rules',
        'debts',
        'debtPayments',
        'debt_payments',
        'txTemplates',
        'tx_templates',
        'pendingTransactions',
        'pending_transactions',
      ];

      for (final colName in collections) {
        try {
          final snap = await root.collection(colName).get().timeout(const Duration(seconds: 15));
          if (snap.docs.isEmpty) continue;
          for (var i = 0; i < snap.docs.length; i += 400) {
            final batch = FirebaseFirestore.instance.batch();
            for (final doc in snap.docs.skip(i).take(400)) {
              batch.delete(doc.reference);
            }
            await batch.commit();
          }
        } catch (e) {
          debugPrint('[AutoSync] Error wiping collection $colName: $e');
        }
      }

      final metaDocs = ['profile', 'security', 'budgetConfig', 'preferences'];
      final metaBatch = FirebaseFirestore.instance.batch();
      for (final m in metaDocs) {
        metaBatch.delete(root.collection('meta').doc(m));
      }
      try {
        await metaBatch.commit();
      } catch (e) {
        debugPrint('[AutoSync] Error wiping meta docs: $e');
      }

      // Hapus pemetaan username di Firestore jika masih ada
      try {
        final usernameSnap = await FirebaseFirestore.instance
            .collection('usernames')
            .where('uid', isEqualTo: uid)
            .get()
            .timeout(const Duration(seconds: 10));
        for (final doc in usernameSnap.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint('[AutoSync] Error wiping username mapping: $e');
      }

      // Hapus dokumen root pengguna
      try {
        await root.delete().timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('[AutoSync] Error wiping root user doc: $e');
      }

      debugPrint('[AutoSync] Successfully wiped all cloud data for user: $uid');
    } catch (e) {
      debugPrint('[AutoSync] Error wiping cloud data: $e');
    }
  }

  Future<void> _pushLocalOnly(String uid) async {
    if (_isSyncing || _isApplyingRemote) return;
    try {
      final root = FirebaseFirestore.instance.collection('users').doc(uid);
      // Query hanya data lokal yang diperbarui sejak push terakhir (beri buffer 5 detik untuk clock skew)
      final since = _lastPushedAt.subtract(const Duration(seconds: 5));
      var hasChanges = false;

      for (final t in _db.syncTables) {
        final rows = await t.changed(since);
        if (rows.isNotEmpty) {
          hasChanges = true;
          final col = root.collection(t.name);
          for (var i = 0; i < rows.length; i += 400) {
            final batch = FirebaseFirestore.instance.batch();
            for (final r in rows.skip(i).take(400)) {
              batch.set(col.doc(r['id'] as String), r);
            }
            await batch.commit().timeout(_timeout);
          }
        }
      }

      // Periksa transaksi berulang yang jatuh tempo
      await RecurringService.checkAndGenerateDue(_db);

      final now = DateTime.now();
      _lastPushedAt = now;
      if (hasChanges) {
        await CloudBackupService.saveLastBackup(uid, now);
        _ref.read(syncStateProvider.notifier).update(SyncState(
              status: SyncStatus.synced,
              lastSynced: now,
            ));
      }
    } catch (e) {
      debugPrint('[AutoSync] Background push error: $e');
    }
  }
}

class SyncStateNotifier extends Notifier<SyncState> {
  @override
  SyncState build() => const SyncState();

  void update(SyncState next) => state = next;
}

final syncStateProvider =
    NotifierProvider<SyncStateNotifier, SyncState>(SyncStateNotifier.new);

final autoSyncServiceProvider = Provider<AutoSyncService>((ref) {
  final service = AutoSyncService(ref);
  ref.onDispose(service.stopSync);
  return service;
});
