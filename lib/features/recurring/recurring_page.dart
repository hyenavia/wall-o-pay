import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';
import '../../data/recurring_service.dart';
import '../../data/tables.dart';

class RecurringPage extends ConsumerWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final rulesAsync = ref.watch(recurringRulesProvider);
    final cats = ref.watch(categoryMapProvider);
    final wallets = ref.watch(walletsProvider).value ?? [];
    final walletMap = {for (final w in wallets) w.id: w};

    return Scaffold(
      appBar: pageAppBar(context, title: Text(context.tr('Recurring & Subscriptions'))),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.tr('Error: {error}', {'error': e}))),
        data: (rules) {
          if (rules.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.repeat_rounded, size: 48, color: scheme.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('No recurring schedules yet.'),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr(
                        'Set up regular income, bills, or subscription schedules. They will prompt you for confirmation on their due date before recording.',
                      ),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.deepForest),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(context.tr('Add Schedule')),
                      onPressed: () => _showAddOrEditDialog(context, ref),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
            itemCount: rules.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final r = rules[i];
              final cat = cats[r.categoryId];
              final catColor = cat != null ? Color(cat.colorValue) : AppColors.sage;
              final wallet = r.walletId != null ? walletMap[r.walletId] : null;

              String freqText = switch (r.frequency) {
                RecurFrequency.daily => ctx.tr('Daily'),
                RecurFrequency.weekly => ctx.tr('Every {day}', {'day': _weekdayName(ctx, r.dayOfWeek ?? 1)}),
                RecurFrequency.monthly => ctx.tr('Every month on the {day}th', {'day': r.dayOfMonth ?? 1}),
              };

              return AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconFor(cat?.icon ?? 'more'), color: catColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  r.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    decoration: r.isActive ? null : TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                              Text(
                                '${r.type == TxType.income ? '+' : '-'}${rupiah(r.amount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: r.type == TxType.income ? AppColors.income : AppColors.expense,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                freqText,
                                style: theme.textTheme.bodySmall?.copyWith(color: muted, fontWeight: FontWeight.w500),
                              ),
                              if (wallet != null) ...[
                                Text(' • ', style: TextStyle(color: muted)),
                                Text(
                                  ctx.tr(wallet.name),
                                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ctx.tr('Next due: {date}', {'date': shortDate(r.nextDueDate)}),
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: r.isActive,
                      onChanged: (active) async {
                        await ref.read(databaseProvider).toggleRecurringRule(r.id, active);
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (val) async {
                        if (val == 'delete') {
                          await ref.read(databaseProvider).deleteRecurringRule(r.id);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline, color: AppColors.expense, size: 18),
                              const SizedBox(width: 8),
                              Text(context.tr('Delete'), style: const TextStyle(color: AppColors.expense)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.deepForest,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(context.tr('Add Schedule')),
        onPressed: () => _showAddOrEditDialog(context, ref),
      ),
    );
  }

  static String _weekdayName(BuildContext ctx, int day) {
    return switch (day) {
      1 => ctx.tr('Monday'),
      2 => ctx.tr('Tuesday'),
      3 => ctx.tr('Wednesday'),
      4 => ctx.tr('Thursday'),
      5 => ctx.tr('Friday'),
      6 => ctx.tr('Saturday'),
      7 => ctx.tr('Sunday'),
      _ => ctx.tr('Monday'),
    };
  }

  void _showAddOrEditDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => const _RecurringFormSheet(),
    );
  }
}

class _RecurringFormSheet extends ConsumerStatefulWidget {
  const _RecurringFormSheet();

  @override
  ConsumerState<_RecurringFormSheet> createState() => _RecurringFormSheetState();
}

class _RecurringFormSheetState extends ConsumerState<_RecurringFormSheet> {
  final _titleCtl = TextEditingController();
  final _amountCtl = TextEditingController();
  final _noteCtl = TextEditingController();

  TxType _type = TxType.expense;
  RecurFrequency _freq = RecurFrequency.weekly;
  int _dayOfWeek = DateTime.wednesday; // Default Rabu sesuai kiriman ortu
  int _dayOfMonth = 1;
  String? _categoryId;
  String? _walletId = 'wallet-main';

