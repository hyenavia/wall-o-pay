import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/brand.dart';
import 'core/l10n.dart';
import 'core/theme.dart';
import 'data/cloud.dart';
import 'data/prefs.dart';
import 'data/providers.dart';
import 'data/update_checker.dart';
import 'features/auth/auth_page.dart';
import 'features/budget/budget_page.dart';
import 'features/goals/goals_page.dart';
import 'features/home/home_page.dart';
import 'features/security/lock_screen.dart';
import 'features/transactions/transaction_form.dart';
import 'features/transactions/transactions_page.dart';

class WallOPayApp extends ConsumerWidget {
  const WallOPayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPrefsProvider);

    return MaterialApp(
      title: "Wall o' Pay",
      debugShowCheckedModeBanner: false,
      themeMode: prefs.themeMode,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
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

/// Menampilkan splash sebentar, lalu lanjut ke gerbang login.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _ready = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _ready
          ? const AuthGate(key: ValueKey('gate'))
          : const SplashPage(key: ValueKey('splash')),
    );
  }
}

/// Aplikasi hanya bisa dipakai setelah login atau daftar.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(firebaseReadyProvider);
    if (!ready) {
      final skip = ref.watch(skipAuthProvider);
      return skip
          ? const LockGate(child: HomeShell())
          : FirebaseMissingPage(
              onContinue: () => ref.read(skipAuthProvider.notifier).skip(),
            );
    }

    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const SplashPage(),
      error: (e, _) => const AuthPage(),
      data: (user) => user == null
          ? const AuthPage()
          : LockGate(key: ValueKey(user.uid), child: const HomeShell()),
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> with WidgetsBindingObserver {

  static const _pages = <Widget>[
    HomePage(),
    TransactionsPage(),
    BudgetPage(),
    GoalsPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;
      await UpdateCheckerService.checkAndNotify(ref, context: context);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      UpdateCheckerService.checkAndNotify(ref, context: context);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final index = ref.watch(tabIndexProvider);
    final notifier = ref.read(tabIndexProvider.notifier);

    Widget item(int i, IconData icon, IconData activeIcon, String label) {
      final selected = index == i;
      final color = selected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.5);
      return Expanded(
        child: InkWell(
          onTap: () => notifier.set(i),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? activeIcon : icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
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
              color: AppColors.deepForest.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.exit_to_app_rounded,
              color: AppColors.deepForest,
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
              child: Text(ctx.tr('Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.deepForest,
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
        body: IndexedStack(index: index, children: _pages),
        floatingActionButton: FloatingActionButton(
          tooltip: context.tr('Add transaction'),
          shape: const CircleBorder(),
          backgroundColor: AppColors.deepForest,
          foregroundColor: Colors.white,
          onPressed: () => showTransactionForm(context),
          child: const Icon(Icons.add, size: 28),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          height: 66,
          padding: EdgeInsets.zero,
          color: scheme.surface,
          surfaceTintColor: Colors.transparent,
          child: Row(
            children: [
              item(0, Icons.home_outlined, Icons.home, context.tr('Home')),
              item(1, Icons.receipt_long_outlined, Icons.receipt_long,
                  context.tr('Transactions')),
              const SizedBox(width: 64),
              item(2, Icons.pie_chart_outline, Icons.pie_chart, context.tr('Budget')),
              item(3, Icons.flag_outlined, Icons.flag, context.tr('Goals')),
            ],
          ),
        ),
      ),
    );
  }
}
