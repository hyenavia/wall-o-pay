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
/// Disimpan di perangkat (offline-first) dan otomatis tersinkronkan dengan akun di Cloud Firestore
/// sehingga pengguna tidak perlu mengatur ulang PIN di perangkat baru.
class Lock {
  Lock._();
  static final instance = Lock._();

  final state = ValueNotifier<AppLockState>(const AppLockState());
  SharedPreferences? _p;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    _emit();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        syncWithCloud(user.uid);
      }
      FirebaseAuth.instance.authStateChanges().listen((u) {
        if (u != null) {
          syncWithCloud(u.uid);
        }
      });
    } catch (e) {
      debugPrint('Firebase not available for lock sync: $e');
    }
  }

  void _emit() {
    final p = _p;
    if (p == null) return;
    state.value = AppLockState(
      enabled: p.getString('lock.hash') != null,
      delayMin: p.getInt('lock.delay') ?? 1,
    );
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
    await _p!.setString('lock.salt', salt);
    await _p!.setString('lock.hash', hash);
    await _p!.setInt('lock.updatedAt', now);
    _emit();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await _doc(uid)?.set({
          'hash': hash,
          'salt': salt,
          'delay': _p!.getInt('lock.delay') ?? 1,
          'updatedAt': now,
        });
      }
    } catch (e) {
      debugPrint('Failed to sync PIN to cloud: $e');
    }
  }

  /// Verifikasi PIN yang diketik.
  bool verify(String pin) {
    final salt = _p?.getString('lock.salt');
    final h = _p?.getString('lock.hash');
    return salt != null && h != null && _hash(pin, salt) == h;
  }

  /// Nonaktifkan penguncian PIN.
  Future<void> disable() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final k in const ['lock.salt', 'lock.hash']) {
      await _p?.remove(k);
    }
    await _p?.setInt('lock.updatedAt', now);
    _emit();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await _doc(uid)?.set({
          'hash': null,
          'salt': null,
          'delay': _p!.getInt('lock.delay') ?? 1,
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
    await _p?.setInt('lock.delay', minutes);
    await _p?.setInt('lock.updatedAt', now);
    _emit();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await _doc(uid)?.set({
          'hash': _p?.getString('lock.hash'),
          'salt': _p?.getString('lock.salt'),
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
        final localHash = _p?.getString('lock.hash');
        final localSalt = _p?.getString('lock.salt');
        if (localHash != null && localSalt != null) {
          final now = _p?.getInt('lock.updatedAt') ??
              DateTime.now().millisecondsSinceEpoch;
          await doc.set({
            'hash': localHash,
            'salt': localSalt,
            'delay': _p?.getInt('lock.delay') ?? 1,
            'updatedAt': now,
          });
        }
        return;
      }

      final remoteAt = (data['updatedAt'] as num?)?.toInt() ?? 0;
      final localAt = _p?.getInt('lock.updatedAt') ?? 0;

      if (remoteAt >= localAt) {
        final remoteHash = data['hash'] as String?;
        final remoteSalt = data['salt'] as String?;
        final remoteDelay = (data['delay'] as num?)?.toInt() ?? 1;

        if (remoteHash != null && remoteSalt != null) {
          await _p?.setString('lock.hash', remoteHash);
          await _p?.setString('lock.salt', remoteSalt);
          await _p?.setInt('lock.delay', remoteDelay);
        } else {
          await _p?.remove('lock.hash');
          await _p?.remove('lock.salt');
          await _p?.setInt('lock.delay', remoteDelay);
        }
        await _p?.setInt('lock.updatedAt', remoteAt);
        _emit();
      } else {
        final localHash = _p?.getString('lock.hash');
        final localSalt = _p?.getString('lock.salt');
        await doc.set({
          'hash': localHash,
          'salt': localSalt,
          'delay': _p?.getInt('lock.delay') ?? 1,
          'updatedAt': localAt,
        });
      }
    } catch (e) {
      debugPrint('PIN sync error: $e');
    }
  }

  /// Bersihkan data PIN lokal saat keluar akun.
  Future<void> clearLocal() async {
    for (final k in const [
      'lock.salt',
      'lock.hash',
      'lock.delay',
      'lock.updatedAt'
    ]) {
      await _p?.remove(k);
    }
    _emit();
  }
}

