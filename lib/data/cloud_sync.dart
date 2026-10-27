import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'cloud_backup.dart';
import 'profile.dart';
import 'providers.dart';

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
  Timer? _debounceTimer;
  Timer? _periodicTimer;
  final List<StreamSubscription> _subscriptions = [];
  String? _currentUid;

  static const _timeout = Duration(seconds: 20);

  /// Memulai sinkronisasi otomatis untuk user yang sedang aktif.
  void startSync(String uid) {
    if (_currentUid == uid && _subscriptions.isNotEmpty) return;
    stopSync();

    _currentUid = uid;
    debugPrint('[AutoSync] Starting sync session for user: $uid');

    // 1. Dengarkan perubahan tabel lokal Drift untuk auto-push ke cloud
    final localSub = _db.tableUpdates().listen((updates) {
      if (_isApplyingRemote) return;
      final syncTableNames = {
        'categories',
        'transactions',
        'budgets',
        'savings_goals',
        'savingsGoals',
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

    // 4. Dengarkan perubahan konektivitas jaringan (deteksi internet kembali aktif)
    final connSub = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        debugPrint('[AutoSync] Network reconnected! Triggering instant auto-sync...');
        triggerTwoWaySync();
      }
    });
    _subscriptions.add(connSub);

    // 5. Timer periodik keamanan setiap 60 detik
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_currentUid != null && !_isSyncing) {
        triggerTwoWaySync();
      }
    });

    // 6. Jalankan sinkronisasi awal dua arah (pull remote + push local)
    triggerTwoWaySync();
  }

  /// Menghentikan seluruh listener saat user logout.
  void stopSync() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _periodicTimer?.cancel();
    _periodicTimer = null;
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
    final uid = _currentUid;
    if (uid == null || _isSyncing) return;

    _isSyncing = true;
    _ref.read(syncStateProvider.notifier).update(
          _ref.read(syncStateProvider).copyWith(status: SyncStatus.syncing),
        );

    try {
      final root = FirebaseFirestore.instance.collection('users').doc(uid);

      // Langkah 1: PULL (Tarik data cloud ke lokal)
      try {
        await _ref.read(profileProvider.notifier).restoreFromCloud(uid);
      } catch (e) {
        debugPrint('[AutoSync] Warning restoring profile: $e');
      }

      for (final t in _db.syncTables) {
        try {
          final snap = await root.collection(t.name).get().timeout(_timeout);
          _isApplyingRemote = true;
          try {
            for (final doc in snap.docs) {
              await t.applyRemote(doc.data());
            }
          } finally {
            _isApplyingRemote = false;
          }
        } catch (e) {
          debugPrint('[AutoSync] Warning pulling table ${t.name}: $e');
        }
      }

      // Langkah 2: PUSH (Unggah data lokal yang belum ada / lebih baru di cloud)
      try {
        await _ref.read(profileProvider.notifier).uploadToCloud(uid);
      } catch (e) {
        debugPrint('[AutoSync] Warning uploading profile: $e');
      }

      for (final t in _db.syncTables) {
        try {
          final col = root.collection(t.name);
          final remote = <String, int>{};
          final snap = await col.get().timeout(_timeout);
          for (final doc in snap.docs) {
            remote[doc.id] = (doc.data()['updatedAt'] as num?)?.toInt() ?? 0;
          }

          final rows = await t.changed(DateTime.fromMillisecondsSinceEpoch(0));
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

      final now = DateTime.now();
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

  /// Hanya mengunggah data lokal yang berubah ke cloud.
  Future<void> _pushLocalOnly(String uid) async {
    if (_isSyncing) return;
    try {
      final root = FirebaseFirestore.instance.collection('users').doc(uid);
      await _ref.read(profileProvider.notifier).uploadToCloud(uid);

      for (final t in _db.syncTables) {
        final col = root.collection(t.name);
        final remote = <String, int>{};
        final snap = await col.get().timeout(_timeout);
        for (final doc in snap.docs) {
          remote[doc.id] = (doc.data()['updatedAt'] as num?)?.toInt() ?? 0;
        }

        final rows = await t.changed(DateTime.fromMillisecondsSinceEpoch(0));
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
      }
      final now = DateTime.now();
      await CloudBackupService.saveLastBackup(uid, now);
      _ref.read(syncStateProvider.notifier).update(SyncState(
            status: SyncStatus.synced,
            lastSynced: now,
          ));
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
