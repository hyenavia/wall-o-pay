import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'cloud_sync.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.code);

  final String code;
}

/// Login dengan email atau username. Firebase Auth hanya mengenal email,
/// jadi username dipetakan ke email lewat koleksi Firestore `usernames`.
class AuthService {
  static final _usernameRe = RegExp(r'^[A-Za-z0-9_.]{3,20}$');

  static bool isValidUsername(String s) => _usernameRe.hasMatch(s);

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _fs => FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _usernameDoc(String username) =>
      _fs.collection('usernames').doc(username.trim().toLowerCase());

  /// Mengubah username atau email yang diketik menjadi email.
  Future<String> _resolveEmail(String identifier) async {
    final id = identifier.trim();
    if (id.contains('@')) return id;
    final snap = await _usernameDoc(id).get();
    final email = snap.data()?['email'] as String?;
    if (email == null) throw const AuthFailure('invalid-credential');
    return email;
  }

  Future<void> signIn(String identifier, String password) async {
    final email = await _resolveEmail(identifier);
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    final name = username.trim();
    if (!isValidUsername(name)) throw const AuthFailure('invalid-username');

    final doc = _usernameDoc(name);
    if ((await doc.get()).exists) throw const AuthFailure('username-taken');

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    try {
      await doc.set({
        'uid': user.uid,
        'email': user.email ?? email.trim(),
        'username': name,
      });
      await _fs.collection('users').doc(user.uid).set({
        'username': name,
        'email': user.email ?? email.trim(),
      }, SetOptions(merge: true));
      await user.updateDisplayName(name);
    } catch (_) {
      // Username keduluan dipakai orang lain: batalkan akun yang baru dibuat.
      await user.delete();
      throw const AuthFailure('username-taken');
    }
  }

  Future<void> sendPasswordReset(String identifier) async {
    final email = await _resolveEmail(identifier);
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Hapus seluruh data Firestore dan pemetaan username pengguna saat user masih terotentikasi.
  Future<void> wipeCloudDataAndUsernames(String uid, {String? knownUsername}) async {
    final usernamesToDelete = <String>{};
    if (knownUsername != null && knownUsername.trim().isNotEmpty) {
      usernamesToDelete.add(knownUsername.trim().toLowerCase());
    }

    final user = _auth.currentUser;
    final displayName = user?.displayName?.trim().toLowerCase();
    if (displayName != null && displayName.isNotEmpty) {
      usernamesToDelete.add(displayName);
    }

    try {
      final userDoc = await _fs.collection('users').doc(uid).get().timeout(const Duration(seconds: 10));
      final uName = userDoc.data()?['username'] as String?;
      if (uName != null && uName.trim().isNotEmpty) {
        usernamesToDelete.add(uName.trim().toLowerCase());
      }
    } catch (_) {}

    try {
      final snap = await _fs.collection('usernames').where('uid', isEqualTo: uid).get().timeout(const Duration(seconds: 10));
      for (final doc in snap.docs) {
        usernamesToDelete.add(doc.id.toLowerCase());
      }
    } catch (e) {
      debugPrint('[AuthService] Query usernames failed: $e');
    }

    // Hapus seluruh dokumen username berdasarkan doc id langsung
    for (final name in usernamesToDelete) {
      try {
        await _usernameDoc(name).delete().timeout(const Duration(seconds: 10));
        debugPrint('[AuthService] Successfully deleted username reservation: $name');
      } catch (e) {
        debugPrint('[AuthService] Error deleting username doc $name: $e');
      }
    }

    // Hapus seluruh koleksi data keuangan
    await AutoSyncService.wipeCloudUserData(uid);

    // Hapus dokumen root pengguna
    try {
      await _fs.collection('users').doc(uid).delete().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[AuthService] Error deleting user root doc: $e');
    }
  }

  /// Menghapus akun pengguna secara permanen dari Firebase Authentication,
  /// menghapus pemetaan username di Firestore, dan menghapus seluruh koleksi data cloud.
  Future<void> deleteAccount({String? password, String? username}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    // 1. Re-autentikasi jika password diisi
    if (password != null && password.isNotEmpty && user.email != null) {
      try {
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(cred);
      } catch (e) {
        debugPrint('[AuthService] Re-authentication failed before delete: $e');
        rethrow;
      }
    }

    // 2. Hapus seluruh data cloud dan pemetaan username selagi masih terotentikasi
    await wipeCloudDataAndUsernames(uid, knownUsername: username);

    // 3. Hapus akun pengguna di Firebase Authentication
    await user.delete();
    debugPrint('[AuthService] Successfully deleted user account: $uid');
  }
}
