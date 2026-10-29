import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/brand.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/lock.dart';

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
      setState(() => locked = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final st = Lock.instance.state.value;
    if (state == AppLifecycleState.paused) {
      leftAt = DateTime.now();
    }
    if (state == AppLifecycleState.resumed && st.enabled && leftAt != null && !locked) {
      final timeout = st.delayMin == 0
          ? const Duration(seconds: 3)
          : Duration(minutes: st.delayMin);
      if (DateTime.now().difference(leftAt!) >= timeout) {
        if (mounted) {
          try {
            Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
          } catch (_) {}
          setState(() => locked = true);
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
              onUnlock: () => setState(() => locked = false),
            ),
          ),
      ],
    );
  }
}

/// Papan tombol angka PIN dengan indikator 6 titik.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.value,
    required this.onChanged,
    this.length = 6,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final int length;

  Widget _key(Widget child, VoidCallback? tap) => Padding(
        padding: const EdgeInsets.all(6),
        child: SizedBox(
          width: 72,
          height: 72,
          child: Material(
            color: Colors.white.withValues(alpha: tap == null ? 0 : 0.12),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: tap,
              child: Center(child: child),
            ),
          ),
        ),
      );

  Widget _digit(int d) => _key(
        Text(
          '$d',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        value.length < length ? () => onChanged('$value$d') : null,
      );

  @override
  Widget build(BuildContext context) {
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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < value.length
                      ? const Color(0xFF6EE7B7)
                      : Colors.white.withValues(alpha: 0.22),
                  boxShadow: i < value.length
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6EE7B7).withValues(alpha: 0.4),
                            blurRadius: 8,
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
            children: [for (final d in row) _digit(d)],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 84, height: 84),
            _digit(0),
            _key(
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
class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String pin = '';
  String? msg;
  int fails = 0;
  DateTime? until;

  void _changed(String v) {
    if (until != null && DateTime.now().isBefore(until!)) {
      setState(() => msg = context.tr('Please wait before trying again.'));
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

    fails++;
    setState(() {
      pin = '';
      msg = context.tr('Incorrect PIN. Try again.');
      if (fails >= 5) {
        until = DateTime.now().add(const Duration(seconds: 30));
        fails = 0;
        msg = context.tr('Please wait before trying again.');
      }
    });
  }

  Future<void> _forgot() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('Forgot PIN?')),
        content: Text(context.tr(
          'Forgot PIN? For security, you can log out to reset your PIN.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('Log Out')),
          ),
        ],
      ),
    );

    if (ok == true) {
      await Lock.instance.disable();
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      widget.onUnlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
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
                    context.tr('Enter your 6-digit PIN'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
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
    setState(() {
      pin = v;
      msg = null;
    });
    if (v.length < 6) return;

    if (!widget.create) {
      if (Lock.instance.verify(v)) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          pin = '';
          msg = context.tr('Incorrect PIN. Try again.');
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
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

