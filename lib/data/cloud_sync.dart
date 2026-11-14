/// Layanan sinkronisasi dua arah otomatis (real-time & latar belakang) antara Drift SQLite lokal
/// dan Cloud Firestore, termasuk penanganan pergantian akun dan pemulihan saat internet aktif kembali.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
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

  int _applyingRemoteCount = 0;
  bool get _isApplyingRemote => _applyingRemoteCount > 0;
  Future<void> _remoteApplyQueue = Future<void>.value();

  bool _isSyncing = false;
  int _syncRunSeq = 0;
  int _activeSyncSeq = 0;

  bool discardGuestDataOnNextLogin = false;
  Timer? _debounceTimer;
  final List<StreamSubscription> _subscriptions = [];
  String? _currentUid;
  String? _startingUid;
  Future<void>? _startInFlight;
  Future<void>? _twoWayInFlight;
  String? _twoWayUid;
  int _sessionEpoch = 0;
  DateTime _lastPushedAt = DateTime.fromMillisecondsSinceEpoch(0);

  Future<T> _runRemoteWrite<T>(Future<T> Function() fn) async {
    _applyingRemoteCount++;
    try {
      return await fn();
    } finally {
      if (_applyingRemoteCount > 0) _applyingRemoteCount--;
    }
  }

  Future<void> _enqueueRemoteSnapshotApply(
    int epoch,
    String uid,
    Future<void> Function() fn,
  ) {
    final next = _remoteApplyQueue.then((_) async {
      if (epoch != _sessionEpoch || _currentUid != uid) return;
      await _runRemoteWrite(fn);
    });
    _remoteApplyQueue = next.catchError((_) {});
    return next;
  }

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

  void _clearSessionResources() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  /// Memulai sinkronisasi otomatis untuk user yang sedang aktif.
  /// Mengembalikan [Future<void>] agar pemanggil dapat menunggu sesi siap dan
  /// mencegah eksekusi paralel untuk UID yang sama maupun konflik pergantian akun.
  Future<void> startSync(String uid) async {
    while (true) {
      if (_currentUid == uid &&
          _subscriptions.isNotEmpty &&
          _startInFlight == null) {
        return;
      }

      final existing = _startInFlight;
      if (existing != null) {
        if (_startingUid == uid) {
          return existing;
        }
        // Pergantian UID saat startSync lain masih berjalan: batalkan sesi lama lalu tunggu selesai.
        stopSync();
        try {
          await existing;
        } catch (_) {}
        continue;
      }
      break;
    }

    final epoch = ++_sessionEpoch;
    _startingUid = uid;
    late final Future<void> run;
    run = _startSyncImpl(uid, epoch).whenComplete(() {
      if (identical(_startInFlight, run)) {
        _startInFlight = null;
        _startingUid = null;
      }
    });
    _startInFlight = run;
    return run;
  }

  Future<void> _startSyncImpl(String uid, int epoch) async {
    _clearSessionResources();
    _currentUid = uid;
    debugPrint('[AutoSync] Starting sync session for user: $uid');

    // Muat riwayat push terakhir untuk membatasi query push lokal
    try {
      final lastBackup = await CloudBackupService.lastBackup(uid);
      if (epoch != _sessionEpoch) return;
      _lastPushedAt = lastBackup ?? DateTime.fromMillisecondsSinceEpoch(0);
    } catch (_) {
      if (epoch != _sessionEpoch) return;
      _lastPushedAt = DateTime.fromMillisecondsSinceEpoch(0);
    }

    // Cek apakah terjadi pergantian akun atau sesi baru pada perangkat ini
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final lastUid = prefs.getString('current_sync_user_id');
      if (lastUid != uid) {
        debugPrint('[AutoSync] Account switch or new session ($lastUid -> $uid). Preparing local data...');
        if (lastUid != null) {
          await prefs.remove('current_sync_user_id');
          await clearPullCursor(prefs, lastUid);
          await _db.resetAllData();
        } else if (discardGuestDataOnNextLogin) {
          discardGuestDataOnNextLogin = false;
          await prefs.remove('current_sync_user_id');
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
        if (epoch != _sessionEpoch) return;
        _ref.read(appPrefsProvider.notifier).loadForUser(uid);
        _ref.read(budgetRuleProvider.notifier).loadForUser(uid);
        await Lock.instance.syncWithCloud(uid);
      }
      if (epoch != _sessionEpoch) return;
      discardGuestDataOnNextLogin = false;
      await _ref.read(skipAuthProvider.notifier).reset();
      if (epoch != _sessionEpoch) return;
      await prefs.setString('current_sync_user_id', uid);
    } catch (e) {
      debugPrint('[AutoSync] Error during account switch check: $e');
    }

    if (epoch != _sessionEpoch || _currentUid != uid) return;

    if (Firebase.apps.isEmpty) {
      debugPrint('[AutoSync] Firebase is not initialized; skipping remote sync listeners.');
      return;
    }

    // 1. Dengarkan perubahan tabel lokal Drift untuk auto-push ke cloud
    final localSub = _db.tableUpdates().listen((updates) {
      if (epoch != _sessionEpoch || _currentUid != uid || _isApplyingRemote) {
        return;
      }
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
      final snapSub = root.collection(t.name).snapshots().listen((snap) {
        if (epoch != _sessionEpoch || _currentUid != uid) return;
        for (final change in snap.docChanges) {
          // Abaikan perubahan lokal yang belum selesai ditulis ke server
          if (change.doc.metadata.hasPendingWrites) continue;
          if (change.type != DocumentChangeType.removed) {
            final data = change.doc.data();
            if (data != null) {
              unawaited(_enqueueRemoteSnapshotApply(epoch, uid, () async {
                try {
                  await t.applyRemote(data);
                } catch (e) {
                  debugPrint('[AutoSync] Error applying remote change for ${t.name}: $e');
                }
              }));
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
      if (epoch != _sessionEpoch || _currentUid != uid) return;
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
      if (epoch != _sessionEpoch || _currentUid != uid) return;
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
      if (epoch != _sessionEpoch || _currentUid != uid) return;
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
      if (epoch != _sessionEpoch || _currentUid != uid) return;
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        debugPrint('[AutoSync] Network reconnected! Triggering instant auto-sync...');
        unawaited(triggerTwoWaySync());
      }
    });
    _subscriptions.add(connSub);

    if (epoch != _sessionEpoch || _currentUid != uid) {
      _clearSessionResources();
      return;
    }

    // 5. Jalankan sinkronisasi awal dua arah (pull remote + push local)
    unawaited(triggerTwoWaySync());
  }

  /// Menghentikan seluruh listener saat user logout atau pergantian akun.
  void stopSync() {
    _sessionEpoch++;
    _activeSyncSeq++;
    _isSyncing = false;
    _twoWayInFlight = null;
    _twoWayUid = null;
    _lastPushedAt = DateTime.fromMillisecondsSinceEpoch(0);
    _clearSessionResources();
    _currentUid = null;
    debugPrint('[AutoSync] Stopped sync session');
  }

  /// Menjadwalkan push data lokal ke cloud dengan jeda debounce (1.5 detik).
  void schedulePush() {
    final uid = _currentUid;
    final epoch = _sessionEpoch;
    if (uid == null) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      _pushLocalOnly(uid, epoch);
    });
  }

  /// Melakukan sinkronisasi dua arah penuh (Pull Remote lalu Push Local).
  /// Menggabungkan panggilan bersamaan untuk UID aktif agar tidak terjadi sync ganda.
  Future<void> triggerTwoWaySync() async {
    final uid = _currentUid ?? _ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    if (Firebase.apps.isEmpty) return;

    final inFlight = _twoWayInFlight;
    if (inFlight != null && _twoWayUid == uid) {
      return inFlight;
    }
    if (_isSyncing) return;

    _currentUid ??= uid;
    final epoch = _sessionEpoch;
    _twoWayUid = uid;
    late final Future<void> run;
    run = _runTwoWaySync(uid, epoch).whenComplete(() {
      if (identical(_twoWayInFlight, run)) {
        _twoWayInFlight = null;
        _twoWayUid = null;
      }
    });
    _twoWayInFlight = run;
    return run;
  }

  Future<void> _runTwoWaySync(String uid, int epoch) async {
    final runSeq = ++_syncRunSeq;
    _activeSyncSeq = runSeq;
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
      if (epoch != _sessionEpoch) return;

      try {
        await _ref.read(budgetRuleProvider.notifier).restoreFromCloud(uid);
      } catch (e) {
        debugPrint('[AutoSync] Warning restoring budgetConfig: $e');
      }
      if (epoch != _sessionEpoch) return;

      try {
        await _ref.read(appPrefsProvider.notifier).restoreFromCloud(uid);
      } catch (e) {
        debugPrint('[AutoSync] Warning restoring preferences: $e');
      }
      if (epoch != _sessionEpoch) return;

      for (final t in _db.syncTables) {
        if (epoch != _sessionEpoch) return;
        try {
          final col = root.collection(t.name);
          final QuerySnapshot<Map<String, dynamic>> snap = isIncrementalPull
              ? await col
                  .where('updatedAt', isGreaterThan: candidateSinceMs)
                  .get()
                  .timeout(_timeout)
              : await col.get().timeout(_timeout);
          if (epoch != _sessionEpoch) return;
          final remoteMap = <String, int>{};
          await _runRemoteWrite(() async {
            for (final doc in snap.docs) {
              if (epoch != _sessionEpoch) return;
              final data = doc.data();
              final updatedMs = (data['updatedAt'] as num?)?.toInt() ?? 0;
              remoteMap[doc.id] = updatedMs;
              pulledUpdatedAtMs.add(updatedMs);
              await t.applyRemote(data);
            }
          });
          remoteUpdatedMaps[t.name] = remoteMap;
        } catch (e) {
          allPullSucceeded = false;
          debugPrint('[AutoSync] Warning pulling table ${t.name}: $e');
        }
      }

      if (epoch != _sessionEpoch) return;

      if (allPullSucceeded) {
        final nextCursor = computeNextPullCursorMs(
          previousCursorMs: prevCursorMs,
          pulledUpdatedAtMs: pulledUpdatedAtMs,
          syncStartedMs: syncStartedMs,
        );
        await prefs.setInt(pullCursorKey(uid), nextCursor);
      }
      if (epoch != _sessionEpoch) return;

      // Langkah 2: PUSH (Unggah data lokal yang belum ada / lebih baru di cloud)
      try {
        await _ref.read(profileProvider.notifier).uploadToCloud(uid);
      } catch (e) {
        debugPrint('[AutoSync] Warning uploading profile: $e');
      }
      if (epoch != _sessionEpoch) return;

      try {
        await _ref.read(budgetRuleProvider.notifier).uploadToCloud(uid);
      } catch (e) {
        debugPrint('[AutoSync] Warning uploading budgetConfig: $e');
      }
      if (epoch != _sessionEpoch) return;

      try {
        await _ref.read(appPrefsProvider.notifier).uploadToCloud(uid);
      } catch (e) {
        debugPrint('[AutoSync] Warning uploading preferences: $e');
      }
      if (epoch != _sessionEpoch) return;

      final localPushSince = isIncrementalPull
          ? _lastPushedAt.subtract(const Duration(seconds: 5))
          : DateTime.fromMillisecondsSinceEpoch(0);

      for (final t in _db.syncTables) {
        if (epoch != _sessionEpoch) return;
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
              if (epoch != _sessionEpoch) return;
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

      if (epoch != _sessionEpoch) return;

      // Periksa transaksi berulang yang jatuh tempo
      await RecurringService.checkAndGenerateDue(_db);

      if (epoch != _sessionEpoch) return;

      final now = DateTime.now();
      _lastPushedAt = now;
      await CloudBackupService.saveLastBackup(uid, now);
      if (epoch == _sessionEpoch) {
        _ref.read(syncStateProvider.notifier).update(SyncState(
              status: SyncStatus.synced,
              lastSynced: now,
            ));
      }
    } catch (e) {
      debugPrint('[AutoSync] Sync error: $e');
      if (epoch == _sessionEpoch) {
        _ref.read(syncStateProvider.notifier).update(
              _ref.read(syncStateProvider).copyWith(
                    status: SyncStatus.error,
                    errorMessage: e.toString(),
                  ),
            );
      }
    } finally {
      if (_activeSyncSeq == runSeq) {
        _isSyncing = false;
      }
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

    final runSeq = ++_syncRunSeq;
    _activeSyncSeq = runSeq;
    _isSyncing = true;
    final epoch = _sessionEpoch;
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
        if (epoch != _sessionEpoch) return totalUploaded;
        final col = root.collection(t.name);
        final rows = await t.changed(DateTime.fromMillisecondsSinceEpoch(0));
        if (rows.isNotEmpty) {
          for (var i = 0; i < rows.length; i += 400) {
            if (epoch != _sessionEpoch) return totalUploaded;
            final batch = FirebaseFirestore.instance.batch();
            for (final r in rows.skip(i).take(400)) {
              batch.set(col.doc(r['id'] as String), r);
            }
            await batch.commit().timeout(_timeout);
          }
          totalUploaded += rows.length;
        }
      }

      if (epoch != _sessionEpoch) return totalUploaded;
      await RecurringService.checkAndGenerateDue(_db);
      if (epoch != _sessionEpoch) return totalUploaded;

      final now = DateTime.now();
      _lastPushedAt = now;
      await CloudBackupService.saveLastBackup(uid, now);
      if (epoch == _sessionEpoch) {
        _ref.read(syncStateProvider.notifier).update(SyncState(
              status: SyncStatus.synced,
              lastSynced: now,
            ));
      }
      return totalUploaded;
    } catch (e) {
      debugPrint('[AutoSync] Error during pushAllLocalToCloud: $e');
      if (epoch == _sessionEpoch) {
        _ref.read(syncStateProvider.notifier).update(
              _ref.read(syncStateProvider).copyWith(
                    status: SyncStatus.error,
                    errorMessage: e.toString(),
                  ),
            );
      }
      rethrow;
    } finally {
      if (_activeSyncSeq == runSeq) {
        _isSyncing = false;
      }
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

    final runSeq = ++_syncRunSeq;
    _activeSyncSeq = runSeq;
    _isSyncing = true;
    final epoch = _sessionEpoch;
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
        if (epoch != _sessionEpoch) return totalRestored;
        final snap = await root.collection(t.name).get().timeout(_timeout);
        await _runRemoteWrite(() async {
          for (final doc in snap.docs) {
            if (epoch != _sessionEpoch) return;
            final data = doc.data();
            pulledUpdatedAtMs.add((data['updatedAt'] as num?)?.toInt() ?? 0);
            final applied = await t.applyRemote(data);
            if (applied) totalRestored++;
          }
        });
      }

      if (epoch != _sessionEpoch) return totalRestored;

      await prefs.setInt(
        pullCursorKey(uid),
        computeNextPullCursorMs(
          previousCursorMs: 0,
          pulledUpdatedAtMs: pulledUpdatedAtMs,
          syncStartedMs: syncStartedMs,
        ),
      );

      await RecurringService.checkAndGenerateDue(_db);
      if (epoch != _sessionEpoch) return totalRestored;

      final now = DateTime.now();
      await CloudBackupService.saveLastBackup(uid, now);
      if (epoch == _sessionEpoch) {
        _ref.read(syncStateProvider.notifier).update(SyncState(
              status: SyncStatus.synced,
              lastSynced: now,
            ));
      }
      return totalRestored;
    } catch (e) {
      debugPrint('[AutoSync] Error during pullAllRemoteToLocal: $e');
      if (epoch == _sessionEpoch) {
        _ref.read(syncStateProvider.notifier).update(
              _ref.read(syncStateProvider).copyWith(
                    status: SyncStatus.error,
                    errorMessage: e.toString(),
                  ),
            );
      }
      rethrow;
    } finally {
      if (_activeSyncSeq == runSeq) {
        _isSyncing = false;
      }
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

  Future<void> _pushLocalOnly(String uid, int epoch) async {
    if (epoch != _sessionEpoch ||
        _currentUid != uid ||
        _isSyncing ||
        _isApplyingRemote ||
        Firebase.apps.isEmpty) {
      return;
    }
    try {
      final root = FirebaseFirestore.instance.collection('users').doc(uid);
      // Query hanya data lokal yang diperbarui sejak push terakhir (beri buffer 5 detik untuk clock skew)
      final since = _lastPushedAt.subtract(const Duration(seconds: 5));
      var hasChanges = false;

      for (final t in _db.syncTables) {
        if (epoch != _sessionEpoch || _currentUid != uid) return;
        final rows = await t.changed(since);
        if (rows.isNotEmpty) {
          hasChanges = true;
          final col = root.collection(t.name);
          for (var i = 0; i < rows.length; i += 400) {
            if (epoch != _sessionEpoch || _currentUid != uid) return;
            final batch = FirebaseFirestore.instance.batch();
            for (final r in rows.skip(i).take(400)) {
              batch.set(col.doc(r['id'] as String), r);
            }
            await batch.commit().timeout(_timeout);
          }
        }
      }

      if (epoch != _sessionEpoch || _currentUid != uid) return;

      final now = DateTime.now();
      _lastPushedAt = now;
      if (hasChanges) {
        await CloudBackupService.saveLastBackup(uid, now);
        if (epoch == _sessionEpoch) {
          _ref.read(syncStateProvider.notifier).update(SyncState(
                status: SyncStatus.synced,
                lastSynced: now,
              ));
        }
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
