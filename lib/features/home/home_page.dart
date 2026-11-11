/// Halaman Beranda utama ([HomePage]) yang menampilkan sapaan profil, kartu saldo & arus kas periode,
/// indikator Daily Financial Pulse, pintasan cepat, ringkasan dompet, dan transaksi terbaru.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/botanical_decorations.dart';
import '../../core/l10n.dart';
import '../../core/period.dart';
import '../../core/widgets.dart';
import '../../data/profile.dart';
import '../../data/providers.dart';
import '../../data/app_database.dart' show Wallet;
import '../../data/tables.dart' show TxType;

import '../accounts/accounts_page.dart';
import '../profile/profile_page.dart';
import '../settings/settings_page.dart';
import '../more/more_page.dart';
import 'daily_financial_pulse_card.dart';
import '../transactions/transaction_form.dart';
import '../transactions/transaction_tile.dart';
import '../../data/budget_rule.dart';
import '../../data/cloud_sync.dart';
import '../../data/update_checker.dart';

/// Widget halaman tab Beranda (Home) pada navigasi utama aplikasi.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider);
    final isWeekly = period.type == PeriodType.weekly;
    final txAsync = ref.watch(transactionsProvider);
    final cats = ref.watch(categoryMapProvider);
    final budgets = ref.watch(budgetByCategoryProvider);
    final spent = ref.watch(spentByCategoryProvider);
    final name = ref.watch(displayNameProvider);
    final updateInfo = ref.watch(availableUpdateProvider);

    void openProfile() => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
        );
    void openMore() => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const MorePage()),
        );
    void openSettings() => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
        );

    return Scaffold(
      backgroundColor: AppColors.headerCanopyTop,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            // Atmospheric Sunlit Conservatory Backdrop Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 220,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/glasshouse_bg.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.headerCanopyTop.withValues(alpha: 0.78),
                          AppColors.headerCanopyBottom.withValues(alpha: 0.96),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 140,
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    isComplex: true,
                    painter: BotanicalCanopyPainter(opacity: 0.12),
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _HomeHeader(
                    name: name,
                    onProfile: openProfile,
                    onMore: openMore,
                    onSettings: openSettings,
                  ),
                  Expanded(
                    child: _Sheet(
                      child: txAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text(context.tr('Could not load data: {error}', {'error': e})),
                    ),
                    data: (txs) {
                      final income = txs
                          .where((t) => t.type == TxType.income)
                          .fold<int>(0, (s, t) => s + t.amount);
                      final expense = txs
                          .where((t) => t.type == TxType.expense)
                          .fold<int>(0, (s, t) => s + t.amount);
                      final balance = income - expense;
                      final totalBalance = ref.watch(totalCurrentBalanceProvider);

                      final budgetPool = ref.watch(currentTotalBudgetPoolProvider);
                      final totalBudget = budgetPool > 0
                          ? budgetPool
                          : budgets.values.fold<int>(0, (a, b) => a + b);
                      final budgetSpent = budgetPool > 0
                          ? expense
                          : budgets.keys.fold<int>(0, (a, id) => a + (spent[id] ?? 0));

                      final daysLeft = period.daysLeft;
                      final dailyAllowance =
                          balance > 0 && daysLeft > 0 ? balance ~/ daysLeft : 0;
                      final isCurrent = period.isCurrent;

                      final now = DateTime.now();
                      final todayStart = DateTime(now.year, now.month, now.day);
                      final todayEnd = todayStart.add(const Duration(days: 1));
                      final todayExpense = txs
                          .where((t) =>
                              t.type == TxType.expense &&
                              !t.date.isBefore(todayStart) &&
                              t.date.isBefore(todayEnd))
                          .fold<int>(0, (s, t) => s + t.amount);

                      final budgetTitle = isCurrent
                          ? (isWeekly ? "This Week's Budget" : "This Month's Budget")
                          : (isWeekly ? 'Weekly Budget' : 'Monthly Budget');

                      final savedPct = income > 0
                          ? ((income - expense) * 100 / income).round()
                          : null;

                      return RefreshIndicator(
                        onRefresh: () async {
                          await Future.wait([
                            ref.read(autoSyncServiceProvider).triggerTwoWaySync(),
                            UpdateCheckerService.checkAndNotify(ref, context: context),
                          ]);
                        },
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
                          children: [
                            if (updateInfo != null) ...[
                              _UpdateBannerCard(
                                info: updateInfo,
                                onDismiss: () => ref.read(availableUpdateProvider.notifier).dismiss(),
                                onUpdate: () => UpdateCheckerService.showUpdateDialog(context, updateInfo),
                              ),
                              const SizedBox(height: 12),
                            ],
                            const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Expanded(child: PeriodSwitcher(compact: true)),
                                  PeriodTypeToggle(compact: true),
                                ],
                              ),
                            ),
                            _BalanceCard(
                              totalBalance: totalBalance,
                              periodFlow: balance,
                              periodLabel: context.tr(isWeekly ? 'Weekly Flow' : 'Monthly Flow'),
                              income: income,
                              expense: expense,
                              savedPct: savedPct,
                            ),
                            const SizedBox(height: 14),
                            DailyFinancialPulseCard(
                              dailyAllowance: dailyAllowance,
                              todayExpense: todayExpense,
                              daysLeft: daysLeft,
                              balance: balance,
                              totalBudget: totalBudget,
                              budgetSpent: budgetSpent,
                              txCount: txs.length,
                              budgetTitle: budgetTitle,
                              onSetBudget: () => ref.read(tabIndexProvider.notifier).set(2),
                            ),
                            const SizedBox(height: 16),
                            SectionHeader(
                              title: context.tr('Recent Transactions'),
                              actionLabel: context.tr('See All'),
                              onAction: () => ref.read(tabIndexProvider.notifier).set(1),
                            ),
                            if (txs.isEmpty)
                              EmptyStateCard(
                                title: context.tr('Start recording your first transaction!'),
                                subtitle: context.tr(
                                  'Every small transaction brings you closer to your financial goals.',
                                ),
                                actionLabel: context.tr('Add transaction'),
                                onAction: () => showTransactionForm(context),
                              )
                            else
                              TransactionGroupCard(
                                children: [
                                  for (final t in txs.take(4))
                                    TransactionTile(
                                      entry: t,
                                      category: cats[t.categoryId],
                                      trailingNote: shortDate(t.date),
                                      onTap: () => showTransactionForm(context, entry: t),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
          ],
        ),
      ),
    );
  }
}

