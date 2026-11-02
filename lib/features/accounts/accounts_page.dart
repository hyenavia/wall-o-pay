import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_database.dart';
import '../../data/providers.dart';
import '../../data/tables.dart' show TxType;

IconData accountIcon(String type) {
  switch (type.toLowerCase()) {
    case 'cash':
      return Icons.payments_outlined;
    case 'bank':
      return Icons.account_balance_outlined;
    case 'digital':
      return Icons.devices_other_outlined;
    case 'ewallet':
      return Icons.account_balance_wallet_outlined;
    default:
      return Icons.account_balance_wallet_outlined;
  }
}

String accountKindLabel(BuildContext context, String type) {
  switch (type.toLowerCase()) {
    case 'cash':
      return context.tr('Cash');
    case 'bank':
      return context.tr('Commercial Bank');
    case 'digital':
      return context.tr('Digital Bank');
    case 'ewallet':
      return context.tr('E-Wallet');
    default:
      return context.tr('Commercial Bank');
  }
}

/// Ringkasan akun di Home: total saldo dan beberapa akun teratas.
class AccountsSummaryCard extends ConsumerWidget {
  const AccountsSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final accounts = ref.watch(walletsProvider).maybeWhen(
          data: (l) => l,
          orElse: () => const <Wallet>[],
        );
    final balances = ref.watch(walletBalancesProvider);
    final total = ref.watch(totalCurrentBalanceProvider);
    final hide = ref.watch(hideBalanceProvider);

    if (accounts.isEmpty) return const SizedBox.shrink();

    String money(int val) => hide ? 'Rp ••••••' : rupiah(val);

    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const AccountsPage()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryBadge(
                icon: Icons.account_balance_wallet_outlined,
                color: theme.colorScheme.primary,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Wallets & Accounts'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('{count} active accounts • {total}', {
                        'count': accounts.length,
                        'total': money(total),
                      }),
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          if (accounts.length > 1) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in accounts.take(4))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(a.colorValue).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${context.tr(a.name)}: ${money(balances[a.id] ?? 0)}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountCategoryHeader extends StatelessWidget {
  const _AccountCategoryHeader({
    required this.title,
    required this.icon,
    required this.count,
    required this.subtotalFormatted,
  });

  final String title;
  final IconData icon;
  final int count;
  final String subtotalFormatted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);

    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.sage.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.sage),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.sage.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.sage,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Spacer(),
          Text(
            subtotalFormatted,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}

