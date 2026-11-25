/// Konfigurasi root aplikasi (`MaterialApp`), gerbang autentikasi (`AuthGate`),
/// serta kerangka navigasi utama 4 tab (`HomeShell`).
library;

import 'dart:async';
import 'dart:math' as math;

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
import 'data/feature_prefs.dart';
import 'data/module_prefs.dart';
import 'data/notifications.dart';
import 'data/prefs.dart';
import 'data/providers.dart';
import 'data/update_checker.dart';
import 'data/recurring_service.dart' hide recurringRulesProvider;
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
          : const _AuthLoadingScreen(),
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
            uid: user.uid,
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
    _checkRecapNotification();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await ref.read(autoSyncServiceProvider).startSync(user.uid);
      }
    });
    Future.delayed(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;
      await UpdateCheckerService.checkAndNotify(ref, context: context);
    });
  }

  void _checkRecapNotification() {
    final features = ref.read(featurePrefsProvider);
    final appPrefs = ref.read(appPrefsProvider);
    checkHarvestRecapNotification(
      db: ref.read(databaseProvider),
      prefs: ref.read(sharedPreferencesProvider),
      enabled: features.recapAlerts,
      periodType: appPrefs.periodType,
      firstDayOfWeek: appPrefs.firstDayOfWeek,
      firstDayOfMonth: appPrefs.firstDayOfMonth,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      UpdateCheckerService.checkAndNotify(ref, context: context);
      RecurringService.checkAndGenerateDue(ref.read(databaseProvider));
      checkDebtDueReminders(ref.read(databaseProvider));
      _checkRecapNotification();
      ShareService.checkSharedData(context);
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.read(autoSyncServiceProvider).triggerTwoWaySync();
      }
    }
  }

  @override
  void dispose() {
    ShareService.detachContext(context);
    UpdateCheckerService.cancelPendingPrompt();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<User?>(currentUserProvider, (previous, next) {
      if (next != null) {
        unawaited(ref.read(autoSyncServiceProvider).startSync(next.uid));
      } else {
        ref.read(autoSyncServiceProvider).stopSync();
      }
    });

    ref.listen<bool>(modulePrefsProvider.select((m) => m.budget), (_, enabled) {
      if (!enabled && ref.read(tabIndexProvider) == 2) {
        ref.read(tabIndexProvider.notifier).set(0);
      }
    });

    final colors = context.themeColors;
    final budgetEnabled = ref.watch(modulePrefsProvider.select((m) => m.budget));
    final rawIndex = ref.watch(tabIndexProvider);
    final index = (!budgetEnabled && rawIndex == 2) ? 0 : rawIndex;
    _visitedTabs.add(index);
    final notifier = ref.read(tabIndexProvider.notifier);

    Widget item(int i, IconData icon, IconData activeIcon, String label, {String? glassIcon}) {
      final selected = index == i;
      const activeColor = AppColors.goldenYellow;
      final inactiveColor = AppColors.mutedBlueGray.withValues(alpha: 0.82);

      final Widget iconWidget;
      if (glassIcon != null) {
        iconWidget = AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          opacity: selected ? 1.0 : 0.65,
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
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          child: ExcludeSemantics(
            child: InkWell(
              onTap: () => notifier.set(i),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconWidget,
                  const SizedBox(height: 3),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? activeColor : inactiveColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
            child: Image.asset(
              'assets/icons/vice_city/logout.png',
              width: 32,
              height: 32,
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

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 600;
    final isExpanded = screenWidth >= 900;

    final tabs = <(int, IconData, IconData, String, String)>[
      (0, Icons.home_outlined, Icons.home, context.tr('Home'), 'assets/icons/vice_city/home.png'),
      (1, Icons.receipt_long_outlined, Icons.receipt_long, context.tr('Transactions'), 'assets/icons/vice_city/card.png'),
      if (budgetEnabled)
        (2, Icons.pie_chart_outline, Icons.pie_chart, context.tr('Budget'), 'assets/icons/vice_city/pie_chart.png'),
      (3, Icons.insights_outlined, Icons.insights, context.tr('Insight'), 'assets/icons/vice_city/growth.png'),
    ];
    final railSelectedIndex = tabs.indexWhere((t) => t.$1 == index).clamp(0, tabs.length - 1);

    final fabButton = FloatingActionButton(
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
              AppColors.sunsetMagenta,
              AppColors.sunsetOrange,
            ],
          ),
          border: Border.all(
            color: AppColors.goldenYellow.withValues(alpha: 0.65),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.sunsetMagenta.withValues(alpha: 0.45),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            'assets/icons/vice_city/add.png',
            width: 32,
            height: 32,
          ),
        ),
      ),
    );

    final content = IndexedStack(
      index: index,
      children: [
        for (int i = 0; i < _pages.length; i++)
          _visitedTabs.contains(i) ? _pages[i] : const SizedBox.shrink(),
      ],
    );

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
      child: isWide
          ? Scaffold(
              body: SafeArea(
                child: Row(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: SizedBox(
                            height: math.max(constraints.maxHeight, 360.0),
                            child: NavigationRail(
                              extended: isExpanded,
                              backgroundColor: AppColors.deepNavy,
                              indicatorColor: AppColors.sunsetMagenta.withValues(alpha: 0.22),
                              labelType: isExpanded
                                  ? NavigationRailLabelType.none
                                  : NavigationRailLabelType.all,
                              selectedLabelTextStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.goldenYellow,
                              ),
                              unselectedLabelTextStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.mutedBlueGray.withValues(alpha: 0.82),
                              ),
                              leading: Padding(
                                padding: const EdgeInsets.only(top: 12, bottom: 16),
                                child: fabButton,
                              ),
                              selectedIndex: railSelectedIndex,
                              onDestinationSelected: (railIdx) => notifier.set(tabs[railIdx].$1),
                              destinations: [
                                for (final t in tabs)
                                  NavigationRailDestination(
                                    icon: Opacity(
                                      opacity: 0.65,
                                      child: Image.asset(
                                        t.$5,
                                        width: 24,
                                        height: 24,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    selectedIcon: Image.asset(
                                      t.$5,
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.contain,
                                    ),
                                    label: Text(t.$4),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: AppColors.borderOutline.withValues(alpha: 0.75),
                    ),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 920),
                          child: content,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Scaffold(
              body: content,
              floatingActionButton: fabButton,
              floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
              bottomNavigationBar: BottomAppBar(
                shape: const CircularNotchedRectangle(),
                notchMargin: 8,
                height: 68,
                padding: EdgeInsets.zero,
                color: AppColors.deepNavy,
                surfaceTintColor: Colors.transparent,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.borderOutline.withValues(alpha: 0.75),
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
                        glassIcon: 'assets/icons/vice_city/home.png',
                      ),
                      item(
                        1,
                        Icons.receipt_long_outlined,
                        Icons.receipt_long,
                        context.tr('Transactions'),
                        glassIcon: 'assets/icons/vice_city/card.png',
                      ),
                      const SizedBox(width: 64),
                      if (budgetEnabled)
                        item(
                          2,
                          Icons.pie_chart_outline,
                          Icons.pie_chart,
                          context.tr('Budget'),
                          glassIcon: 'assets/icons/vice_city/pie_chart.png',
                        ),
                      item(
                        3,
                        Icons.insights_outlined,
                        Icons.insights,
                        context.tr('Insight'),
                        glassIcon: 'assets/icons/vice_city/growth.png',
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.sage),
        ),
      ),
    );
  }
}
