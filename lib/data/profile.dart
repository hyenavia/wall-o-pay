/// Pengelolaan profil pengguna (nickname dan foto profil Base64) yang disimpan per akun
/// di perangkat lokal dan disinkronkan ke Cloud Firestore.
library;

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show MemoryImage, Offset;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud.dart';
import 'cloud_sync.dart';
import 'prefs.dart';

/// Daftar ID bingkai profil yang tersedia di `assets/new_asset/borders/`.
const List<String> profileFrameIds = [
  'border_02',
  'border_03',
  'border_04',
  'border_05',
  'border_06',
  'border_07',
  'border_08',
  'border_09',
  'border_10',
  'border_11',
  'border_12',
  'border_13',
  'border_14',
];

/// Mengembalikan path aset bingkai profil yang valid, atau `null` jika tidak dikenal.
String? profileFrameAssetPath(String? frameId) {
  if (frameId == null || !profileFrameIds.contains(frameId)) return null;
  return 'assets/new_asset/borders/$frameId.png';
}

/// Mengembalikan faktor skala agar lubang tengah bingkai pas mengelilingi avatar.
double profileFrameScale(String? frameId) {
  return switch (frameId) {
    'border_02' => 1.26,
    'border_03' => 1.29,
    'border_04' => 1.28,
    'border_05' => 1.36,
    'border_06' => 1.33,
    'border_07' => 1.49,
    'border_08' => 1.32,
    'border_09' => 1.33,
    'border_10' => 1.50,
    'border_11' => 1.26,
    'border_12' => 1.33,
    'border_13' => 1.25,
    'border_14' => 1.29,
    _ => 1.26,
  };
}

/// Mengembalikan offset fraksional agar pusat lubang bingkai tepat di tengah avatar.
Offset profileFrameOffset(String? frameId) {
  return switch (frameId) {
    'border_02' => const Offset(0.032, -0.004),
    'border_03' => const Offset(0.067, -0.004),
    'border_04' => const Offset(-0.022, 0.009),
    'border_05' => const Offset(0.055, 0.015),
    'border_06' => const Offset(0.043, -0.005),
    'border_07' => const Offset(-0.019, 0.063),
    'border_08' => const Offset(0.042, 0.033),
    'border_09' => const Offset(-0.043, 0.032),
    'border_10' => const Offset(-0.007, 0.018),
    'border_11' => const Offset(0.017, 0.020),
    'border_12' => const Offset(-0.031, 0.0),
    'border_13' => const Offset(0.015, 0.003),
    'border_14' => const Offset(0.027, 0.003),
    _ => Offset.zero,
  };
}

class ProfileState {
  ProfileState({this.nickname, this.photo, this.frameId})
      : photoImage = photo == null ? null : MemoryImage(photo);

  final String? nickname;
  final Uint8List? photo;
  final MemoryImage? photoImage;
  final String? frameId;
}

/// Nickname dan foto profil, disimpan per akun di perangkat.
/// Ikut tercadangkan saat pengguna menekan tombol backup cloud.
class ProfileController extends Notifier<ProfileState> {
  static const guestId = 'guest';
  static const _timeout = Duration(seconds: 30);

  String _nickKey(String uid) => 'nickname_$uid';
  String _photoKey(String uid) => 'photo_$uid';
  String _frameKey(String uid) => 'profile_frame_$uid';
  String _updatedKey(String uid) => 'profile_updated_$uid';
  String _syncedKey(String uid) => 'profile_synced_at_$uid';

  /// Batas maksimum panjang string Base64 foto profil (~600 KB binary) agar aman bagi memori & batas dokumen Firestore 1 MiB.
  static const maxPhotoBase64Length = 800000;

