import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockState {
  const AppLockState({this.enabled = false, this.delayMin = 1});

  final bool enabled;
  final int delayMin; // auto-lock timeout in minutes (0 = immediately / 3s grace)
}

/// Kunci aplikasi dengan PIN 6 digit.
/// Disimpan di perangkat per-akun (offline-first) dan otomatis tersinkronkan dengan akun di Cloud Firestore
/// sehingga pengguna tidak perlu mengatur ulang PIN di perangkat baru, dan saat ganti akun tidak saling tertimpa.
class Lock {
  Lock._();
  static final instance = Lock._();

  final state = ValueNotifier<AppLockState>(const AppLockState());
  final isLocked = ValueNotifier<bool>(false);
  SharedPreferences? _p;
  String? _activeUid;

  String get _currentUid {
    if (_activeUid != null) return _activeUid!;
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    } catch (_) {
      return 'guest';
    }
  }

  String _k(String key, [String? uid]) {
    final u = uid ?? _currentUid;
    return 'lock.$key.$u';
  }

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    try {
      _activeUid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      _activeUid = null;
    }
    _migrateLegacyIfNeeded(_activeUid);
    _emit();
    try {
      if (_activeUid != null) {
        syncWithCloud(_activeUid!);
      }
      FirebaseAuth.instance.authStateChanges().listen((u) {
        loadForUser(u?.uid);
      });
    } catch (e) {
      debugPrint('Firebase not available for lock sync: $e');
    }
  }

  Future<void> loadForUser(String? uid) async {
    _activeUid = uid;
    _migrateLegacyIfNeeded(uid);
    _emit();
    if (uid != null) {
      await syncWithCloud(uid);
    }
  }

  void _migrateLegacyIfNeeded(String? uid) {
    final p = _p;
    if (p == null || uid == null) return;
    final scopedHash = p.getString(_k('hash', uid));
    final legacyHash = p.getString('lock.hash');
    if (scopedHash == null && legacyHash != null) {
      p.setString(_k('hash', uid), legacyHash);
      final legacySalt = p.getString('lock.salt');
      if (legacySalt != null) p.setString(_k('salt', uid), legacySalt);
      final legacyDelay = p.getInt('lock.delay');
      if (legacyDelay != null) p.setInt(_k('delay', uid), legacyDelay);
      final legacyAt = p.getInt('lock.updatedAt');
      if (legacyAt != null) p.setInt(_k('updatedAt', uid), legacyAt);
      p.remove('lock.hash');
      p.remove('lock.salt');
      p.remove('lock.delay');
      p.remove('lock.updatedAt');
    }
  }

  void _emit() {
    final p = _p;
    if (p == null) return;
    final enabled = p.getString(_k('hash')) != null;
    state.value = AppLockState(
      enabled: enabled,
      delayMin: p.getInt(_k('delay')) ?? 1,
    );
    if (!enabled) {
      isLocked.value = false;
    }
  }

  String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  DocumentReference<Map<String, dynamic>>? _doc(String uid) {
    try {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('meta')
          .doc('security');
    } catch (_) {
      return null;
    }
  }

  /// Atur PIN baru (6 digit).
  Future<void> setPin(String pin) async {
    final salt = base64Url.encode(
      List<int>.generate(16, (_) => Random.secure().nextInt(256)),
    );
    final hash = _hash(pin, salt);
    final now = DateTime.now().millisecondsSinceEpoch;
    final uid = _currentUid;
    await _p!.setString(_k('salt', uid), salt);
    await _p!.setString(_k('hash', uid), hash);
    await _p!.setInt(_k('updatedAt', uid), now);
    _emit();

    try {
      final userUid = FirebaseAuth.instance.currentUser?.uid;
      if (userUid != null) {
        await _doc(userUid)?.set({
          'hash': hash,
          'salt': salt,
          'delay': _p!.getInt(_k('delay', userUid)) ?? 1,
          'updatedAt': now,
        });
      }
    } catch (e) {
      debugPrint('Failed to sync PIN to cloud: $e');
    }
  }

  /// Verifikasi PIN yang diketik.
  bool verify(String pin) {
    final salt = _p?.getString(_k('salt'));
    final h = _p?.getString(_k('hash'));
    return salt != null && h != null && _hash(pin, salt) == h;
  }

  /// Nonaktifkan penguncian PIN.
  Future<void> disable() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final uid = _currentUid;
    await _p?.remove(_k('salt', uid));
    await _p?.remove(_k('hash', uid));
    await _p?.setInt(_k('updatedAt', uid), now);
    _emit();

    try {
      final userUid = FirebaseAuth.instance.currentUser?.uid;
      if (userUid != null) {
        await _doc(userUid)?.set({
          'hash': null,
          'salt': null,
          'delay': _p!.getInt(_k('delay', userUid)) ?? 1,
          'updatedAt': now,
        });
      }
    } catch (e) {
      debugPrint('Failed to sync PIN disable to cloud: $e');
    }
  }

  /// Ubah jeda waktu penguncian otomatis (menit).
  Future<void> setDelay(int minutes) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final uid = _currentUid;
    await _p?.setInt(_k('delay', uid), minutes);
    await _p?.setInt(_k('updatedAt', uid), now);
    _emit();

    try {
      final userUid = FirebaseAuth.instance.currentUser?.uid;
      if (userUid != null) {
        await _doc(userUid)?.set({
          'hash': _p?.getString(_k('hash', userUid)),
          'salt': _p?.getString(_k('salt', userUid)),
          'delay': minutes,
          'updatedAt': now,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Failed to sync PIN delay to cloud: $e');
    }
  }

  /// Sinkronkan status PIN dengan Cloud Firestore (dipanggil saat login atau buka app).
  Future<void> syncWithCloud(String uid) async {
    try {
      final doc = _doc(uid);
      if (doc == null) return;

      final snap = await doc.get().timeout(const Duration(seconds: 15));
      final data = snap.data();
      if (data == null) {
        final localHash = _p?.getString(_k('hash', uid));
        final localSalt = _p?.getString(_k('salt', uid));
        if (localHash != null && localSalt != null) {
          final now = _p?.getInt(_k('updatedAt', uid)) ??
              DateTime.now().millisecondsSinceEpoch;
          await doc.set({
            'hash': localHash,
            'salt': localSalt,
            'delay': _p?.getInt(_k('delay', uid)) ?? 1,
            'updatedAt': now,
          });
        }
        return;
      }

      final remoteAt = (data['updatedAt'] as num?)?.toInt() ?? 0;
      final localAt = _p?.getInt(_k('updatedAt', uid)) ?? 0;

      if (remoteAt >= localAt) {
        final remoteHash = data['hash'] as String?;
        final remoteSalt = data['salt'] as String?;
        final remoteDelay = (data['delay'] as num?)?.toInt() ?? 1;

        if (remoteHash != null && remoteSalt != null) {
          await _p?.setString(_k('hash', uid), remoteHash);
          await _p?.setString(_k('salt', uid), remoteSalt);
          await _p?.setInt(_k('delay', uid), remoteDelay);
        } else {
          await _p?.remove(_k('hash', uid));
          await _p?.remove(_k('salt', uid));
          await _p?.setInt(_k('delay', uid), remoteDelay);
        }
        await _p?.setInt(_k('updatedAt', uid), remoteAt);
        if (_activeUid == uid) {
          _emit();
        }
      } else {
        final localHash = _p?.getString(_k('hash', uid));
        final localSalt = _p?.getString(_k('salt', uid));
        await doc.set({
          'hash': localHash,
          'salt': localSalt,
          'delay': _p?.getInt(_k('delay', uid)) ?? 1,
          'updatedAt': localAt,
        });
      }
    } catch (e) {
      debugPrint('PIN sync error: $e');
    }
  }

  /// Bersihkan data PIN lokal pengguna tertentu saat wipe data.
  Future<void> clearLocal([String? uid]) async {
    final targetUid = uid ?? _currentUid;
    await _p?.remove(_k('salt', targetUid));
    await _p?.remove(_k('hash', targetUid));
    await _p?.remove(_k('delay', targetUid));
    await _p?.remove(_k('updatedAt', targetUid));
    if (_activeUid == targetUid) {
      _emit();
    }
  }
}
