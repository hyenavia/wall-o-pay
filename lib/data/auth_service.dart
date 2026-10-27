import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
}
