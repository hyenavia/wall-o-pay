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
import '../../data/tables.dart' show NeedWant, TxType;
import '../settings/report_dialog.dart';
import 'transaction_form.dart';
import 'transaction_tile.dart';

/// Widget halaman tab Transaksi (Transactions) pada navigasi utama.
class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  Timer? _searchDebounce;
  TxType? _filter;
  DateTimeRange? _range;
  String? _selectedWalletId;
  String? _selectedCategoryId;
  NeedWant? _needWant;
  bool _showCalendar = false;
  DateTime? _selectedDay;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasAnyFilter =>
      _query.isNotEmpty ||
      _filter != null ||
      _selectedWalletId != null ||
      _selectedCategoryId != null ||
      _needWant != null ||
      _selectedDay != null ||
      _range != null;

  void _clearAllFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _query = '';
      _filter = null;
      _selectedWalletId = null;
      _selectedCategoryId = null;
      _needWant = null;
      _selectedDay = null;
      _range = null;
    });
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
    final cats = ref.watch(categoryMapProvider);
    final wallets = ref.watch(walletMapProvider);
    final period = ref.watch(selectedPeriodProvider);

    final matchedCategoryIds = isSearching
        ? [
            for (final c in cats.values)
              if (c.name.toLowerCase().contains(_query) ||
                  context.tr(c.name).toLowerCase().contains(_query))
                c.id,
          ]
        : const <String>[];

    final txAsync = (isSearching
            ? ref.watch(searchTransactionsProvider(
                TxSearchParams(
                  query: _query,
                  type: _filter,
                  range: _range,
                  walletId: _selectedWalletId,
                  categoryId: _selectedCategoryId,
                  needWant: _needWant,
                  matchedCategoryIds: matchedCategoryIds,
                ),
              ))
            : (_range == null
                ? ref.watch(transactionsProvider)
                : ref.watch(rangeTransactionsProvider(_range!))))
        .unwrapPrevious();

    return Scaffold(
      appBar: pageAppBar(
        context,
        title: Text(context.tr('Transactions')),
        actions: [
          IconButton(
            tooltip: context.tr('Cashflow Calendar'),
            icon: Icon(
              Icons.calendar_month_rounded,
              color: (_showCalendar || _selectedDay != null) ? AppColors.dewMint : Colors.white,
            ),
            onPressed: () => setState(() {
              _showCalendar = !_showCalendar;
              if (!_showCalendar) _selectedDay = null;
            }),
          ),
          IconButton(
            tooltip: context.tr('Filter by date range'),
            icon: Icon(
              Icons.date_range_rounded,
              color: _range == null ? Colors.white : AppColors.dewMint,
            ),
            onPressed: _pickRange,
          ),
          PopupMenuButton<String>(
            tooltip: context.tr('Export'),
            icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
            onSelected: (choice) {
              if (choice == 'pdf') {
                showReportDialog(context);
              } else if (choice == 'csv') {
                showCsvExportDialog(context, ref);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                value: 'pdf',
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.dewMint),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ctx.tr('Export PDF report'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'csv',
                child: Row(
                  children: [
                    const Icon(Icons.table_view_outlined, size: 18, color: AppColors.dewMint),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ctx.tr('Export transactions (CSV)'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: Center(
          child: _range != null
              ? InputChip(
                  avatar: const Icon(Icons.date_range_rounded, size: 18, color: AppColors.dewMint),
                  label: Text(
                    '${shortDate(_range!.start)} - ${shortDate(_range!.end)}',
                    style: const TextStyle(color: AppColors.dewMint, fontWeight: FontWeight.w700),
                  ),
                  deleteIconColor: AppColors.dewMint.withValues(alpha: 0.8),
                  backgroundColor: AppColors.emeraldLeaf.withValues(alpha: 0.35),
                  side: BorderSide(color: AppColors.dewMint.withValues(alpha: 0.40)),
                  onDeleted: () => setState(() => _range = null),
                )
              : isSearching
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldLeaf.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.dewMint.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history_rounded, size: 15, color: AppColors.dewMint),
                          const SizedBox(width: 6),
                          Text(
                            context.tr('Searching across all dates'),
                            style: const TextStyle(
                              color: AppColors.dewMint,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const PeriodSwitcher(onDark: true),
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
              if (_needWant != null && t.needWant != _needWant) {
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
            final netFlow = totalIncome - totalExpense;

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
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: appInput(
                            context,
                            hint: context.tr('Search transaction...'),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.freshSage),
                            suffixIcon: (_query.isNotEmpty || _searchController.text.isNotEmpty)
                                ? IconButton(
                                    tooltip: context.tr('Clear search'),
                                    icon: const Icon(Icons.close_rounded, color: AppColors.freshSage, size: 18),
                                    onPressed: () {
                                      _searchDebounce?.cancel();
                                      _searchController.clear();
                                      setState(() => _query = '');
                                    },
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final f in <(String, TxType?, IconData)>[
                                (context.tr('All'), null, Icons.tune_rounded),
                                (context.tr('Expense'), TxType.expense, Icons.arrow_upward_rounded),
                                (context.tr('Income'), TxType.income, Icons.arrow_downward_rounded),
                                (context.tr('Transfer'), TxType.transfer, Icons.swap_horiz_rounded),
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: AppChip(
                                    label: f.$1,
                                    icon: f.$3,
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
                                            const Icon(Icons.check, size: 16, color: AppColors.incomeOnDark)
                                          else
                                            const SizedBox(width: 16),
                                          const SizedBox(width: 8),
                                          Text(context.tr(w.name)),
                                        ],
                                      ),
                                    ),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: _selectedWalletId != null
                                        ? AppColors.emeraldLeaf.withValues(alpha: 0.35)
                                        : AppColors.cardSurface.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _selectedWalletId != null
                                          ? AppColors.dewMint
                                          : AppColors.dewMint.withValues(alpha: 0.22),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet_outlined,
                                        size: 15,
                                        color: _selectedWalletId != null
                                            ? AppColors.dewMint
                                            : AppColors.freshSage,
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
                                              ? AppColors.dewMint
                                              : AppColors.softIvory,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        size: 16,
                                        color: _selectedWalletId != null
                                            ? AppColors.dewMint
                                            : AppColors.freshSage,
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
                                            const Icon(Icons.check, size: 16, color: AppColors.incomeOnDark)
                                          else
                                            const SizedBox(width: 16),
                                          const SizedBox(width: 8),
                                          Text(context.tr(c.name)),
                                        ],
                                      ),
                                    ),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: _selectedCategoryId != null
                                        ? AppColors.emeraldLeaf.withValues(alpha: 0.35)
                                        : AppColors.cardSurface.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _selectedCategoryId != null
                                          ? AppColors.dewMint
                                          : AppColors.dewMint.withValues(alpha: 0.22),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.category_outlined,
                                        size: 15,
                                        color: _selectedCategoryId != null
                                            ? AppColors.dewMint
                                            : AppColors.freshSage,
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
                                              ? AppColors.dewMint
                                              : AppColors.softIvory,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        size: 16,
                                        color: _selectedCategoryId != null
                                            ? AppColors.dewMint
                                            : AppColors.freshSage,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Need / Want filter button
                              PopupMenuButton<NeedWant?>(
                                tooltip: context.tr('Filter by Need / Want'),
                                onSelected: (val) => setState(() => _needWant = val),
                                itemBuilder: (context) => [
                                  PopupMenuItem<NeedWant?>(
                                    value: null,
                                    child: Text(context.tr('All Needs & Wants')),
                                  ),
                                  PopupMenuItem<NeedWant?>(
                                    value: NeedWant.need,
                                    child: Row(
                                      children: [
                                        if (_needWant == NeedWant.need)
                                          const Icon(Icons.check, size: 16, color: AppColors.incomeOnDark)
                                        else
                                          const SizedBox(width: 16),
                                        const SizedBox(width: 8),
                                        Text(context.tr('Needs')),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<NeedWant?>(
                                    value: NeedWant.want,
                                    child: Row(
                                      children: [
                                        if (_needWant == NeedWant.want)
                                          const Icon(Icons.check, size: 16, color: AppColors.incomeOnDark)
                                        else
                                          const SizedBox(width: 16),
                                        const SizedBox(width: 8),
                                        Text(context.tr('Wants')),
                                      ],
                                    ),
                                  ),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: _needWant != null
                                        ? AppColors.emeraldLeaf.withValues(alpha: 0.35)
                                        : AppColors.cardSurface.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _needWant != null
                                          ? AppColors.dewMint
                                          : AppColors.dewMint.withValues(alpha: 0.22),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.balance_outlined,
                                        size: 15,
                                        color: _needWant != null
                                            ? AppColors.dewMint
                                            : AppColors.freshSage,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _needWant == null
                                            ? context.tr('Need / Want')
                                            : context.tr(_needWant == NeedWant.need ? 'Needs' : 'Wants'),
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: _needWant != null
                                              ? AppColors.dewMint
                                              : AppColors.softIvory,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        size: 16,
                                        color: _needWant != null
                                            ? AppColors.dewMint
                                            : AppColors.freshSage,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_hasAnyFilter) ...[
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: _clearAllFilters,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.expense.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.expenseOnDark.withValues(alpha: 0.35),
                                        width: 0.9,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.close_rounded, size: 14, color: AppColors.expenseOnDark),
                                        const SizedBox(width: 4),
                                        Text(
                                          context.tr('Clear filters'),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.expenseOnDark,
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
                                color: AppColors.incomeOnDark,
                                icon: Icons.arrow_downward_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SummaryTile(
                                label: context.tr('Total Expense'),
                                value: rupiah(totalExpense),
                                color: AppColors.expenseOnDark,
                                icon: Icons.arrow_upward_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.dewMint.withValues(alpha: 0.14),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 14,
                                color: AppColors.freshSage,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                shown.length == 1
                                    ? context.tr('1 transaction')
                                    : context.tr('{count} transactions', {'count': shown.length}),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.freshSage,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${context.tr('Net flow')}: ',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.freshSage,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${netFlow >= 0 ? '+' : '-'}${rupiah(netFlow.abs())}',
                                style: context.moneyStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: netFlow >= 0
                                      ? AppColors.incomeOnDark
                                      : AppColors.expenseOnDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (txs.isEmpty && !_hasAnyFilter)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                    sliver: SliverToBoxAdapter(
                      child: EmptyStateCard(
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
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                    sliver: SliverToBoxAdapter(
                      child: EmptyStateCard(
                        icon: Icons.search_off_rounded,
                        title: context.tr('No matching transactions.'),
                        subtitle: context.tr(
                          'Try adjusting your search keywords or active filters.',
                        ),
                        actionLabel: context.tr('Clear filters'),
                        onAction: _clearAllFilters,
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
                        final dayIncome = entry.value
                            .where((t) => t.type == TxType.income)
                            .fold<int>(0, (s, t) => s + t.amount);
                        final dayExpense = entry.value
                            .where((t) => t.type == TxType.expense)
                            .fold<int>(0, (s, t) => s + t.amount);
                        final hasDayNet = dayIncome > 0 || dayExpense > 0;
                        final netDay = dayIncome - dayExpense;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 20, bottom: 8),
                              child: Row(
                                children: [
                                  Text(
                                    dayHeader(entry.key),
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.softIvory.withValues(alpha: 0.85),
                                        ),
                                  ),
                                  const Spacer(),
                                  if (hasDayNet)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (netDay >= 0 ? AppColors.income : AppColors.expense)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: (netDay >= 0 ? AppColors.incomeOnDark : AppColors.expenseOnDark)
                                              .withValues(alpha: 0.35),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        '${netDay >= 0 ? '+' : '-'}${rupiah(netDay.abs())}',
                                        style: context.moneyStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: netDay >= 0 ? AppColors.incomeOnDark : AppColors.expenseOnDark,
                                        ),
                                      ),
                                    ),
                                ],
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
                                    onLongPress: () => showDuplicateTransactionForm(context, t),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 18),
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
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.freshSage.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.moneyStyle(
                    fontSize: 15.5,
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.emeraldLeaf.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.dewMint),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('Cashflow Calendar'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.softIvory,
                  ),
                ),
              ),
              if (selectedDay != null)
                InkWell(
                  onTap: () => onSelectDay(null),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldLeaf.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.dewMint.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          shortDate(selectedDay!),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dewMint,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.close_rounded, size: 12, color: AppColors.dewMint),
                      ],
                    ),
                  ),
                )
              else
                Text(
                  context.tr('Tap a date to filter'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: AppColors.freshSage.withValues(alpha: 0.7),
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
                        color: AppColors.freshSage.withValues(alpha: 0.75),
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
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.emeraldLeaf.withValues(alpha: 0.45)
                        : (inc > 0 || exp > 0)
                            ? AppColors.surfaceContainer.withValues(alpha: 0.65)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    border: isSelected
                        ? Border.all(color: AppColors.dewMint, width: 1.5)
                        : isToday
                            ? Border.all(
                                color: AppColors.freshSage.withValues(alpha: 0.6),
                                width: 1.2,
                              )
                            : (inc > 0 || exp > 0)
                                ? Border.all(
                                    color: AppColors.borderOutline.withValues(alpha: 0.45),
                                    width: 0.8,
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
                              ? AppColors.dewMint
                              : isToday
                                  ? AppColors.dewMint
                                  : (inc > 0 || exp > 0)
                                      ? AppColors.softIvory
                                      : AppColors.freshSage.withValues(alpha: 0.65),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (inc > 0)
                            Container(
                              width: 5.5,
                              height: 5.5,
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.incomeOnDark,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.incomeOnDark.withValues(alpha: 0.4),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          if (exp > 0)
                            Container(
                              width: 5.5,
                              height: 5.5,
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.expenseOnDark,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.expenseOnDark.withValues(alpha: 0.4),
                                    blurRadius: 3,
                                  ),
                                ],
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
