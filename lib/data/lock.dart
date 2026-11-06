/// Layanan keamanan kunci aplikasi menggunakan PIN 6 digit (SHA-256 + salt acak),
/// autentikasi biometrik perangkat (Fingerprint / Face Unlock), jeda kunci otomatis (auto-lock timeout),
/// sinkronisasi PIN antar perangkat, dan Privacy Shield (`FLAG_SECURE`).
library;

import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model state untuk status penguncian PIN aplikasi, biometrik, jeda waktu kunci otomatis, dan perisai privasi layar.
class AppLockState {
  const AppLockState({
    this.enabled = false,
    this.delayMin = 1,
    this.privacyShield = false,
    this.biometricEnabled = false,
    this.biometricAvailable = false,
    this.biometricTypes = const [],
  });

  final bool enabled;
  final int delayMin; // auto-lock timeout in minutes (0 = immediately / 3s grace)
  final bool privacyShield; // true = FLAG_SECURE active (hide app switcher preview)
  final bool biometricEnabled; // true = biometric unlock active alongside PIN
  final bool biometricAvailable; // true = device has enrolled biometrics
  final List<BiometricType> biometricTypes;

  bool get hasFace => biometricTypes.contains(BiometricType.face);
  bool get hasFingerprint => biometricTypes.contains(BiometricType.fingerprint);
  bool get isFaceOnly => hasFace && !hasFingerprint;
  bool get isFingerprintOnly => hasFingerprint && !hasFace;
}

/// Kunci aplikasi dengan PIN 6 digit dan biometrik (Fingerprint / Face Unlock).
/// PIN disimpan di perangkat per-akun (offline-first) dan otomatis tersinkronkan dengan akun di Cloud Firestore
/// sehingga pengguna tidak perlu mengatur ulang PIN di perangkat baru, dan saat ganti akun tidak saling tertimpa.
/// Status aktif biometrik disimpan secara lokal per perangkat & per akun.
class Lock {
  Lock._();
  static final instance = Lock._();

  final state = ValueNotifier<AppLockState>(const AppLockState());
  final isLocked = ValueNotifier<bool>(false);
  final _localAuth = LocalAuthentication();
  final _secureStorage = const FlutterSecureStorage();
  final Map<String, String> _secretCache = {};
  static const _channel = MethodChannel('com.example.wall_o_pay/notifications');
  SharedPreferences? _p;
  String? _activeUid;
  bool _biometricAvailable = false;
  List<BiometricType> _biometricTypes = const [];
  bool _isAuthenticatingBiometric = false;
  DateTime? _lastBiometricAuthEndedAt;

  /// Menandakan apakah dialog biometrik sistem sedang aktif (atau baru saja ditutup)
  /// agar transisi lifecycle pause/resume dari dialog OS tidak memicu penguncian ulang.
  bool get isAuthenticatingBiometric {
    if (_isAuthenticatingBiometric) return true;
    final ended = _lastBiometricAuthEndedAt;
    if (ended != null &&
        DateTime.now().difference(ended) < const Duration(milliseconds: 1200)) {
      return true;
    }
    return false;
  }

  /// Atur perlindungan layar (FLAG_SECURE) ke native Android.
  static Future<void> setSecureScreen(bool enabled) async {
    try {
      await _channel.invokeMethod('setSecureScreen', {'secure': enabled});
    } catch (e) {
      debugPrint('Failed to set secure screen: $e');
    }
  }

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

  String? _getSecret(String key) => _secretCache[key] ?? _p?.getString(key);

  Future<void> _writeSecret(String key, String value) async {
    _secretCache[key] = value;
    if (!kIsWeb) {
      try {
        await _secureStorage.write(key: key, value: value);
        await _p?.remove(key);
        return;
      } catch (_) {
        // Fallback ke SharedPreferences pada lingkungan unit test tanpa plugin native
      }
    }
    await _p?.setString(key, value);
  }

  Future<void> _deleteSecret(String key) async {
    _secretCache.remove(key);
    await _p?.remove(key);
    if (!kIsWeb) {
      try {
        await _secureStorage.delete(key: key);
      } catch (_) {}
    }
  }

  Future<void> _loadSecretsForUid(String? uid) async {
    final targetUid = uid ?? 'guest';
    for (final field in const ['hash', 'salt']) {
      final key = _k(field, targetUid);
      String? val;
      var secureOk = false;
      if (!kIsWeb) {
        try {
          val = await _secureStorage.read(key: key);
          secureOk = true;
        } catch (_) {}
      }
      final legacyVal = _p?.getString(key);
      if (val != null) {
        _secretCache[key] = val;
        if (legacyVal != null) {
          await _p?.remove(key);
        }
      } else if (legacyVal != null) {
        _secretCache[key] = legacyVal;
        if (secureOk) {
          try {
            await _secureStorage.write(key: key, value: legacyVal);
            await _p?.remove(key);
          } catch (_) {}
        }
      } else {
        _secretCache.remove(key);
      }
    }
  }

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    try {
      _activeUid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      _activeUid = null;
    }
    _migrateLegacyIfNeeded(_activeUid);
    await _loadSecretsForUid(_activeUid);
    await refreshBiometricSupport();
    final shield = _p?.getBool('security.privacy_shield') ?? false;
    if (shield) {
      await setSecureScreen(true);
    }
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

