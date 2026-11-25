/// Konfigurasi root aplikasi (`MaterialApp`), gerbang autentikasi (`AuthGate`),
/// serta kerangka navigasi utama 4 tab (`HomeShell`).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

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
      themeMode: prefs.themeMode,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
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

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
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
    final budgetEnabled = ref.watch(
      modulePrefsProvider.select((m) => m.budget),
    );
    final rawIndex = ref.watch(tabIndexProvider);
    final index = (!budgetEnabled && rawIndex == 2) ? 0 : rawIndex;
    _visitedTabs.add(index);
    final notifier = ref.read(tabIndexProvider.notifier);

    Widget item(int i, PhosphorDuotoneIconData icon, String label) {
      final selected = index == i;
      final activeColor = colors.isDark
          ? AppColors.goldenYellow
          : colors.primary;
      final inactiveColor = colors.isDark
          ? AppColors.mutedBlueGray.withValues(alpha: 0.82)
          : colors.textMuted;

      final iconColor = selected ? activeColor : inactiveColor;
      final iconWidget = PhosphorDuotoneIcon(
        icon,
        color: iconColor,
        secondaryColor: iconColor.withValues(alpha: selected ? 0.28 : 0.14),
        size: 25,
      );

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
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: PhosphorDuotoneIcon(
              PhosphorIconsDuotone.signOut,
              color: colors.primary,
              secondaryColor: colors.primary.withValues(alpha: 0.24),
              size: 30,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: Text(ctx.tr('Stay in App')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
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

    final tabs = <(int, PhosphorDuotoneIconData, String)>[
      (0, PhosphorIconsDuotone.house, context.tr('Home')),
      (1, PhosphorIconsDuotone.receipt, context.tr('Transactions')),
      if (budgetEnabled)
        (2, PhosphorIconsDuotone.chartPieSlice, context.tr('Budget')),
      (3, PhosphorIconsDuotone.chartLineUp, context.tr('Insight')),
    ];
    final railSelectedIndex = tabs
        .indexWhere((t) => t.$1 == index)
        .clamp(0, tabs.length - 1);

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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors.isDark
                ? const [AppColors.sunsetMagenta, AppColors.sunsetOrange]
                : [colors.primary, AppColors.sunsetMagenta],
          ),
          border: Border.all(
            color: colors.isDark
                ? AppColors.goldenYellow.withValues(alpha: 0.65)
                : Colors.white.withValues(alpha: 0.45),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.42),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: PhosphorDuotoneIcon(
            PhosphorIconsDuotone.plus,
            size: 28,
            color: Colors.white,
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
                              backgroundColor: colors.cardSurface,
                              indicatorColor: colors.primary.withValues(
                                alpha: 0.16,
                              ),
                              labelType: isExpanded
                                  ? NavigationRailLabelType.none
                                  : NavigationRailLabelType.all,
                              selectedLabelTextStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colors.isDark
                                    ? AppColors.goldenYellow
                                    : colors.primary,
                              ),
                              unselectedLabelTextStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colors.isDark
                                    ? AppColors.mutedBlueGray.withValues(
                                        alpha: 0.82,
                                      )
                                    : colors.textMuted,
                              ),
                              leading: Padding(
                                padding: const EdgeInsets.only(
                                  top: 12,
                                  bottom: 16,
                                ),
                                child: fabButton,
                              ),
                              selectedIndex: railSelectedIndex,
                              onDestinationSelected: (railIdx) =>
                                  notifier.set(tabs[railIdx].$1),
                              destinations: [
                                for (final t in tabs)
                                  NavigationRailDestination(
                                    icon: PhosphorDuotoneIcon(
                                      t.$2,
                                      size: 24,
                                      color: colors.isDark
                                          ? AppColors.mutedBlueGray.withValues(
                                              alpha: 0.82,
                                            )
                                          : colors.textMuted,
                                      secondaryColor:
                                          (colors.isDark
                                                  ? AppColors.mutedBlueGray
                                                  : colors.textMuted)
                                              .withValues(alpha: 0.14),
                                    ),
                                    selectedIcon: PhosphorDuotoneIcon(
                                      t.$2,
                                      size: 24,
                                      color: colors.isDark
                                          ? AppColors.goldenYellow
                                          : colors.primary,
                                      secondaryColor:
                                          (colors.isDark
                                                  ? AppColors.goldenYellow
                                                  : colors.primary)
                                              .withValues(alpha: 0.28),
                                    ),
                                    label: Text(t.$3),
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
                      color: colors.borderOutline.withValues(
                        alpha: colors.isDark ? 0.75 : 1.0,
                      ),
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
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
              bottomNavigationBar: BottomAppBar(
                shape: const CircularNotchedRectangle(),
                notchMargin: 8,
                height: 68,
                padding: EdgeInsets.zero,
                color: colors.cardSurface,
                surfaceTintColor: Colors.transparent,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: colors.borderOutline.withValues(
                          alpha: colors.isDark ? 0.75 : 1.0,
                        ),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      item(0, PhosphorIconsDuotone.house, context.tr('Home')),
                      item(
                        1,
                        PhosphorIconsDuotone.receipt,
                        context.tr('Transactions'),
                      ),
                      const SizedBox(width: 64),
                      if (budgetEnabled)
                        item(
                          2,
                          PhosphorIconsDuotone.chartPieSlice,
                          context.tr('Budget'),
                        ),
                      item(
                        3,
                        PhosphorIconsDuotone.chartLineUp,
                        context.tr('Insight'),
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
    final colors = context.themeColors;
    return Scaffold(
      backgroundColor: colors.bg,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
        ),
      ),
    );
  }
}
