/// Gerbang penguncian layar ([LockGate]), papan tombol PIN ([PinPad]),
/// layar pembuka kunci ([LockScreen]), serta dialog pembuatan/verifikasi PIN 6 digit.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/brand.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/budget_rule.dart';
import '../../data/cloud.dart';
import '../../data/lock.dart';
import '../../data/prefs.dart';
import '../../data/profile.dart';
import '../../data/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Membungkus aplikasi: terkunci saat dibuka (jika PIN aktif),
/// dan terkunci kembali setelah ditinggalkan di latar belakang sesuai batas waktu.
class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  late bool locked = Lock.instance.state.value.enabled;
  DateTime? leftAt;

  @override
  void initState() {
    super.initState();
    Lock.instance.isLocked.value = locked;
    WidgetsBinding.instance.addObserver(this);
    Lock.instance.state.addListener(_onLockStateChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Lock.instance.state.removeListener(_onLockStateChanged);
    super.dispose();
  }

  void _onLockStateChanged() {
    if (!Lock.instance.state.value.enabled && locked) {
      Lock.instance.isLocked.value = false;
      setState(() => locked = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (Lock.instance.isAuthenticatingBiometric) return;
    final st = Lock.instance.state.value;
    if (state == AppLifecycleState.paused) {
      leftAt = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      final previousLeftAt = leftAt;
      leftAt = null;
      if (st.enabled && previousLeftAt != null && !locked) {
        final timeout = st.delayMin == 0
            ? const Duration(seconds: 3)
            : Duration(minutes: st.delayMin);
        if (DateTime.now().difference(previousLeftAt) >= timeout) {
          if (mounted) {
            try {
              Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
            } catch (_) {}
            Lock.instance.isLocked.value = true;
            setState(() => locked = true);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (locked)
          Positioned.fill(
            child: LockScreen(
              onUnlock: () {
                Lock.instance.isLocked.value = false;
                setState(() => locked = false);
              },
            ),
          ),
      ],
    );
  }
}

/// Papan tombol angka PIN dengan indikator 6 titik dan tombol biometrik opsional.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.value,
    required this.onChanged,
    this.length = 6,
    this.onBiometricTap,
    this.biometricIcon = Icons.fingerprint_rounded,
    this.biometricTooltip,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final int length;
  final VoidCallback? onBiometricTap;
  final IconData biometricIcon;
  final String? biometricTooltip;

  Widget _key(BuildContext context, Widget child, VoidCallback? tap) {
    final isCyber = context.isCyberpunk;
    final shape = isCyber
        ? BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: tap == null
                  ? Colors.transparent
                  : context.themeColors.primary.withValues(alpha: 0.35),
            ),
          )
        : const CircleBorder();

    return Padding(
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Material(
          color: Colors.white.withValues(alpha: tap == null ? 0 : (isCyber ? 0.08 : 0.12)),
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: tap,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  Widget _digit(BuildContext context, int d) => _key(
        context,
        Text(
          '$d',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFamily: context.isCyberpunk ? 'Rajdhani' : null,
          ),
        ),
        value.length < length ? () => onChanged('$value$d') : null,
      );

  @override
  Widget build(BuildContext context) {
    final isCyber = context.isCyberpunk;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < length; i++)
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 7),
                decoration: ShapeDecoration(
                  color: i < value.length
                      ? (isCyber
                          ? context.themeColors.primary
                          : const Color(0xFF6EE7B7))
                      : Colors.white.withValues(alpha: 0.22),
                  shape: isCyber
                      ? BeveledRectangleBorder(borderRadius: BorderRadius.circular(3.5))
                      : const CircleBorder(),
                  shadows: i < value.length
                      ? [
                          BoxShadow(
                            color: (isCyber
                                    ? context.themeColors.primary
                                    : const Color(0xFF6EE7B7))
                                .withValues(alpha: 0.45),
                            blurRadius: isCyber ? 12 : 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: 28),
        for (final row in const [
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9]
        ])
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [for (final d in row) _digit(context, d)],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            onBiometricTap != null
                ? _key(
                    context,
                    Tooltip(
                      message: biometricTooltip ?? '',
                      child: Icon(
                        biometricIcon,
                        color: isCyber
                            ? context.themeColors.primary
                            : const Color(0xFF6EE7B7),
                        size: 28,
                      ),
                    ),
                    onBiometricTap,
                  )
                : const SizedBox(width: 84, height: 84),
            _digit(context, 0),
            _key(
              context,
              const Icon(Icons.backspace_outlined, color: Colors.white, size: 22),
              value.isEmpty ? null : () => onChanged(value.substring(0, value.length - 1)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Layar pembuka kunci PIN utama aplikasi.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key, required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String pin = '';
  String? msg;
  bool _autoPrompted = false;

  String _lockoutMessage(BuildContext context) {
    final sec = Lock.instance.remainingLockoutSeconds;
    if (sec > 0) {
      return context.tr(
        'Please wait {seconds}s before trying again.',
        {'seconds': sec},
      );
    }
    return context.tr('Please wait before trying again.');
  }

  Future<void> _tryBiometric() async {
    if (Lock.instance.isLockedOut) {
      setState(() => msg = _lockoutMessage(context));
      return;
    }
    final ok = await Lock.instance.authenticateBiometric(
      localizedReason: context.tr('Verify your identity to unlock Wall o\' Pay'),
    );
    if (ok && mounted) {
      widget.onUnlock();
    }
  }

  void _changed(String v) {
    if (Lock.instance.isLockedOut) {
      setState(() => msg = _lockoutMessage(context));
      return;
    }
    setState(() {
      pin = v;
      msg = null;
    });
    if (v.length < 6) return;

    if (Lock.instance.verify(v)) {
      widget.onUnlock();
      return;
    }

    setState(() {
      pin = '';
      msg = Lock.instance.isLockedOut
          ? _lockoutMessage(context)
          : context.tr('Incorrect PIN. Try again.');
    });
  }

  Future<void> _forgot() async {
    final isGuest = ref.read(currentUserProvider) == null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('Forgot PIN?')),
        content: Text(context.tr(
          isGuest
              ? 'In Guest mode without an account, resetting a forgotten PIN will erase all local data on this device for security.'
              : 'Forgot PIN? For security, you can log out to reset your PIN.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.themeColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr(isGuest ? 'Erase All Data' : 'Log Out')),
          ),
        ],
      ),
    );

    if (ok == true) {
      if (isGuest) {
        try {
          await ref.read(databaseProvider).resetAllData();
          await ref.read(profileProvider.notifier).clearLocal(ProfileController.guestId);
          await ref.read(budgetRuleProvider.notifier).clearLocal();
          await Lock.instance.clearLocal('guest');
          await ref.read(sharedPreferencesProvider).remove('onboarding_done_local');
          await ref.read(skipAuthProvider.notifier).reset();
        } catch (_) {}
      } else {
        await Lock.instance.disable();
        try {
          await FirebaseAuth.instance.signOut();
        } catch (_) {}
      }
      widget.onUnlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLockState>(
      valueListenable: Lock.instance.state,
      builder: (context, st, _) {
        if (st.biometricEnabled &&
            !_autoPrompted &&
            !Lock.instance.bypassForQuickAction.value) {
          _autoPrompted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !Lock.instance.bypassForQuickAction.value) {
              _tryBiometric();
            }
          });
        }
        final promptText = !st.biometricEnabled
            ? context.tr('Enter your 6-digit PIN')
            : st.isFaceOnly
                ? context.tr('Enter 6-digit PIN or use Face Unlock')
                : st.isFingerprintOnly
                    ? context.tr('Enter 6-digit PIN or scan fingerprint')
                    : context.tr('Enter 6-digit PIN or use biometric');

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: context.isCyberpunk
                    ? const [
                        Color(0xFF13172E),
                        Color(0xFF080912),
                      ]
                    : const [
                        AppColors.deepForest,
                        Color(0xFF0F241A),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BrandMark(size: 64),
                      const SizedBox(height: 12),
                      const Text(
                        "Wall o' Pay",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        promptText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      PinPad(
                        value: pin,
                        onChanged: _changed,
                        onBiometricTap: st.biometricEnabled ? _tryBiometric : null,
                        biometricIcon: st.isFaceOnly
                            ? Icons.face_rounded
                            : Icons.fingerprint_rounded,
                        biometricTooltip: context.tr('Unlock with Biometric'),
                      ),
                      SizedBox(
                        height: 44,
                        child: msg == null
                            ? null
                            : Center(
                                child: Text(
                                  msg!,
                                  style: const TextStyle(
                                    color: Color(0xFFFFB3C7),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                      ),
                      TextButton(
                        onPressed: _forgot,
                        child: Text(
                          context.tr('Forgot PIN?'),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Alur pengaturan PIN baru atau verifikasi PIN.
class _PinFlow extends StatefulWidget {
  const _PinFlow({required this.create, required this.title});

  final bool create;
  final String title;

  @override
  State<_PinFlow> createState() => _PinFlowState();
}

class _PinFlowState extends State<_PinFlow> {
  String pin = '';
  String? first;
  String? msg;

  void _changed(String v) {
    if (!widget.create && Lock.instance.isLockedOut) {
      final sec = Lock.instance.remainingLockoutSeconds;
      setState(() {
        msg = context.tr(
          'Please wait {seconds}s before trying again.',
          {'seconds': sec},
        );
      });
      return;
    }
    setState(() {
      pin = v;
      msg = null;
    });
    if (v.length < 6) return;

    if (!widget.create) {
      if (Lock.instance.verify(v)) {
        Navigator.pop(context, true);
      } else {
        final sec = Lock.instance.remainingLockoutSeconds;
        setState(() {
          pin = '';
          msg = Lock.instance.isLockedOut
              ? context.tr(
                  'Please wait {seconds}s before trying again.',
                  {'seconds': sec},
                )
              : context.tr('Incorrect PIN. Try again.');
        });
      }
    } else if (first == null) {
      setState(() {
        first = v;
        pin = '';
      });
    } else if (first == v) {
      Navigator.pop(context, v);
    } else {
      setState(() {
        first = null;
        pin = '';
        msg = context.tr('PIN does not match. Try again.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.create
        ? (first == null
            ? context.tr('Create 6-digit PIN')
            : context.tr('Confirm 6-digit PIN'))
        : widget.title;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: context.isCyberpunk
                ? const [
                    Color(0xFF13172E),
                    Color(0xFF080912),
                  ]
                : const [
                    AppColors.deepForest,
                    Color(0xFF0F241A),
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          titleText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        PinPad(value: pin, onChanged: _changed),
                        SizedBox(
                          height: 44,
                          child: msg == null
                              ? null
                              : Center(
                                  child: Text(
                                    msg!,
                                    style: const TextStyle(
                                      color: Color(0xFFFFB3C7),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minta PIN yang berlaku; true jika benar.
Future<bool> askPin(BuildContext context, {String? title}) async {
  return await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _PinFlow(
            create: false,
            title: title ?? context.tr('Enter your 6-digit PIN'),
          ),
        ),
      ) ??
      false;
}

/// Buat PIN baru (dua kali ketik); null jika dibatalkan.
Future<String?> createPin(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const _PinFlow(create: true, title: ''),
    ),
  );
}

