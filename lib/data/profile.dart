/// Pengelolaan profil pengguna (nickname dan foto profil Base64) yang disimpan per akun
/// di perangkat lokal dan disinkronkan ke Cloud Firestore.
library;

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show MemoryImage;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cloud.dart';
import 'cloud_sync.dart';
import 'prefs.dart';

class ProfileState {
  ProfileState({this.nickname, this.photo})
      : photoImage = photo == null ? null : MemoryImage(photo);

  final String? nickname;
  final Uint8List? photo;
  final MemoryImage? photoImage;
}

/// Nickname dan foto profil, disimpan per akun di perangkat.
/// Ikut tercadangkan saat pengguna menekan tombol backup cloud.
class ProfileController extends Notifier<ProfileState> {
  static const guestId = 'guest';
  static const _timeout = Duration(seconds: 30);

  String _nickKey(String uid) => 'nickname_$uid';
  String _photoKey(String uid) => 'photo_$uid';
  String _updatedKey(String uid) => 'profile_updated_$uid';

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
    return ProfileState(
      nickname: p.getString(_nickKey(uid)),
      photo: _safeDecodePhoto(b64),
    );
  }

  String? get _uid => ref.read(currentUserProvider)?.uid;
  String get _effectiveUid => _uid ?? guestId;

  Future<void> setNickname(String value) async {
    final uid = _effectiveUid;
    final p = ref.read(sharedPreferencesProvider);
    final nick = value.trim();
    if (nick.isEmpty) {
      await p.remove(_nickKey(uid));
    } else {
      await p.setString(_nickKey(uid), nick);
    }
    await p.setInt(_updatedKey(uid), DateTime.now().millisecondsSinceEpoch);
    state = ProfileState(nickname: nick.isEmpty ? null : nick, photo: state.photo);
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
    await p.setInt(_updatedKey(uid), DateTime.now().millisecondsSinceEpoch);
    state = ProfileState(nickname: state.nickname, photo: bytes);
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

  /// Unggah profil ke cloud (dipanggil saat backup).
  Future<void> uploadToCloud(String uid) async {
    final p = ref.read(sharedPreferencesProvider);
    await _doc(uid).set({
      'nickname': p.getString(_nickKey(uid)),
      'photo': p.getString(_photoKey(uid)),
      'updatedAt': p.getInt(_updatedKey(uid)) ?? 0,
    }).timeout(_timeout);
  }

  /// Ambil profil dari cloud jika lebih baru dari yang ada di perangkat.
  Future<void> restoreFromCloud(String uid) async {
    final snap = await _doc(uid).get().timeout(_timeout);
    final data = snap.data();
    if (data == null) return;
    final p = ref.read(sharedPreferencesProvider);
    final remoteAt = (data['updatedAt'] as num?)?.toInt() ?? 0;
    if (remoteAt <= (p.getInt(_updatedKey(uid)) ?? 0)) return;

    final nick = data['nickname'] is String ? data['nickname'] as String : null;
    final rawPhoto = data['photo'] is String ? data['photo'] as String : null;
    final photo = (rawPhoto != null && rawPhoto.length <= maxPhotoBase64Length)
        ? rawPhoto
        : null;
    nick == null ? await p.remove(_nickKey(uid)) : await p.setString(_nickKey(uid), nick);
    photo == null ? await p.remove(_photoKey(uid)) : await p.setString(_photoKey(uid), photo);
    await p.setInt(_updatedKey(uid), remoteAt);
    state = ProfileState(
      nickname: nick,
      photo: _safeDecodePhoto(photo),
    );
  }

  /// Migrasikan profil mode tamu ke akun pengguna saat mendaftar/menautkan akun.
  Future<void> migrateGuestToUser(String uid) async {
    final p = ref.read(sharedPreferencesProvider);
    final guestNick = p.getString(_nickKey(guestId));
    final guestPhoto = p.getString(_photoKey(guestId));
    final guestUpdated = p.getInt(_updatedKey(guestId));

    if (guestNick != null && p.getString(_nickKey(uid)) == null) {
      await p.setString(_nickKey(uid), guestNick);
    }
    if (guestPhoto != null && p.getString(_photoKey(uid)) == null) {
      await p.setString(_photoKey(uid), guestPhoto);
    }
    if (guestUpdated != null && p.getInt(_updatedKey(uid)) == null) {
      await p.setInt(_updatedKey(uid), guestUpdated);
    }

    await p.remove(_nickKey(guestId));
    await p.remove(_photoKey(guestId));
    await p.remove(_updatedKey(guestId));

    final b64 = p.getString(_photoKey(uid));
    state = ProfileState(
      nickname: p.getString(_nickKey(uid)),
      photo: _safeDecodePhoto(b64),
    );
  }

  /// Bersihkan data profil lokal saat logout atau hapus akun.
  Future<void> clearLocal([String? uid]) async {
    final effectiveUid = uid ?? _effectiveUid;
    final p = ref.read(sharedPreferencesProvider);
    await p.remove(_nickKey(effectiveUid));
    await p.remove(_photoKey(effectiveUid));
    await p.remove(_updatedKey(effectiveUid));
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
