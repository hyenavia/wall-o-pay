/// Konfigurasi root aplikasi (`MaterialApp`), gerbang autentikasi (`AuthGate`),
/// serta kerangka navigasi utama 4 tab (`HomeShell`).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/brand.dart';
import 'core/l10n.dart';
import 'core/theme.dart';
import 'core/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'data/cloud.dart';
import 'data/cloud_sync.dart';
import 'data/notifications.dart';
import 'data/prefs.dart';
import 'data/providers.dart';
import 'data/quick_widget_service.dart';
import 'data/update_checker.dart';
import 'data/recurring_service.dart';
import 'data/share_service.dart';
import 'features/auth/auth_page.dart';
import 'features/budget/budget_page.dart';
import 'features/insights/insights_page.dart';
import 'features/home/home_page.dart';
import 'features/onboarding/onboarding_gate.dart';
import 'features/security/lock_screen.dart';
import 'features/transactions/transaction_form.dart';
import 'features/transactions/transactions_page.dart';

/// Widget root `MaterialApp` yang mengatur tema Botanical Forest, bahasa aktif,
/// dan delegasi lokalisasi aplikasi.
class WallOPayApp extends ConsumerWidget {
  const WallOPayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPrefsProvider);

    return MaterialApp(
      title: "Wall o' Pay",
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: buildTheme(),
      darkTheme: buildTheme(),
      locale: Locale(prefs.localeCode),
      supportedLocales: AppLocale.supported,
      localizationsDelegates: [
        AppStrings.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: const _Root(),
    );
  }
}

/// Menampilkan layar splash bertema Enchanted Glasshouse, lalu lanjut ke gerbang autentikasi.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _ready = ShareService.hasPendingShortcut;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    if (!_ready) {
      // Fallback pengaman agar aplikasi selalu lanjut jika terjadi interupsi lifecycle
      _fallbackTimer = Timer(const Duration(milliseconds: 2200), () {
        if (mounted && !_ready) setState(() => _ready = true);
      });
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _ready
          ? const AuthGate(key: ValueKey('gate'))
          : SplashPage(
              key: const ValueKey('splash'),
              onFinish: () {
                if (mounted && !_ready) {
                  setState(() => _ready = true);
                }
              },
            ),
    );
  }
}

/// Aplikasi bisa dipakai setelah login/daftar atau melalui Mode Tamu (offline).
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(firebaseReadyProvider);
    final skip = ref.watch(skipAuthProvider);
    if (!ready) {
      return skip
          ? const LockGate(
              key: ValueKey('guest'),
              child: OnboardingGate(child: HomeShell()),
            )
          : FirebaseMissingPage(
              onContinue: () => ref.read(skipAuthProvider.notifier).skip(),
            );
    }

    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => skip
          ? const LockGate(
              key: ValueKey('guest'),
              child: OnboardingGate(child: HomeShell()),
            )
          : const SplashPage(),
      error: (e, _) => skip
          ? const LockGate(
              key: ValueKey('guest'),
              child: OnboardingGate(child: HomeShell()),
            )
          : const AuthPage(),
      data: (user) {
        if (user != null) {
          return LockGate(
            key: ValueKey(user.uid),
            child: const OnboardingGate(child: HomeShell()),
          );
        }
        if (skip) {
          return const LockGate(
            key: ValueKey('guest'),
            child: OnboardingGate(child: HomeShell()),
          );
        }
        return const AuthPage();
      },
    );
  }
}

