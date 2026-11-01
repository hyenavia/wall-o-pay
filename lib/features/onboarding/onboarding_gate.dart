import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _loading = true;
  bool _needsOnboarding = false;

  String get _doneKey =>
      'onboarding_done_${ref.read(currentUserProvider)?.uid ?? 'local'}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
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

  Future<void> _check() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      if (prefs.getBool(_doneKey) ?? false) {
        if (mounted) setState(() { _loading = false; _needsOnboarding = false; });
        return;
      }
      final user = ref.read(currentUserProvider);
      if (user != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('meta')
              .doc('preferences')
              .get()
              .timeout(const Duration(seconds: 3));
          if (doc.exists && doc.data()?['onboardingDone'] == true) {
            await prefs.setBool(_doneKey, true);
            if (mounted) setState(() { _loading = false; _needsOnboarding = false; });
            return;
          }
        } catch (_) {}
      }
      final hasData = await ref.read(databaseProvider).hasAnyTransaction();
      if (hasData) {
        await prefs.setBool(_doneKey, true);
        if (mounted) setState(() { _loading = false; _needsOnboarding = false; });
        return;
      }
      if (mounted) setState(() { _loading = false; _needsOnboarding = true; });
    } catch (e) {
      debugPrint('Error checking onboarding: $e');
      if (mounted) setState(() { _loading = false; _needsOnboarding = false; });
    }
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
    if (mounted) {
      setState(() => _needsOnboarding = false);
    }
    final user = ref.read(currentUserProvider);
    if (user != null) {
      ref.read(appPrefsProvider.notifier).uploadToCloud(user.uid);
    }
    _background();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _needsOnboarding ? OnboardingPage(onDone: _finish) : widget.child;
  }
}
