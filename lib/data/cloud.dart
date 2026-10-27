import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Diisi true oleh main.dart jika Firebase berhasil diinisialisasi.
final firebaseReadyProvider = Provider<bool>((ref) => false);

/// Memantau perubahan akun, termasuk saat nama pengguna (displayName) diatur.
final authStateProvider = StreamProvider<User?>((ref) {
  if (!ref.watch(firebaseReadyProvider)) return const Stream<User?>.empty();
  return FirebaseAuth.instance.userChanges();
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).maybeWhen(
        data: (u) => u,
        orElse: () => null,
      );
});

/// Username akun (disimpan di displayName saat mendaftar).
final usernameProvider = Provider<String?>((ref) {
  final name = ref.watch(currentUserProvider)?.displayName?.trim();
  return (name == null || name.isEmpty) ? null : name;
});

/// Untuk mode darurat tanpa Firebase: lanjut memakai aplikasi tanpa akun.
class SkipAuth extends Notifier<bool> {
  @override
  bool build() => false;

  void skip() => state = true;
}

final skipAuthProvider = NotifierProvider<SkipAuth, bool>(SkipAuth.new);