/// Kerangka utama aplikasi setelah pengguna melewati autentikasi, kunci PIN, dan onboarding.
/// Menyediakan navigasi bawah 4 tab (Home, Transactions, Budget, Insight), tombol tambah transaksi,
/// serta memantau siklus hidup aplikasi (lifecycle) untuk sinkronisasi otomatis dan pengingat.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> with WidgetsBindingObserver {
  final Set<int> _visitedTabs = {0};

  static const _pages = <Widget>[
    HomePage(),
    TransactionsPage(),
    BudgetPage(),
    InsightsPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ShareService.initialize(context, ref);
    RecurringService.checkAndGenerateDue(ref.read(databaseProvider));
    checkDebtDueReminders(ref.read(databaseProvider));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.read(autoSyncServiceProvider).startSync(user.uid);
      }
      syncWidgetData(ref);
    });
    Future.delayed(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;
      await UpdateCheckerService.checkAndNotify(ref, context: context);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      UpdateCheckerService.checkAndNotify(ref, context: context);
      RecurringService.checkAndGenerateDue(ref.read(databaseProvider));
      checkDebtDueReminders(ref.read(databaseProvider));
      ShareService.checkSharedData(context);
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.read(autoSyncServiceProvider).triggerTwoWaySync();
      }
      syncWidgetData(ref);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<User?>(currentUserProvider, (previous, next) {
      if (next != null) {
        ref.read(autoSyncServiceProvider).startSync(next.uid);
      } else {
        ref.read(autoSyncServiceProvider).stopSync();
      }
    });

    // Sinkronisasi data widget setiap kali total saldo atau status sensor berubah.
    ref.listen<int>(totalCurrentBalanceProvider, (_, _) => syncWidgetData(ref));
    ref.listen<bool>(hideBalanceProvider, (_, _) => syncWidgetData(ref));

    final colors = context.themeColors;
    final index = ref.watch(tabIndexProvider);
    _visitedTabs.add(index);
    final notifier = ref.read(tabIndexProvider.notifier);

    Widget item(int i, IconData icon, IconData activeIcon, String label, {String? glassIcon}) {
      final selected = index == i;
      const activeColor = AppColors.dewMint;
      final inactiveColor = AppColors.freshSage.withValues(alpha: 0.55);

      final Widget iconWidget;
      if (glassIcon != null) {
        iconWidget = AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          opacity: selected ? 1.0 : 0.38,
          child: Image.asset(
            glassIcon,
            width: 26,
            height: 26,
            fit: BoxFit.contain,
          ),
        );
      } else {
        iconWidget = Icon(
          selected ? activeIcon : icon,
          color: selected ? activeColor : inactiveColor,
          size: 26,
        );
      }

      return Expanded(
        child: InkWell(
          onTap: () => notifier.set(i),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Future<bool> showExitDialog(BuildContext context) async {
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.exit_to_app_rounded,
              color: colors.primary,
              size: 32,
            ),
          ),
          title: Text(
            ctx.tr('Exit Application'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            ctx.tr('Are you sure you want to exit Wall o\' Pay?'),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(ctx.tr('Stay in App')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: colors.heroBackground,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              child: Text(ctx.tr('Exit')),
            ),
          ],
        ),
      );
      return result ?? false;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (index != 0) {
          notifier.set(0);
          return;
        }
        final shouldExit = await showExitDialog(context);
        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: index,
          children: [
            for (int i = 0; i < _pages.length; i++)
              _visitedTabs.contains(i) ? _pages[i] : const SizedBox.shrink(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: context.tr('Add transaction'),
          shape: const CircleBorder(),
          backgroundColor: Colors.transparent,
          elevation: 6,
          onPressed: () => showTransactionForm(context),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF38B271),
                  Color(0xFF1E4F39),
                ],
              ),
              border: Border.all(
                color: AppColors.dewMint.withValues(alpha: 0.55),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.income.withValues(alpha: 0.40),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                'assets/icons/glasshouse/add.png',
                width: 32,
                height: 32,
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          height: 66,
          padding: EdgeInsets.zero,
          color: AppColors.mossShadow,
          surfaceTintColor: Colors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.dewMint.withValues(alpha: 0.16),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                item(
                  0,
                  Icons.home_outlined,
                  Icons.home,
                  context.tr('Home'),
                  glassIcon: 'assets/icons/glasshouse/home.png',
                ),
                item(
                  1,
                  Icons.receipt_long_outlined,
                  Icons.receipt_long,
                  context.tr('Transactions'),
                  glassIcon: 'assets/icons/glasshouse/receipt.png',
                ),
                const SizedBox(width: 64),
                item(
                  2,
                  Icons.pie_chart_outline,
                  Icons.pie_chart,
                  context.tr('Budget'),
                  glassIcon: 'assets/icons/glasshouse/savings.png',
                ),
                item(
                  3,
                  Icons.insights_outlined,
                  Icons.insights,
                  context.tr('Insight'),
                  glassIcon: 'assets/icons/glasshouse/investment.png',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
