import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/brand.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/period.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/module_prefs.dart';
import '../../data/prefs.dart';
import '../../data/providers.dart';
import '../../data/recurring_service.dart';
import '../../data/tables.dart' show RecurFrequency, TxType;

/// Pengenalan awal: periode, modul pilihan, saldo awal, uang saku, dan anggaran pertama.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  static const _lastStep = 4;

  int _step = 0;
  bool _moduleGoals = true;
  bool _moduleDebts = true;
  bool _moduleRecurring = true;
  bool _moduleTransfer = true;
  bool _moduleBudget = true;

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

      // Simpan preferensi modul yang dipilih pengguna
      await ref.read(modulePrefsProvider.notifier).setAll(
            goals: _moduleGoals,
            debts: _moduleDebts,
            recurring: _moduleRecurring,
            transfer: _moduleTransfer,
            budget: _moduleBudget,
          );

      final cash = parseAmount(_cash.text);
      if (cash > 0) await db.updateWalletInitialBalance('wallet-cash', cash);

      final allowance = parseAmount(_allowance.text);
      if (_moduleRecurring && _hasAllowance && allowance > 0) {
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

      if (_moduleBudget) {
        final key = Period.containing(type, DateTime.now()).key;
        for (final e in {
          'cat-exp-food': parseAmount(_food.text),
          'cat-exp-transport': parseAmount(_transport.text),
          'cat-exp-fun': parseAmount(_fun.text),
        }.entries) {
          if (e.value > 0) await db.setBudget(e.key, key, e.value);
        }
      }
    } catch (e, st) {
      debugPrint('Error finishing onboarding: $e\n$st');
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

  Widget _moduleItem({
    required IconData icon,
    required String title,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.65);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? AppColors.sage.withValues(alpha: 0.5) : scheme.outlineVariant,
          width: value ? 1.4 : 1.0,
        ),
      ),
      child: CheckboxListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (value ? AppColors.sage : muted).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: value ? AppColors.sage : muted, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(desc, style: TextStyle(fontSize: 12, color: muted)),
        value: value,
        activeColor: AppColors.sage,
        checkColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onChanged: (v) => onChanged(v ?? false),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.65);
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
              context.tr('Choose your features'),
              context.tr('Pick the modules you want to use. You can change them anytime in Settings.'),
            ),
            Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.done_all_rounded, size: 16),
                  label: Text(context.tr('All Features')),
                  onPressed: () => setState(() {
                    _moduleGoals = true;
                    _moduleDebts = true;
                    _moduleRecurring = true;
                    _moduleTransfer = true;
                    _moduleBudget = true;
                  }),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.flash_on_rounded, size: 16),
                  label: Text(context.tr('Minimalist')),
                  onPressed: () => setState(() {
                    _moduleGoals = false;
                    _moduleDebts = false;
                    _moduleRecurring = false;
                    _moduleTransfer = false;
                    _moduleBudget = false;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _moduleItem(
              icon: Icons.flag_outlined,
              title: context.tr('Savings Goals'),
              desc: context.tr('Set targets for emergency funds, gadgets, or vacations.'),
              value: _moduleGoals,
              onChanged: (v) => setState(() => _moduleGoals = v),
            ),
            _moduleItem(
              icon: Icons.handshake_outlined,
              title: context.tr('Debts & Split Bills'),
              desc: context.tr('Track who owes whom and split group dining bills.'),
              value: _moduleDebts,
              onChanged: (v) => setState(() => _moduleDebts = v),
            ),
            _moduleItem(
              icon: Icons.event_repeat_rounded,
              title: context.tr('Recurring Schedules'),
              desc: context.tr('Automate allowance, subscriptions, and rent reminders.'),
              value: _moduleRecurring,
              onChanged: (v) => setState(() => _moduleRecurring = v),
            ),
            _moduleItem(
              icon: Icons.swap_horiz_rounded,
              title: context.tr('Account Transfers'),
              desc: context.tr('Move funds between cash, bank, and digital wallets.'),
              value: _moduleTransfer,
              onChanged: (v) => setState(() => _moduleTransfer = v),
            ),
            _moduleItem(
              icon: Icons.pie_chart_outline_rounded,
              title: context.tr('Category Budgets'),
              desc: context.tr('Set monthly or weekly spending limits per category.'),
              value: _moduleBudget,
              onChanged: (v) => setState(() => _moduleBudget = v),
            ),
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
      case 3:
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
