import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cloud.dart';
import '../../data/feature_prefs.dart';
import '../../data/notifications.dart';
import '../../data/prefs.dart';
import '../../data/providers.dart';
import '../../data/recurring_service.dart';
import 'onboarding_page.dart';

/// Menampilkan onboarding sekali untuk pengguna baru, dan menjalankan tugas
/// latar saat aplikasi dibuka: membuat transaksi berulang yang jatuh tempo
/// dan menyesuaikan jadwal pengingat harian.
class OnboardingGate extends ConsumerStatefulWidget {
  const OnboardingGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends ConsumerState<OnboardingGate>
    with WidgetsBindingObserver {
  late Future<bool> _needed;

  String get _doneKey =>
      'onboarding_done_${ref.read(currentUserProvider)?.uid ?? 'local'}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _needed = _check();
    _background();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _background();
  }

  Future<bool> _check() async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs.getBool(_doneKey) ?? false) return false;
    final hasData = await ref.read(databaseProvider).hasAnyTransaction();
    if (hasData) {
      await prefs.setBool(_doneKey, true);
      return false;
    }
    return true;
  }

  Future<void> _background() async {
    try {
      await RecurringService.checkAndGenerateDue(ref.read(databaseProvider));
      final f = ref.read(featurePrefsProvider);
      await NotificationService.instance
          .syncReminder(enabled: f.dailyReminder, time: f.reminderTime);
    } catch (e) {
      debugPrint('Background tasks failed: $e');
    }
  }

  void _finish() {
    ref.read(sharedPreferencesProvider).setBool(_doneKey, true);
    setState(() => _needed = Future.value(false));
    _background();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _needed,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snap.data! ? OnboardingPage(onDone: _finish) : widget.child;
      },
    );
  }
}