  /// Mendekode Base64 foto secara aman tanpa membuang data tersimpan bila korup.
  static Uint8List? _safeDecodePhoto(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.length > maxPhotoBase64Length) return null;
    try {
      final bytes = base64Decode(trimmed);
      return bytes.isEmpty ? null : bytes;
    } catch (e) {
      debugPrint('[Profile] Invalid base64 photo ignored: $e');
      return null;
    }
  }

  @override
  ProfileState build() {
    final user = ref.watch(currentUserProvider);
    final uid = user?.uid ?? guestId;
    final p = ref.read(sharedPreferencesProvider);
    final b64 = p.getString(_photoKey(uid));
    final rawFrame = p.getString(_frameKey(uid));
    return ProfileState(
      nickname: p.getString(_nickKey(uid)),
      photo: _safeDecodePhoto(b64),
      frameId: profileFrameAssetPath(rawFrame) != null ? rawFrame : null,
    );
  }

  String? get _uid => ref.read(currentUserProvider)?.uid;
  String get _effectiveUid => _uid ?? guestId;

  Future<int> _touchUpdated(SharedPreferences p, String uid) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final prev = p.getInt(_updatedKey(uid)) ?? 0;
    final next = now > prev ? now : prev + 1;
    await p.setInt(_updatedKey(uid), next);
    return next;
  }

  /// Apakah profil akun [uid] memiliki perubahan lokal yang belum diunggah ke cloud.
  bool hasPendingUpload(String uid) {
    final p = ref.read(sharedPreferencesProvider);
    final localAt = p.getInt(_updatedKey(uid)) ?? 0;
    if (localAt <= 0) return false;
    final syncedAt = p.getInt(_syncedKey(uid)) ?? 0;
    return localAt > syncedAt;
  }

  Future<void> setNickname(String value) async {
    final uid = _effectiveUid;
    final p = ref.read(sharedPreferencesProvider);
    final nick = value.trim();
    if (nick.isEmpty) {
      await p.remove(_nickKey(uid));
    } else {
      await p.setString(_nickKey(uid), nick);
    }
    await _touchUpdated(p, uid);
    state = ProfileState(
      nickname: nick.isEmpty ? null : nick,
      photo: state.photo,
      frameId: state.frameId,
    );
    if (_uid != null) {
      ref.read(autoSyncServiceProvider).schedulePush();
    }
  }

  Future<void> setPhoto(Uint8List? bytes) async {
    final uid = _effectiveUid;
    final p = ref.read(sharedPreferencesProvider);
    if (bytes == null) {
      await p.remove(_photoKey(uid));
    } else {
      await p.setString(_photoKey(uid), base64Encode(bytes));
    }
    await _touchUpdated(p, uid);
    state = ProfileState(
      nickname: state.nickname,
      photo: bytes,
      frameId: state.frameId,
    );
    if (_uid != null) {
      ref.read(autoSyncServiceProvider).schedulePush();
    }
  }

  Future<void> setFrame(String? frameId) async {
    final normalized = profileFrameAssetPath(frameId) != null ? frameId : null;
    final uid = _effectiveUid;
    final p = ref.read(sharedPreferencesProvider);
    if (normalized == null) {
      await p.remove(_frameKey(uid));
    } else {
      await p.setString(_frameKey(uid), normalized);
    }
    await _touchUpdated(p, uid);
    state = ProfileState(
      nickname: state.nickname,
      photo: state.photo,
      frameId: normalized,
    );
    if (_uid != null) {
      ref.read(autoSyncServiceProvider).schedulePush();
    }
  }

  DocumentReference<Map<String, dynamic>> _doc(String uid) => FirebaseFirestore
      .instance
      .collection('users')
      .doc(uid)
      .collection('meta')
      .doc('profile');

  /// Membangun payload dokumen profil yang sesuai dengan aturan validasi Firestore.
  @visibleForTesting
  Map<String, dynamic> buildCloudPayload(String uid, {int? updatedAt}) {
    final p = ref.read(sharedPreferencesProvider);
    final rawNick = p.getString(_nickKey(uid));
    final nick = rawNick != null && rawNick.length > 100
        ? rawNick.substring(0, 100)
        : rawNick;
    final rawPhoto = p.getString(_photoKey(uid));
    final safePhoto = (rawPhoto != null && rawPhoto.length <= maxPhotoBase64Length)
        ? rawPhoto
        : null;
    final rawFrame = p.getString(_frameKey(uid));
    final frameId = profileFrameAssetPath(rawFrame) != null ? rawFrame : null;
    return {
      'nickname': nick,
      'photo': safePhoto,
      'frameId': frameId,
      'updatedAt': updatedAt ?? (p.getInt(_updatedKey(uid)) ?? 0),
    };
  }

  /// Unggah profil ke cloud bila ada perubahan lokal atau dipaksa saat backup manual.
  Future<void> uploadToCloud(String uid, {bool force = false}) async {
    final p = ref.read(sharedPreferencesProvider);
    final localAt = p.getInt(_updatedKey(uid)) ?? 0;
    final syncedAt = p.getInt(_syncedKey(uid)) ?? 0;
    if (localAt <= 0) return;
    if (!force && localAt <= syncedAt) return;

    final snap = await _doc(uid).get().timeout(_timeout);
    final remoteData = snap.data();
    final remoteAt = (remoteData?['updatedAt'] as num?)?.toInt() ?? 0;
    if (remoteData != null && remoteAt > localAt) {
      await applyRemoteData(remoteData, uid);
      return;
    }
    if (!force && snap.exists && remoteData != null && remoteAt == localAt) {
      await p.setInt(_syncedKey(uid), localAt);
      return;
    }

    await _doc(uid)
        .set(buildCloudPayload(uid, updatedAt: localAt))
        .timeout(_timeout);
    await p.setInt(_syncedKey(uid), localAt);
  }

  /// Terapkan data profil dari cloud jika lebih baru dari data lokal di perangkat.
  Future<bool> applyRemoteData(Map<String, dynamic> data, String uid) async {
    final p = ref.read(sharedPreferencesProvider);
    final remoteAt = (data['updatedAt'] as num?)?.toInt() ?? 0;
    if (remoteAt <= (p.getInt(_updatedKey(uid)) ?? 0)) return false;

    final nick = data['nickname'] is String ? data['nickname'] as String : null;
    final rawPhoto = data['photo'] is String ? data['photo'] as String : null;
    final rawFrame = data['frameId'] is String ? data['frameId'] as String : null;
    final frameId = profileFrameAssetPath(rawFrame) != null ? rawFrame : null;
    final photo = (rawPhoto != null && rawPhoto.length <= maxPhotoBase64Length)
        ? rawPhoto
        : null;
    nick == null ? await p.remove(_nickKey(uid)) : await p.setString(_nickKey(uid), nick);
    photo == null ? await p.remove(_photoKey(uid)) : await p.setString(_photoKey(uid), photo);
    frameId == null ? await p.remove(_frameKey(uid)) : await p.setString(_frameKey(uid), frameId);
    await p.setInt(_updatedKey(uid), remoteAt);
    await p.setInt(_syncedKey(uid), remoteAt);
    state = ProfileState(
      nickname: nick,
      photo: _safeDecodePhoto(photo),
      frameId: frameId,
    );
    return true;
  }

  /// Ambil profil dari cloud jika lebih baru dari yang ada di perangkat.
  Future<void> restoreFromCloud(String uid) async {
    final snap = await _doc(uid).get().timeout(_timeout);
    final data = snap.data();
    if (data == null) return;
    await applyRemoteData(data, uid);
  }

  /// Migrasikan profil mode tamu ke akun pengguna saat mendaftar/menautkan akun.
  Future<void> migrateGuestToUser(String uid) async {
    final p = ref.read(sharedPreferencesProvider);
    final guestNick = p.getString(_nickKey(guestId));
    final guestPhoto = p.getString(_photoKey(guestId));
    final guestFrame = p.getString(_frameKey(guestId));
    final guestUpdated = p.getInt(_updatedKey(guestId));

    var migrated = false;
    if (guestNick != null && p.getString(_nickKey(uid)) == null) {
      await p.setString(_nickKey(uid), guestNick);
      migrated = true;
    }
    if (guestPhoto != null && p.getString(_photoKey(uid)) == null) {
      await p.setString(_photoKey(uid), guestPhoto);
      migrated = true;
    }
    if (guestFrame != null && p.getString(_frameKey(uid)) == null) {
      await p.setString(_frameKey(uid), guestFrame);
      migrated = true;
    }
    if (guestUpdated != null && p.getInt(_updatedKey(uid)) == null) {
      await p.setInt(_updatedKey(uid), guestUpdated);
    } else if (migrated && p.getInt(_updatedKey(uid)) == null) {
      await _touchUpdated(p, uid);
    }

    await p.remove(_nickKey(guestId));
    await p.remove(_photoKey(guestId));
    await p.remove(_frameKey(guestId));
    await p.remove(_updatedKey(guestId));
    await p.remove(_syncedKey(guestId));

    final b64 = p.getString(_photoKey(uid));
    final rawFrame = p.getString(_frameKey(uid));
    state = ProfileState(
      nickname: p.getString(_nickKey(uid)),
      photo: _safeDecodePhoto(b64),
      frameId: profileFrameAssetPath(rawFrame) != null ? rawFrame : null,
    );
  }

  /// Bersihkan data profil lokal saat logout atau hapus akun.
  Future<void> clearLocal([String? uid]) async {
    final effectiveUid = uid ?? _effectiveUid;
    final p = ref.read(sharedPreferencesProvider);
    await p.remove(_nickKey(effectiveUid));
    await p.remove(_photoKey(effectiveUid));
    await p.remove(_frameKey(effectiveUid));
    await p.remove(_updatedKey(effectiveUid));
    await p.remove(_syncedKey(effectiveUid));
    state = ProfileState();
  }
}

final profileProvider =
    NotifierProvider<ProfileController, ProfileState>(ProfileController.new);

/// Nama untuk sapaan di Home: nickname, atau username, atau bagian depan email.
final displayNameProvider = Provider<String?>((ref) {
  final nick = ref.watch(profileProvider).nickname?.trim();
  if (nick != null && nick.isNotEmpty) return nick;
  final username = ref.watch(usernameProvider);
  if (username != null) return username;
  final email = ref.watch(currentUserProvider)?.email ?? '';
  final local = email.split('@').first;
  if (local.isEmpty) return null;
  return local[0].toUpperCase() + local.substring(1);
});