  @override
  void dispose() {
    _titleCtl.dispose();
    _amountCtl.dispose();
    _noteCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allCats = ref.watch(categoriesProvider).value ?? [];
    final cats = allCats.where((c) => c.type == _type).toList();
    final wallets = ref.watch(walletsProvider).value ?? [];

    if (_categoryId == null && cats.isNotEmpty) {
      _categoryId = cats.first.id;
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('New Recurring Schedule'),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            // Tipe
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<TxType>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: TxType.expense, label: Text(context.tr('Expense'))),
                  ButtonSegment(value: TxType.income, label: Text(context.tr('Income'))),
                ],
                selected: {_type},
                onSelectionChanged: (s) {
                  setState(() {
                    _type = s.first;
                    _categoryId = null;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtl,
              decoration: appInput(context, label: context.tr('Title (e.g. Kiriman Ortu, Kost, Netflix)')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtl,
              keyboardType: TextInputType.number,
              inputFormatters: amountFormatters(),
              decoration: appInput(context, label: context.tr('Amount'), prefixText: 'Rp '),
            ),
            const SizedBox(height: 14),
            // Frekuensi
            Text(context.tr('Frequency'), style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<RecurFrequency>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: RecurFrequency.weekly, label: Text(context.tr('Weekly'))),
                  ButtonSegment(value: RecurFrequency.monthly, label: Text(context.tr('Monthly'))),
                  ButtonSegment(value: RecurFrequency.daily, label: Text(context.tr('Daily'))),
                ],
                selected: {_freq},
                onSelectionChanged: (s) => setState(() => _freq = s.first),
              ),
            ),
            const SizedBox(height: 12),
            if (_freq == RecurFrequency.weekly) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.tr('Day of week'), style: theme.textTheme.bodyMedium),
                  DropdownButton<int>(
                    value: _dayOfWeek,
                    underline: const SizedBox(),
                    borderRadius: BorderRadius.circular(12),
                    items: [
                      DropdownMenuItem(value: DateTime.monday, child: Text(context.tr('Monday'))),
                      DropdownMenuItem(value: DateTime.tuesday, child: Text(context.tr('Tuesday'))),
                      DropdownMenuItem(value: DateTime.wednesday, child: Text(context.tr('Wednesday'))),
                      DropdownMenuItem(value: DateTime.thursday, child: Text(context.tr('Thursday'))),
                      DropdownMenuItem(value: DateTime.friday, child: Text(context.tr('Friday'))),
                      DropdownMenuItem(value: DateTime.saturday, child: Text(context.tr('Saturday'))),
                      DropdownMenuItem(value: DateTime.sunday, child: Text(context.tr('Sunday'))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _dayOfWeek = val);
                    },
                  ),
                ],
              ),
            ] else if (_freq == RecurFrequency.monthly) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.tr('Day of month'), style: theme.textTheme.bodyMedium),
                  DropdownButton<int>(
                    value: _dayOfMonth,
                    underline: const SizedBox(),
                    borderRadius: BorderRadius.circular(12),
                    items: [
                      for (int d = 1; d <= 31; d++)
                        DropdownMenuItem(value: d, child: Text(context.tr('Day {n}', {'n': d}))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _dayOfMonth = val);
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            // Wallet
            if (wallets.isNotEmpty) ...[
              Text(context.tr('Wallet / Account'), style: theme.textTheme.labelMedium),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _walletId,
                decoration: appInput(context),
                items: [
                  for (final w in wallets)
                    DropdownMenuItem(value: w.id, child: Text(context.tr(w.name))),
                ],
                onChanged: (val) => setState(() => _walletId = val),
              ),
              const SizedBox(height: 12),
            ],
            // Category
            if (cats.isNotEmpty) ...[
              Text(context.tr('Category'), style: theme.textTheme.labelMedium),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: appInput(context),
                items: [
                  for (final c in cats)
                    DropdownMenuItem(value: c.id, child: Text(context.tr(c.name))),
                ],
                onChanged: (val) => setState(() => _categoryId = val),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _noteCtl,
              decoration: appInput(context, label: context.tr('Note (optional)')),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.deepForest),
                onPressed: () async {
                  final title = _titleCtl.text.trim();
                  final amount = parseAmount(_amountCtl.text);
                  if (title.isEmpty || amount <= 0 || _categoryId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('Please fill in title and amount.'))),
                    );
                    return;
                  }

                  final now = DateTime.now();
                  final nextDue = RecurringService.calculateNextDueDate(
                    _freq,
                    now,
                    dayOfWeek: _dayOfWeek,
                    dayOfMonth: _dayOfMonth,
                  );

                  final db = ref.read(databaseProvider);
                  await db.addRecurringRule(
                    title: title,
                    amount: amount,
                    type: _type,
                    categoryId: _categoryId!,
                    walletId: _walletId,
                    frequency: _freq,
                    dayOfWeek: _dayOfWeek,
                    dayOfMonth: _dayOfMonth,
                    startDate: now,
                    nextDueDate: nextDue,
                    note: _noteCtl.text.trim(),
                  );

                  await RecurringService.checkAndGenerateDue(db);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('Recurring schedule created!'))),
                    );
                  }
                },
                child: Text(context.tr('Save Schedule')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
