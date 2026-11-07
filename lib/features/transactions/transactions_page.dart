/// Halaman daftar riwayat transaksi ([TransactionsPage]) yang dilengkapi fitur pencarian SQL langsung,
/// filter tipe transaksi, filter dompet/rekening, filter kategori, dan filter rentang tanggal kustom.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/period.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_database.dart';
import '../../data/feature_providers.dart';
import '../../data/providers.dart';
import '../../data/tables.dart' show TxType;
import 'transaction_form.dart';
import 'transaction_tile.dart';

/// Widget halaman tab Transaksi (Transactions) pada navigasi utama.
class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  String _query = '';
  Timer? _searchDebounce;
  TxType? _filter;
  DateTimeRange? _range;
  String? _selectedWalletId;
  String? _selectedCategoryId;
  bool _showCalendar = false;
  DateTime? _selectedDay;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      final next = value.trim().toLowerCase();
      if (_query != next) {
        setState(() => _query = next);
      }
    });
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _query.isNotEmpty;
    final txAsync = (isSearching
            ? ref.watch(searchTransactionsProvider(
                TxSearchParams(query: _query, type: _filter, range: _range),
              ))
            : (_range == null
                ? ref.watch(transactionsProvider)
                : ref.watch(rangeTransactionsProvider(_range!))))
        .unwrapPrevious();
    final cats = ref.watch(categoryMapProvider);
    final wallets = ref.watch(walletMapProvider);
    final period = ref.watch(selectedPeriodProvider);
    final colors = context.themeColors;

    return Scaffold(
      appBar: pageAppBar(
        context,
        title: Text(context.tr('Transactions')),
        actions: [
          IconButton(
            tooltip: context.tr('Cashflow Calendar'),
            icon: Icon(
              Icons.calendar_month_rounded,
              color: (_showCalendar || _selectedDay != null) ? colors.primary : null,
            ),
            onPressed: () => setState(() {
              _showCalendar = !_showCalendar;
              if (!_showCalendar) _selectedDay = null;
            }),
          ),
          IconButton(
            tooltip: context.tr('Filter by date range'),
            icon: Icon(
              Icons.date_range,
              color: _range == null ? null : colors.primary,
            ),
            onPressed: _pickRange,
          ),
        ],
        bottom: Center(
          child: _range == null
              ? const PeriodSwitcher(onDark: true)
              : InputChip(
                  avatar: const Icon(Icons.date_range, size: 18, color: Colors.white),
                  label: Text(
                    '${shortDate(_range!.start)} - ${shortDate(_range!.end)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  deleteIconColor: Colors.white70,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                  onDeleted: () => setState(() => _range = null),
                ),
        ),
        bottomHeight: 44,
      ),
      body: BotanicalBackgroundSheet(
        child: txAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(context.tr('Could not load data: {error}', {'error': e})),
          ),
          data: (txs) {
            final shown = txs.where((t) {
              if (!isSearching && _filter != null && t.type != _filter) return false;
              if (_selectedWalletId != null &&
                  t.walletId != _selectedWalletId &&
                  t.toWalletId != _selectedWalletId) {
                return false;
              }
              if (_selectedCategoryId != null && t.categoryId != _selectedCategoryId) {
                return false;
              }
              if (_selectedDay != null &&
                  (t.date.year != _selectedDay!.year ||
                      t.date.month != _selectedDay!.month ||
                      t.date.day != _selectedDay!.day)) {
                return false;
              }
              return true;
            }).toList();

            final totalIncome = shown
                .where((t) => t.type == TxType.income)
                .fold<int>(0, (a, t) => a + t.amount);
            final totalExpense = shown
                .where((t) => t.type == TxType.expense)
                .fold<int>(0, (a, t) => a + t.amount);

            // Kelompokkan per hari (urutan sudah dari terbaru).
            final groups = <DateTime, List<TransactionEntry>>{};
            for (final t in shown) {
              final day = DateTime(t.date.year, t.date.month, t.date.day);
              groups.putIfAbsent(day, () => []).add(t);
            }
            final groupEntries = groups.entries.toList(growable: false);

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          onChanged: _onSearchChanged,
                          decoration: appInput(
                            context,
                            hint: context.tr('Search transaction...'),
                            prefixIcon: const Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final f in <(String, TxType?)>[
                                (context.tr('All'), null),
                                (context.tr('Expense'), TxType.expense),
                                (context.tr('Income'), TxType.income),
                                (context.tr('Transfer'), TxType.transfer),
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: AppChip(
                                    label: f.$1,
                                    selected: _filter == f.$2,
                                    onSelected: () => setState(() => _filter = f.$2),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // Account filter button
                              PopupMenuButton<String?>(
                                tooltip: context.tr('Filter by account'),
                                onSelected: (val) => setState(() => _selectedWalletId = val),
                                itemBuilder: (context) => [
                                  PopupMenuItem<String?>(
                                    value: null,
                                    child: Text(context.tr('All Accounts')),
                                  ),
                                  for (final w in wallets.values)
                                    PopupMenuItem<String?>(
                                      value: w.id,
                                      child: Row(
                                        children: [
                                          if (w.id == _selectedWalletId)
                                            Icon(Icons.check, size: 16, color: context.themeColors.income)
                                          else
                                            const SizedBox(width: 16),
                                          const SizedBox(width: 8),
                                          Text(context.tr(w.name)),
                                        ],
                                      ),
                                    ),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _selectedWalletId != null
                                        ? colors.primary.withValues(alpha: 0.18)
                                        : Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _selectedWalletId != null
                                          ? colors.primary
                                          : Theme.of(context).colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet_outlined,
                                        size: 15,
                                        color: _selectedWalletId != null
                                            ? colors.primary
                                            : Theme.of(context).colorScheme.onSurface,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _selectedWalletId == null
                                            ? context.tr('All Accounts')
                                            : (wallets[_selectedWalletId] != null
                                                ? context.tr(wallets[_selectedWalletId]!.name)
                                                : context.tr('All Accounts')),
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: _selectedWalletId != null
                                              ? colors.primary
                                              : Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        size: 16,
                                        color: _selectedWalletId != null
                                            ? colors.primary
                                            : Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Category filter button
                              PopupMenuButton<String?>(
                                tooltip: context.tr('Filter by category'),
                                onSelected: (val) => setState(() => _selectedCategoryId = val),
                                itemBuilder: (context) => [
                                  PopupMenuItem<String?>(
                                    value: null,
                                    child: Text(context.tr('All Categories')),
                                  ),
                                  for (final c in cats.values)
                                    PopupMenuItem<String?>(
                                      value: c.id,
                                      child: Row(
                                        children: [
                                          if (c.id == _selectedCategoryId)
                                            Icon(Icons.check, size: 16, color: colors.income)
                                          else
                                            const SizedBox(width: 16),
                                          const SizedBox(width: 8),
                                          Text(context.tr(c.name)),
                                        ],
                                      ),
                                    ),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _selectedCategoryId != null
                                        ? colors.primary.withValues(alpha: 0.18)
                                        : Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _selectedCategoryId != null
                                          ? colors.primary
                                          : Theme.of(context).colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.category_outlined,
                                        size: 15,
                                        color: _selectedCategoryId != null
                                            ? colors.primary
                                            : Theme.of(context).colorScheme.onSurface,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _selectedCategoryId == null
                                            ? context.tr('All Categories')
                                            : (cats[_selectedCategoryId] != null
                                                ? context.tr(cats[_selectedCategoryId]!.name)
                                                : context.tr('All Categories')),
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: _selectedCategoryId != null
                                              ? colors.primary
                                              : Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        size: 16,
                                        color: _selectedCategoryId != null
                                            ? colors.primary
                                            : Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_selectedWalletId != null ||
                                  _selectedCategoryId != null ||
                                  _selectedDay != null) ...[
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => setState(() {
                                    _selectedWalletId = null;
                                    _selectedCategoryId = null;
                                    _selectedDay = null;
                                  }),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.close, size: 15, color: context.themeColors.expense),
                                        const SizedBox(width: 4),
                                        Text(
                                          context.tr('Clear filters'),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.themeColors.expense,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (_showCalendar) ...[
                          const SizedBox(height: 12),
                          _CashflowCalendarCard(
                            period: period,
                            txs: txs,
                            selectedDay: _selectedDay,
                            onSelectDay: (day) => setState(() {
                              if (_selectedDay != null &&
                                  day != null &&
                                  _selectedDay!.year == day.year &&
                                  _selectedDay!.month == day.month &&
                                  _selectedDay!.day == day.day) {
                                _selectedDay = null;
                              } else {
                                _selectedDay = day;
                              }
                            }),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryTile(
                                label: context.tr('Total Income'),
                                value: rupiah(totalIncome),
                                color: context.themeColors.income,
                                icon: Icons.arrow_downward,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SummaryTile(
                                label: context.tr('Total Expense'),
                                value: rupiah(totalExpense),
                                color: context.themeColors.expense,
                                icon: Icons.arrow_upward,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (txs.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                    sliver: SliverToBoxAdapter(
                      child: isSearching
                          ? EmptyState(
                              icon: Icons.search_off,
                              message: context.tr('No matching transactions.'),
                            )
                          : EmptyStateCard(
                              title: context.tr('Start recording your first transaction!'),
                              subtitle: context.tr(
                                'Every small transaction brings you closer to your financial goals.',
                              ),
                              actionLabel: context.tr('Add transaction'),
                              onAction: () => showTransactionForm(context),
                            ),
                    ),
                  )
                else if (shown.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 96),
                    sliver: SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.search_off,
                        message: context.tr('No matching transactions.'),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                    sliver: SliverList.builder(
                      itemCount: groupEntries.length,
                      itemBuilder: (context, index) {
                        final entry = groupEntries[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 18, bottom: 8),
                              child: Text(
                                dayHeader(entry.key),
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.65),
                                    ),
                              ),
                            ),
                            TransactionGroupCard(
                              children: [
                                for (final t in entry.value)
                                  TransactionTile(
                                    entry: t,
                                    category: cats[t.categoryId],
                                    wallet: t.walletId != null ? wallets[t.walletId!] : null,
                                    toWallet: t.toWalletId != null ? wallets[t.toWalletId!] : null,
                                    trailingNote: timeLabel(t.createdAt),
                                    onTap: () => showTransactionForm(context, entry: t),
                                  ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            );
        },
      ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CategoryBadge(icon: icon, color: color, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu kalender arus kas interaktif yang hanya di-render saat diaktifkan pengguna (on-demand).
class _CashflowCalendarCard extends StatelessWidget {
  const _CashflowCalendarCard({
    required this.period,
    required this.txs,
    required this.selectedDay,
    required this.onSelectDay,
  });

  final Period period;
  final List<TransactionEntry> txs;
  final DateTime? selectedDay;
  final ValueChanged<DateTime?> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.themeColors;
    final isId = AppLocale.code == 'id';
    final weekdays = isId
        ? const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
        : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Petakan total pemasukan & pengeluaran per tanggal di periode aktif
    final dailyIncome = <DateTime, int>{};
    final dailyExpense = <DateTime, int>{};
    for (final t in txs) {
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      if (t.type == TxType.income) {
        dailyIncome[d] = (dailyIncome[d] ?? 0) + t.amount;
      } else if (t.type == TxType.expense) {
        dailyExpense[d] = (dailyExpense[d] ?? 0) + t.amount;
      }
    }

    // Daftar seluruh hari dalam periode
    final days = <DateTime>[];
    var cursor = DateTime(period.start.year, period.start.month, period.start.day);
    final end = DateTime(period.end.year, period.end.month, period.end.day);
    while (cursor.isBefore(end)) {
      days.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }

    final leadingEmpty = days.isEmpty ? 0 : (days.first.weekday - 1);
    final totalCells = leadingEmpty + days.length;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 16, color: colors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.tr('Cashflow Calendar'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (selectedDay != null)
                InkWell(
                  onTap: () => onSelectDay(null),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      shortDate(selectedDay!),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  context.tr('Tap a date to filter'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: colors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final w in weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, idx) {
              if (idx < leadingEmpty) {
                return const SizedBox.shrink();
              }
              final date = days[idx - leadingEmpty];
              final inc = dailyIncome[date] ?? 0;
              final exp = dailyExpense[date] ?? 0;
              final isSelected = selectedDay != null &&
                  selectedDay!.year == date.year &&
                  selectedDay!.month == date.month &&
                  selectedDay!.day == date.day;
              final isToday = date == today;

              return InkWell(
                onTap: () => onSelectDay(date),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primary.withValues(alpha: 0.22)
                        : (inc > 0 || exp > 0)
                            ? colors.surfaceContainer.withValues(alpha: 0.55)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: colors.primary, width: 1.4)
                        : isToday
                            ? Border.all(
                                color: colors.primary.withValues(alpha: 0.45),
                                width: 1,
                              )
                            : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? colors.primary
                              : colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (inc > 0)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: colors.income,
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (exp > 0)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: colors.expense,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