/// Header hijau di Beranda: foto, sapaan, status sinkronisasi, menu lainnya, dan pengaturan.
class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({
    required this.name,
    required this.onProfile,
    required this.onMore,
    required this.onSettings,
  });

  final String? name;
  final VoidCallback onProfile;
  final VoidCallback onMore;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sync = ref.watch(syncStateProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 18),
      child: Row(
        children: [
          UserAvatar(size: 48, withGlassFrame: true, onTap: onProfile),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Baris 1: Sapaan
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        greeting(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.freshSage,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (sync.status == SyncStatus.syncing) ...[
                      const SizedBox(width: 6),
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: AppColors.dewMint,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                // Baris 2: Nama Pengguna
                Text(
                  (name != null && name!.trim().isNotEmpty)
                      ? name!.trim()
                      : context.tr('Wall o\' Pay'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.softIvory,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.dewMint.withValues(alpha: 0.22),
                width: 1.0,
              ),
            ),
            child: IconButton(
              tooltip: context.tr('More Features'),
              padding: EdgeInsets.zero,
              color: Colors.white,
              icon: const Icon(Icons.grid_view_rounded, size: 20),
              onPressed: onMore,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.dewMint.withValues(alpha: 0.22),
                width: 1.0,
              ),
            ),
            child: IconButton(
              tooltip: context.tr('Settings'),
              padding: EdgeInsets.zero,
              color: Colors.white,
              icon: const Icon(Icons.settings_outlined, size: 20),
              onPressed: onSettings,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lembar background berujung melengkung di bawah header hijau bergaya Enchanted Glasshouse.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: AppColors.dewMint.withValues(alpha: 0.28),
            width: 1.2,
          ),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF163228), // Deep emerald mist at the top
            Color(0xFF11251E), // Subtle moss tint
            Color(0xFF0C1914), // Deep grounding moss shadow
          ],
          stops: [0.0, 0.40, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Suasana Rumah Kaca Alami dari Aset Fotorealistik
          Positioned.fill(
            child: Opacity(
              opacity: 0.10,
              child: Image.asset(
                'assets/images/glasshouse_bg.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  isComplex: true,
                  painter: BotanicalBackgroundPainter(),
                ),
              ),
            ),
          ),
          child,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 18,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF163228).withValues(alpha: 0.85),
                      const Color(0xFF163228).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard({
    required this.totalBalance,
    required this.periodFlow,
    required this.periodLabel,
    required this.income,
    required this.expense,
    this.savedPct,
  });

  final int totalBalance;
  final int periodFlow;
  final String periodLabel;
  final int income;
  final int expense;
  final int? savedPct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSurplus = periodFlow >= 0;
    final hidden = ref.watch(hideBalanceProvider);
    final wallets = ref.watch(walletsProvider).value ?? const [];

    Widget blurred(Widget child) => hidden
        ? ClipRect(child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: child))
        : child;

    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const AccountsPage()),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              context.tr('Total Balance'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (savedPct != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+$savedPct% ${context.tr('saved')}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              IconButton(
                tooltip: context.tr(hidden ? 'Show amounts' : 'Hide amounts'),
                visualDensity: VisualDensity.compact,
                color: Colors.white70,
                icon: Icon(hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => ref.read(hideBalanceProvider.notifier).toggle(),
              ),
            ],
          ),
          const SizedBox(height: 2),
          blurred(
            AnimatedMoneyCounter(
              amount: totalBalance,
              style: context.moneyStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Builder(
            builder: (ctx) {
              final c = ctx.themeColors;
              final flowColor = isSurplus ? c.income : c.expense;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSurplus ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 15,
                      color: flowColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$periodLabel: ',
                      style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                    blurred(
                      Text(
                        isSurplus ? '+${rupiah(periodFlow)}' : rupiah(periodFlow),
                        style: ctx.moneyStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: flowColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _FlowTile(
                    icon: Icons.arrow_downward,
                    label: context.tr('Income'),
                    value: rupiah(income),
                    blurred: hidden,
                  ),
                ),
                Container(width: 1, height: 36, color: Colors.white24),
                const SizedBox(width: 12),
                Expanded(
                  child: _FlowTile(
                    icon: Icons.arrow_upward,
                    label: context.tr('Expense'),
                    value: rupiah(expense),
                    blurred: hidden,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _AccountsQuickBar(wallets: wallets),
        ],
      ),
    );
  }
}

class _AccountsQuickBar extends StatelessWidget {
  const _AccountsQuickBar({required this.wallets});

  final List<Wallet> wallets;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AccountsPage()),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.dewMint.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              if (wallets.isEmpty) ...[
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('Add accounts & wallets'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.freshSage,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ] else ...[
                _buildStackedAvatars(context),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _buildSummary(context),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.dewMint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStackedAvatars(BuildContext context) {
    const avatarSize = 22.0;
    const overlap = 14.0;
    final displayed = wallets.take(3).toList();
    final extra = wallets.length - displayed.length;
    final totalBadges = displayed.length + (extra > 0 ? 1 : 0);
    final width = avatarSize + (totalBadges - 1) * overlap;

    return SizedBox(
      width: width,
      height: avatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < displayed.length; i++)
            Positioned(
              left: i * overlap,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: Color(displayed[i].colorValue),
                  shape: BoxShape.circle,
                  border: Border.all(color: context.themeColors.heroBackground, width: 1.5),
                ),
                child: Icon(
                  accountIcon(displayed[i].type),
                  size: 11,
                  color: Colors.white,
                ),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: displayed.length * overlap,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: context.themeColors.heroBackground, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$extra',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _buildSummary(BuildContext context) {
    final count = wallets.length;
    final countLabel = count == 1
        ? context.tr('1 Account')
        : context.tr('{count} Accounts', {'count': count});
    final names = wallets.take(2).map((w) => context.tr(w.name)).join(', ');
    final suffix = count > 2 ? '...' : '';
    return '$countLabel · $names$suffix';
  }
}

class _FlowTile extends StatelessWidget {
  const _FlowTile({required this.icon, required this.label, required this.value, this.blurred = false});

  final IconData icon;
  final String label;
  final String value;
  final bool blurred;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueWidget = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.moneyStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
    final isIncome = icon == Icons.arrow_downward;
    final accentColor = isIncome ? AppColors.incomeOnDark : AppColors.expenseOnDark;
    final bgTint = isIncome
        ? AppColors.income.withValues(alpha: 0.20)
        : AppColors.expense.withValues(alpha: 0.20);
    final borderTint = isIncome
        ? AppColors.income.withValues(alpha: 0.35)
        : AppColors.expense.withValues(alpha: 0.35);

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgTint,
            border: Border.all(color: borderTint, width: 1.0),
          ),
          child: Icon(icon, size: 16, color: accentColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.freshSage,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              blurred
                  ? ClipRect(child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: valueWidget))
                  : valueWidget,
            ],
          ),
        ),
      ],
    );
  }
}

class _UpdateBannerCard extends StatelessWidget {
  const _UpdateBannerCard({
    required this.info,
    required this.onDismiss,
    required this.onUpdate,
  });

  final AppUpdateInfo info;
  final VoidCallback onDismiss;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.heroBackground,
            const Color(0xFF2C5A47),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepForest.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onUpdate,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.tr('Update Available (v{version})!', {
                                'version': info.latestVersion,
                              }),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: onDismiss,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr(
                            'A new version of Wall o\' Pay is ready with performance improvements and updates.'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'v${info.currentVersion} ➔ v${info.latestVersion}',
                            style: TextStyle(
                              color: context.themeColors.income,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  context.tr('Update Now'),
                                  style: TextStyle(
                                    color: colors.heroBackground,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: colors.heroBackground,
                                  size: 13,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