class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final accountsAsync = ref.watch(walletsProvider);
    final balances = ref.watch(walletBalancesProvider);
    final walletMap = ref.watch(walletMapProvider);
    final total = ref.watch(totalCurrentBalanceProvider);
    final hide = ref.watch(hideBalanceProvider);

    final transfersAsync = ref.watch(transactionsProvider);
    final transfers = transfersAsync.maybeWhen(
      data: (list) => list.where((t) => t.type == TxType.transfer).toList(),
      orElse: () => const <TransactionEntry>[],
    );

    String money(int val) => hide ? 'Rp ••••••' : rupiah(val);

    return Scaffold(
      appBar: pageAppBar(
        context,
        title: Text(context.tr('Accounts')),
        actions: [
          IconButton(
            tooltip: context.tr('Transfer'),
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => showTransferSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAccountForm(context),
        icon: const Icon(Icons.add),
        label: Text(context.tr('Add account')),
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(context.tr('Could not load data: {error}', {'error': e})),
        ),
        data: (accounts) {
          const categoryOrder = ['bank', 'digital', 'ewallet', 'cash'];
          final grouped = <String, List<Wallet>>{
            for (final cat in categoryOrder) cat: <Wallet>[],
          };
          for (final a in accounts) {
            final type = a.type.toLowerCase();
            if (grouped.containsKey(type)) {
              grouped[type]!.add(a);
            } else {
              grouped['bank']!.add(a);
            }
          }

          // Urutkan akun di dalam tiap kategori berdasarkan saldo terbesar
          for (final list in grouped.values) {
            list.sort((a, b) {
              final balA = balances[a.id] ?? 0;
              final balB = balances[b.id] ?? 0;
              final cmp = balB.compareTo(balA);
              if (cmp != 0) return cmp;
              return a.name.compareTo(b.name);
            });
          }

          final activeCategories =
              categoryOrder.where((cat) => grouped[cat]!.isNotEmpty).toList();

          return FadedScrollBody(
            child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
            children: [
              HeroCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(context.tr('Total Balance'),
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                        const Spacer(),
                        IconButton(
                          tooltip: context.tr(hide ? 'Show amounts' : 'Hide amounts'),
                          visualDensity: VisualDensity.compact,
                          color: Colors.white70,
                          icon: Icon(hide ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => ref.read(hideBalanceProvider.notifier).toggle(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      money(total),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('Across all your accounts'),
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (activeCategories.isEmpty) ...[
                const SizedBox(height: 24),
                EmptyStateCard(
                  icon: Icons.account_balance_wallet_outlined,
                  title: context.tr('No accounts yet'),
                  subtitle: context.tr('Cash, bank, and e-wallet balances'),
                ),
              ],
              for (final cat in activeCategories) ...[
                _AccountCategoryHeader(
                  title: accountKindLabel(context, cat),
                  icon: accountIcon(cat),
                  count: grouped[cat]!.length,
                  subtotalFormatted: money(
                    grouped[cat]!.fold<int>(0, (sum, a) => sum + (balances[a.id] ?? 0)),
                  ),
                ),
                for (final a in grouped[cat]!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      onTap: () => showAccountForm(context, wallet: a),
                      child: Row(
                        children: [
                          CategoryBadge(
                            icon: accountIcon(a.type),
                            color: Color(a.colorValue),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr(a.name),
                                  style: theme.textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  accountKindLabel(context, a.type),
                                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            money(balances[a.id] ?? 0),
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              if (transfers.isNotEmpty) ...[
                SectionHeader(title: context.tr('Recent transfers')),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final t in transfers.take(10))
                        ListTile(
                          leading: const Icon(Icons.swap_horiz),
                          title: Text(
                            '${context.tr(walletMap[t.walletId]?.name ?? 'Wallet')}'
                            ' → ${context.tr(walletMap[t.toWalletId]?.name ?? 'Wallet')}',
                          ),
                          subtitle: Text(
                            t.note.isEmpty ? shortDate(t.date) : '${shortDate(t.date)} • ${t.note}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(money(t.amount),
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                              IconButton(
                                tooltip: context.tr('Delete'),
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => _confirmDeleteTransfer(context, ref, t.id),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteTransfer(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('Delete this transfer?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('Delete')),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(databaseProvider).deleteTransaction(id);
  }
}

// ---------------------------------------------------------------------------
// Form akun / dompet
// ---------------------------------------------------------------------------

Future<void> showAccountForm(BuildContext context, {Wallet? wallet}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => AccountForm(wallet: wallet),
  );
}

class AccountForm extends ConsumerStatefulWidget {
  const AccountForm({super.key, this.wallet});

  final Wallet? wallet;

  @override
  ConsumerState<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends ConsumerState<AccountForm> {
  late final TextEditingController _name;
  late final TextEditingController _balance;
  late String _type;
  late int _color;
  String? _error;

  static const _types = ['bank', 'digital', 'ewallet', 'cash'];

  @override
  void initState() {
    super.initState();
    final w = widget.wallet;
    _name = TextEditingController(text: w == null ? '' : w.name);
    final currentBal = w != null
        ? (ref.read(walletBalancesProvider)[w.id] ?? w.initialBalance)
        : 0;
    _balance = TextEditingController(
      text: currentBal > 0 ? formatThousands(currentBal) : (w == null ? '' : '0'),
    );
    _type = w?.type ?? 'bank';
    _color = w?.colorValue ?? categoryColors[1];
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = context.tr('Account name cannot be empty.'));
      return;
    }
    final db = ref.read(databaseProvider);
    final balance = parseAmount(_balance.text);
    final w = widget.wallet;
    if (w == null) {
      await db.addWallet(
        name: name,
        type: _type,
        colorValue: _color,
        initialBalance: balance,
        icon: _type == 'cash'
            ? 'payments'
            : _type == 'ewallet'
                ? 'account_balance_wallet'
                : 'account_balance',
      );
    } else {
      final currentBal = ref.read(walletBalancesProvider)[w.id] ?? w.initialBalance;
      final netTx = currentBal - w.initialBalance;
      final newInitial = balance - netTx;
      await db.updateWallet(
        w.id,
        name: name,
        type: _type,
        colorValue: _color,
        initialBalance: newInitial,
        icon: w.icon,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _archive() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('Archive this account?')),
        content: Text(context.tr(
          'Its past transactions are kept, but the account will no longer count toward your total balance.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('Archive')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(databaseProvider).deleteWallet(widget.wallet!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.wallet != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr(isEdit ? 'Edit account' : 'Add account'),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: appInput(context, label: context.tr('Account name')),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  for (final t in _types)
                    ButtonSegment(
                      value: t,
                      icon: Icon(accountIcon(t), size: 18),
                      label: Text(accountKindLabel(context, t)),
                    ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _balance,
              keyboardType: TextInputType.number,
              inputFormatters: amountFormatters(),
              decoration: appInput(
                context,
                label: context.tr('Balance'),
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in categoryColors)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: _color == c
                            ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                            : null,
                      ),
                      child: _color == c
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.expense)),
            ],
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: Text(context.tr('Save'))),
            if (isEdit)
              TextButton.icon(
                onPressed: _archive,
                icon: const Icon(Icons.archive_outlined),
                label: Text(context.tr('Archive account')),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transfer antar akun
// ---------------------------------------------------------------------------

Future<void> showTransferSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const TransferSheet(),
  );
}

class TransferSheet extends ConsumerStatefulWidget {
  const TransferSheet({super.key});

  @override
  ConsumerState<TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends ConsumerState<TransferSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _from;
  String? _to;
  DateTime _date = DateTime.now();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = parseAmount(_amount.text);
    if (_from == null || _to == null) {
      setState(() => _error = context.tr('Choose both accounts.'));
      return;
    }
    if (_from == _to) {
      setState(() => _error = context.tr('Choose two different accounts.'));
      return;
    }
    if (amount <= 0) {
      setState(() => _error = context.tr('Amount must be greater than 0.'));
      return;
    }
    await ref.read(databaseProvider).transferBetweenWallets(
          fromWalletId: _from!,
          toWalletId: _to!,
          amount: amount,
          date: DateTime(_date.year, _date.month, _date.day),
          note: _note.text.trim(),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accounts = ref.watch(walletsProvider).maybeWhen(
          data: (l) => l,
          orElse: () => const <Wallet>[],
        );
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    Widget picker(String label, String? value, ValueChanged<String> onPick) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: value,
            decoration: appInput(context),
            items: [
              for (final a in accounts)
                DropdownMenuItem(
                  value: a.id,
                  child: Row(
                    children: [
                      Icon(accountIcon(a.type), size: 18, color: Color(a.colorValue)),
                      const SizedBox(width: 8),
                      Text(context.tr(a.name)),
                    ],
                  ),
                ),
            ],
            onChanged: (v) {
              if (v != null) onPick(v);
            },
          ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('Transfer Between Accounts'),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            picker(context.tr('From'), _from, (v) => setState(() => _from = v)),
            const SizedBox(height: 12),
            picker(context.tr('To'), _to, (v) => setState(() => _to = v)),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: amountFormatters(),
              decoration: appInput(context, label: context.tr('Amount'), prefixText: 'Rp '),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(shortDate(_date)),
              trailing: TextButton(
                onPressed: _pickDate,
                child: Text(context.tr('Change')),
              ),
            ),
            TextField(
              controller: _note,
              decoration: appInput(context, label: context.tr('Note (optional)')),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.expense)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              child: Text(context.tr('Transfer')),
            ),
          ],
        ),
      ),
    );
  }
}