  /// Periksa ketersediaan dan jenis sensor biometrik yang terdaftar di perangkat.
  Future<void> refreshBiometricSupport() async {
    if (kIsWeb) {
      _biometricAvailable = false;
      _biometricTypes = const [];
      _emit();
      return;
    }
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (canCheck && isSupported) {
        final enrolled = await _localAuth.getAvailableBiometrics();
        _biometricTypes = enrolled;
        _biometricAvailable = enrolled.isNotEmpty;
      } else {
        _biometricTypes = const [];
        _biometricAvailable = false;
      }
    } catch (e) {
      debugPrint('Failed to check biometric support: $e');
      _biometricTypes = const [];
      _biometricAvailable = false;
    }
    _emit();
  }

  /// Waktu berakhirnya penalti lockout akibat salah mengetik PIN berulang kali (disimpan persisten).
  DateTime? get lockoutUntil {
    final ms = _p?.getInt(_k('lockoutUntil'));
    if (ms == null) return null;
    final until = DateTime.fromMillisecondsSinceEpoch(ms);
    if (DateTime.now().isBefore(until)) return until;
    return null;
  }

  /// Apakah saat ini sedang dalam masa penalti lockout brute-force PIN.
  bool get isLockedOut => lockoutUntil != null;

  /// Sisa detik penalti lockout saat ini (0 jika tidak terkunci).
  int get remainingLockoutSeconds {
    final until = lockoutUntil;
    if (until == null) return 0;
    return (until.difference(DateTime.now()).inMilliseconds / 1000)
        .ceil()
        .clamp(1, 86400);
  }

  Future<void> _clearLockoutState([String? uid]) async {
    final targetUid = uid ?? _currentUid;
    await _p?.remove(_k('fails', targetUid));
    await _p?.remove(_k('lockoutUntil', targetUid));
    await _p?.remove(_k('lockoutTier', targetUid));
  }

  /// Jalankan autentikasi biometrik bawaan sistem (Fingerprint / Face Unlock).
  Future<bool> authenticateBiometric({required String localizedReason}) async {
    if (kIsWeb || _isAuthenticatingBiometric || isLockedOut) return false;
    _isAuthenticatingBiometric = true;
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (ok) {
        await _clearLockoutState();
      }
      return ok;
    } on LocalAuthException catch (e) {
      debugPrint('Biometric auth exception (${e.code.name}): ${e.description}');
      return false;
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    } finally {
      _isAuthenticatingBiometric = false;
      _lastBiometricAuthEndedAt = DateTime.now();
    }
  }

  /// Aktifkan atau nonaktifkan pembuka kunci biometrik untuk pengguna saat ini.
  /// Saat diaktifkan, pengguna wajib memverifikasi biometrik terlebih dahulu.
  Future<bool> setBiometric(
    bool enabled, {
    required String localizedReason,
  }) async {
    final p = _p;
    if (p == null) return false;
    if (enabled) {
      await refreshBiometricSupport();
      if (!_biometricAvailable) return false;
      final ok = await authenticateBiometric(localizedReason: localizedReason);
      if (!ok) return false;
    }
    await p.setBool(_k('biometric', _currentUid), enabled);
    _emit();
    return true;
  }

  Future<void> loadForUser(String? uid) async {
    _activeUid = uid;
    _migrateLegacyIfNeeded(uid);
    await _loadSecretsForUid(uid);
    _emit();
    if (uid != null) {
      await syncWithCloud(uid);
    }
  }

  void _migrateLegacyIfNeeded(String? uid) {
    final p = _p;
    if (p == null || uid == null) return;
    final scopedHash = _getSecret(_k('hash', uid));
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
    final enabled = _getSecret(_k('hash')) != null;
    final biometricPref = p.getBool(_k('biometric')) ?? false;
    final privacyShield = p.getBool('security.privacy_shield') ?? false;
    state.value = AppLockState(
      enabled: enabled,
      delayMin: p.getInt(_k('delay')) ?? 1,
      privacyShield: privacyShield,
      biometricEnabled: enabled && _biometricAvailable && biometricPref,
      biometricAvailable: _biometricAvailable,
      biometricTypes: _biometricTypes,
    );
    if (!enabled) {
      isLocked.value = false;
    }
  }

  /// Atur status perisai privasi (FLAG_SECURE) untuk menyembunyikan pratinjau di Recent Apps.
  Future<void> setPrivacyShield(bool enabled) async {
    final p = _p;
    if (p == null) return;
    await p.setBool('security.privacy_shield', enabled);
    await setSecureScreen(enabled);
    _emit();
  }

  String _hashLegacy(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  /// Key-stretching PIN menggunakan 2.048 iterasi HMAC-SHA256 (`v2:<hex>`).
  /// Memperlambat serangan brute-force offline secara signifikan namun tetap < 1ms di UI thread.
  String _hash(String pin, String salt) {
    final hmac = Hmac(sha256, utf8.encode('wop_v2:$salt'));
    List<int> digest = hmac.convert(utf8.encode(pin)).bytes;
    for (var i = 1; i < 2048; i++) {
      digest = hmac.convert(digest).bytes;
    }
    final hex = Digest(digest).toString();
    return 'v2:$hex';
  }

  bool _verifyHash(String pin, String salt, String storedHash) {
    if (storedHash.startsWith('v2:')) {
      return _hash(pin, salt) == storedHash;
    }
    return _hashLegacy(pin, salt) == storedHash;
  }

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
    await _writeSecret(_k('salt', uid), salt);
    await _writeSecret(_k('hash', uid), hash);
    await _p!.setInt(_k('updatedAt', uid), now);
    await _clearLockoutState(uid);
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

  /// Verifikasi PIN yang diketik dengan perlindungan brute-force persisten (exponential backoff).
  bool verify(String pin) {
    if (isLockedOut) return false;
    final salt = _getSecret(_k('salt'));
    final h = _getSecret(_k('hash'));
    final ok = salt != null && h != null && _verifyHash(pin, salt, h);
    if (ok) {
      _clearLockoutState();
      // Upgrade transparan jika PIN masih menggunakan format hash v1 lama
      if (!h.startsWith('v2:')) {
        final upgraded = _hash(pin, salt);
        _writeSecret(_k('hash'), upgraded);
      }
      return true;
    }
    final fails = (_p?.getInt(_k('fails')) ?? 0) + 1;
    if (fails >= 5) {
      final tier = (_p?.getInt(_k('lockoutTier')) ?? 0) + 1;
      final penaltySec = switch (tier) {
        1 => 30,
        2 => 120,
        _ => 300,
      };
      _p?.setInt(_k('fails'), 0);
      _p?.setInt(_k('lockoutTier'), tier);
      _p?.setInt(
        _k('lockoutUntil'),
        DateTime.now().add(Duration(seconds: penaltySec)).millisecondsSinceEpoch,
      );
    } else {
      _p?.setInt(_k('fails'), fails);
    }
    return false;
  }

  /// Nonaktifkan penguncian PIN.
  Future<void> disable() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final uid = _currentUid;
    await _deleteSecret(_k('salt', uid));
    await _deleteSecret(_k('hash', uid));
    await _p?.remove(_k('biometric', uid));
    await _clearLockoutState(uid);
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
          'hash': _getSecret(_k('hash', userUid)),
          'salt': _getSecret(_k('salt', userUid)),
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
        final localHash = _getSecret(_k('hash', uid));
        final localSalt = _getSecret(_k('salt', uid));
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
          await _writeSecret(_k('hash', uid), remoteHash);
          await _writeSecret(_k('salt', uid), remoteSalt);
          await _p?.setInt(_k('delay', uid), remoteDelay);
        } else {
          await _deleteSecret(_k('hash', uid));
          await _deleteSecret(_k('salt', uid));
          await _p?.setInt(_k('delay', uid), remoteDelay);
        }
        await _p?.setInt(_k('updatedAt', uid), remoteAt);
        if (_activeUid == uid) {
          _emit();
        }
      } else {
        final localHash = _getSecret(_k('hash', uid));
        final localSalt = _getSecret(_k('salt', uid));
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

  /// Migrasikan PIN lokal mode tamu ke akun pengguna saat menautkan akun.
  Future<void> migrateGuestToUser(String uid) async {
    final p = _p;
    if (p == null) return;
    await _loadSecretsForUid('guest');
    await _loadSecretsForUid(uid);
    final guestHash = _getSecret(_k('hash', 'guest'));
    final guestSalt = _getSecret(_k('salt', 'guest'));
    if (guestHash != null &&
        guestSalt != null &&
        _getSecret(_k('hash', uid)) == null) {
      await _writeSecret(_k('hash', uid), guestHash);
      await _writeSecret(_k('salt', uid), guestSalt);
      final guestDelay = p.getInt(_k('delay', 'guest'));
      if (guestDelay != null) await p.setInt(_k('delay', uid), guestDelay);
      final guestBio = p.getBool(_k('biometric', 'guest'));
      if (guestBio != null) await p.setBool(_k('biometric', uid), guestBio);
      final guestAt = p.getInt(_k('updatedAt', 'guest'));
      if (guestAt != null) await p.setInt(_k('updatedAt', uid), guestAt);
    }
    await clearLocal('guest');
    _activeUid = uid;
    _emit();
  }

  /// Bersihkan data PIN lokal pengguna tertentu saat wipe data.
  Future<void> clearLocal([String? uid]) async {
    final targetUid = uid ?? _currentUid;
    await _deleteSecret(_k('salt', targetUid));
    await _deleteSecret(_k('hash', targetUid));
    await _p?.remove(_k('delay', targetUid));
    await _p?.remove(_k('biometric', targetUid));
    await _clearLockoutState(targetUid);
    await _p?.remove(_k('updatedAt', targetUid));
    if ((_activeUid ?? 'guest') == targetUid) {
      _emit();
    }
  }
}
