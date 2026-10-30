import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/brand.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/period.dart';
import '../../core/widgets.dart';
import '../../data/prefs.dart';
import '../../data/providers.dart';
import '../../data/recurring_service.dart';
import '../../data/tables.dart' show RecurFrequency, TxType;

/// Pengenalan awal: periode, uang saku, saldo awal, dan anggaran pertama.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  static const _lastStep = 3;

  int _step = 0;
  bool _hasAllowance = true;
  int _dayOfWeek = DateTime.now().weekday;
  int _dayOfMonth = 1;
  bool _saving = false;

  final _allowance = TextEditingController();
  final _cash = TextEditingController();
  final _food = TextEditingController();
  final _transport = TextEditingController();
  final _fun = TextEditingController();

  @override
  void dispose() {
    _allowance.dispose();
    _cash.dispose();
    _food.dispose();
    _transport.dispose();
    _fun.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final db = ref.read(databaseProvider);
      final type = ref.read(appPrefsProvider).periodType;

      final cash = parseAmount(_cash.text);
      if (cash > 0) await db.updateWalletInitialBalance('wallet-cash', cash);

      final allowance = parseAmount(_allowance.text);
      if (_hasAllowance && allowance > 0) {
        final now = DateTime.now();
        await db.addRecurringRule(
          title: trG('Allowance'),
          type: TxType.income,
          amount: allowance,
          categoryId: 'cat-inc-parents',
          frequency: type == PeriodType.weekly
              ? RecurFrequency.weekly
              : RecurFrequency.monthly,
          dayOfWeek: _dayOfWeek,
          dayOfMonth: _dayOfMonth,
          walletId: 'wallet-cash',
          startDate: now,
          nextDueDate: now,
          note: trG('Allowance'),
        );
        await RecurringService.checkAndGenerateDue(db);
      }

      final key = Period.containing(type, DateTime.now()).key;
      for (final e in {
        'cat-exp-food': parseAmount(_food.text),
        'cat-exp-transport': parseAmount(_transport.text),
        'cat-exp-fun': parseAmount(_fun.text),
      }.entries) {
        if (e.value > 0) await db.setBudget(e.key, key, e.value);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    widget.onDone();
  }

  Widget _amountField(TextEditingController c, String label) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: amountFormatters(),
      decoration: appInput(context, label: label, prefixText: 'Rp '),
    );
  }

  Widget _body(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final type = ref.watch(appPrefsProvider.select((p) => p.periodType));
    final weekly = type == PeriodType.weekly;

    Widget heading(String title, String sub) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(sub, style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
            const SizedBox(height: 24),
          ],
        );

    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading(
              context.tr('How do you receive your money?'),
              context.tr('Pick how you plan your spending. You can change it later in Settings.'),
            ),
            const SizedBox(width: double.infinity, child: PeriodTypeToggle()),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading(
              context.tr('Your allowance'),
              context.tr('We will record it automatically so you do not have to.'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _hasAllowance,
              onChanged: (v) => setState(() => _hasAllowance = v),
              title: Text(context.tr('I receive a regular allowance')),
            ),
            if (_hasAllowance) ...[
              const SizedBox(height: 8),
              _amountField(_allowance, context.tr('Allowance amount')),
              const SizedBox(height: 16),
              Text(
                context.tr(weekly ? 'Which day of the week?' : 'Which day of the month?'),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              if (weekly)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var d = 1; d <= 7; d++)
                      AppChip(
                        label: DateFormat('EEE', AppLocale.code).format(DateTime(2024, 1, d)),
                        selected: _dayOfWeek == d,
                        onSelected: () => setState(() => _dayOfWeek = d),
                      ),
                  ],
                )
              else
                DropdownButton<int>(
                  value: _dayOfMonth,
                  items: [
                    for (var d = 1; d <= 30; d++)
                      DropdownMenuItem(value: d, child: Text('$d')),
                    DropdownMenuItem(value: 31, child: Text(context.tr('Last day'))),
                  ],
                  onChanged: (v) => setState(() => _dayOfMonth = v ?? 1),
                ),
            ],
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading(
              context.tr('Money you have now'),
              context.tr('Enter your current cash. You can add bank and e-wallet accounts later in More > Accounts.'),
            ),
            _amountField(_cash, context.tr('Cash on hand')),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading(
              context.tr(weekly ? 'Your first weekly budget' : 'Your first monthly budget'),
              context.tr('Set limits for the categories you spend on most. All optional.'),
            ),
            _amountField(_food, context.tr('Food & Drinks')),
            const SizedBox(height: 12),
            _amountField(_transport, context.tr('Transport')),
            const SizedBox(height: 12),
            _amountField(_fun, context.tr('Entertainment')),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = _step == _lastStep;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const BrandMark(size: 40),
                  const Spacer(),
                  TextButton(
                    onPressed: _saving ? null : widget.onDone,
                    child: Text(context.tr('Skip')),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AppProgressBar(value: (_step + 1) / (_lastStep + 1)),
              const SizedBox(height: 28),
              Expanded(child: SingleChildScrollView(child: _body(context))),
              Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: _saving ? null : () => setState(() => _step--),
                      child: Text(context.tr('Back')),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _saving
                        ? null
                        : () {
                            if (last) {
                              _finish();
                            } else {
                              setState(() => _step++);
                            }
                          },
                    style: FilledButton.styleFrom(minimumSize: const Size(140, 52)),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.tr(last ? 'Finish' : 'Next')),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('Step {n} of {total}', {'n': _step + 1, 'total': _lastStep + 1}),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
