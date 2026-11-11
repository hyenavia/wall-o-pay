/// Halaman autentikasi pengguna ([AuthPage]) untuk masuk menggunakan email/username,
/// mendaftar akun baru, mereset kata sandi, atau masuk dalam Mode Tamu (offline).
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/brand.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/auth_service.dart';
import '../../data/cloud.dart';
import '../../data/cloud_sync.dart';
import '../../data/prefs.dart';
import '../../data/providers.dart';

/// Layar pertama: masuk (dengan email atau username), daftar akun baru, atau lanjut sebagai tamu.
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key, this.initialRegister = false});

  final bool initialRegister;

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _identifier = TextEditingController(); // email atau username (login)
  final _username = TextEditingController(); // daftar
  final _email = TextEditingController(); // daftar
  final _password = TextEditingController();
  final _auth = AuthService();

  late bool _register = widget.initialRegister;
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _identifier.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Jika pengguna memiliki transaksi lokal dari Mode Tamu lalu login ke akun yang sudah ada,
  /// tanyakan apakah ingin menggabungkan data tamu atau memakai data cloud saja.
  Future<bool?> _askGuestDataChoice() async {
    final lastUid = ref.read(sharedPreferencesProvider).getString('current_sync_user_id');
    if (lastUid != null) return true;
    final hasTx = await ref.read(databaseProvider).hasAnyTransaction();
    if (!hasTx || !mounted) return true;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('Keep Guest Data?')),
        content: Text(ctx.tr(
          'You have local transactions recorded in Guest mode. Would you like to merge them into your account, or replace them with your cloud backup?',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(ctx.tr('Cancel')),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('Use Cloud Only')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.tr('Merge Data')),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final password = _password.text;
    if (_register) {
      if (_username.text.trim().isEmpty ||
          _email.text.trim().isEmpty ||
          password.isEmpty) {
        setState(() {
          _error = context.tr('Fill in username, email, and password.');
          _info = null;
        });
        return;
      }
      if (!AuthService.isValidUsername(_username.text.trim())) {
        setState(() {
          _error = context.tr('Username must be 3-20 characters: letters, numbers, "." or "_".');
          _info = null;
        });
        return;
      }
    } else if (_identifier.text.trim().isEmpty || password.isEmpty) {
      setState(() {
        _error = context.tr('Enter your email or username and password.');
        _info = null;
      });
      return;
    }

    var discardGuest = false;
    if (!_register) {
      final keep = await _askGuestDataChoice();
      if (keep == null) return;
      discardGuest = !keep;
    }

    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final syncService = ref.read(autoSyncServiceProvider);
    syncService.discardGuestDataOnNextLogin = discardGuest;
    try {
      if (_register) {
        await _auth.signUp(
          username: _username.text,
          email: _email.text,
          password: password,
        );
      } else {
        await _auth.signIn(_identifier.text, password);
      }
      await ref.read(skipAuthProvider.notifier).reset();
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
      }
    } on AuthFailure catch (e) {
      syncService.discardGuestDataOnNextLogin = false;
      if (mounted) setState(() => _error = _message(e.code));
    } on FirebaseException catch (e) {
      syncService.discardGuestDataOnNextLogin = false;
      if (mounted) setState(() => _error = _message(e.code));
    } catch (e) {
      syncService.discardGuestDataOnNextLogin = false;
      if (mounted) {
        setState(() => _error = context.tr('Something went wrong: {error}', {'error': e}));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final id = _register ? _email.text : _identifier.text;
    if (id.trim().isEmpty) {
      setState(() {
        _error = context.tr('Enter your email or username first, then tap "Forgot password?".');
        _info = null;
      });
      return;
    }
    try {
      await _auth.sendPasswordReset(id);
      if (mounted) {
        setState(() {
          _error = null;
          _info = context.tr('A password reset email has been sent.');
        });
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = _message(e.code));
    } on FirebaseException catch (e) {
      if (mounted) setState(() => _error = _message(e.code));
    }
  }

  String _message(String code) {
    switch (code) {
      case 'invalid-email':
        return context.tr('That email address is not valid.');
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return context.tr('Incorrect username/email or password.');
      case 'email-already-in-use':
        return context.tr('This email is already registered. Try logging in.');
      case 'weak-password':
        return context.tr('Password is too weak (at least 6 characters).');
      case 'network-request-failed':
      case 'unavailable':
        return context.tr('No internet connection.');
      case 'operation-not-allowed':
        return context.tr('Email/password sign-in is not enabled in Firebase.');
      case 'username-taken':
        return context.tr('This username is already taken.');
      case 'invalid-username':
        return context.tr('Username must be 3-20 characters: letters, numbers, "." or "_".');
      case 'permission-denied':
        return context.tr('Access denied. Check your Firestore rules.');
      default:
        return context.tr('Failed ({code}).', {'code': code});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final localeCode = ref.watch(appPrefsProvider.select((p) => p.localeCode));
    final prefs = ref.read(appPrefsProvider.notifier);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            Row(
              children: [
                if (canPop) ...[
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                ],
                const BrandMark(size: 52),
                const Spacer(),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  segments: const [
                    ButtonSegment(value: 'en', label: Text('EN')),
                    ButtonSegment(value: 'id', label: Text('ID')),
                  ],
                  selected: {localeCode},
                  onSelectionChanged: (s) => prefs.setLocale(s.first),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              context.tr(_register ? 'Create account' : 'Welcome Back'),
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(_register
                  ? 'Sign up to back up your data to the cloud and use it on any device.'
                  : 'Log in to continue your financial journey.'),
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: 28),
            if (_register) ...[
              TextField(
                controller: _username,
                autocorrect: false,
                decoration: appInput(
                  context,
                  label: context.tr('Username'),
                  prefixIcon: const Icon(Icons.alternate_email),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: appInput(context, label: context.tr('Email')),
              ),
            ] else
              TextField(
                controller: _identifier,
                autocorrect: false,
                autofillHints: const [AutofillHints.username],
                decoration: appInput(context, label: context.tr('Email or username')),
              ),
            const SizedBox(height: 14),
            TextField(
              controller: _password,
              obscureText: _hidePassword,
              decoration: appInput(
                context,
                label: context.tr('Password'),
                suffixIcon: IconButton(
                  icon: Icon(
                    _hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                ),
              ),
            ),
            if (!_register)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy ? null : _forgotPassword,
                  child: Text(context.tr('Forgot password?')),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: context.themeColors.expense)),
            ],
            if (_info != null) ...[
              const SizedBox(height: 8),
              Text(_info!, style: TextStyle(color: theme.colorScheme.primary)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.glasshouseGreen,
                foregroundColor: AppColors.softIvory,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AppColors.dewMint.withValues(alpha: 0.35)),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.softIvory),
                    )
                  : Text(
                      context.tr(_register ? 'Sign Up' : 'Login'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    context.tr(_register ? 'Already have an account?' : "Don't have an account?"),
                    style: const TextStyle(color: AppColors.freshSage),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: AppColors.dewMint),
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _register = !_register;
                            _error = null;
                            _info = null;
                          }),
                  child: Text(
                    context.tr(_register ? 'Login' : 'Sign Up'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (!canPop) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.dewMint.withValues(alpha: 0.15))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      context.tr('or'),
                      style: const TextStyle(color: AppColors.freshSage, fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.dewMint.withValues(alpha: 0.15))),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => ref.read(skipAuthProvider.notifier).skip(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: AppColors.dewMint,
                  side: BorderSide(color: AppColors.dewMint.withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.person_outline_rounded, size: 20),
                label: Text(
                  context.tr('Continue as Guest'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(
                  '100% offline on this device. You can link an account anytime.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.freshSage),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ditampilkan jika Firebase belum dihubungkan, sehingga login belum bisa dipakai.
class FirebaseMissingPage extends ConsumerWidget {
  const FirebaseMissingPage({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandMark(size: 56),
              const SizedBox(height: 24),
              Text(
                context.tr('Firebase is not connected'),
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                context.tr('Login and sign up need a Firebase project. Run "flutterfire configure" in the project, then restart the app.'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.tonal(
                onPressed: onContinue,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: Text(context.tr('Continue without account')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
