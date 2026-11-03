import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/module_prefs.dart';

void showModuleSelectionSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const _ModuleSelectionContent(),
  );
}

class _ModuleSelectionContent extends ConsumerWidget {
  const _ModuleSelectionContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modules = ref.watch(modulePrefsProvider);
    final ctl = ref.read(modulePrefsProvider.notifier);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.65);

    Widget moduleTile({
      required String key,
      required IconData icon,
      required String titleKey,
      required String descKey,
      required bool value,
      required ValueChanged<bool> onChanged,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? AppColors.sage.withValues(alpha: 0.5) : scheme.outlineVariant,
            width: value ? 1.4 : 1.0,
          ),
        ),
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (value ? AppColors.sage : muted).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: value ? AppColors.sage : muted, size: 22),
          ),
          title: Text(
            context.tr(titleKey),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          subtitle: Text(
            context.tr(descKey),
            style: TextStyle(fontSize: 12, color: muted, height: 1.3),
          ),
          value: value,
          activeThumbColor: AppColors.sage,
          onChanged: onChanged,
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('Active Modules & Features'),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('Customize which modules appear on your home screen and menus.'),
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  moduleTile(
                    key: 'goals',
                    icon: Icons.flag_outlined,
                    titleKey: 'Savings Goals',
                    descKey: 'Set targets for emergency funds, gadgets, or vacations.',
                    value: modules.goals,
                    onChanged: (v) => ctl.setModule('goals', v),
                  ),
                  moduleTile(
                    key: 'debts',
                    icon: Icons.handshake_outlined,
                    titleKey: 'Debts & Split Bills',
                    descKey: 'Track who owes whom and split group dining bills.',
                    value: modules.debts,
                    onChanged: (v) => ctl.setModule('debts', v),
                  ),
                  moduleTile(
                    key: 'recurring',
                    icon: Icons.event_repeat_rounded,
                    titleKey: 'Recurring Schedules',
                    descKey: 'Automate allowance, subscriptions, and rent reminders.',
                    value: modules.recurring,
                    onChanged: (v) => ctl.setModule('recurring', v),
                  ),
                  moduleTile(
                    key: 'transfer',
                    icon: Icons.swap_horiz_rounded,
                    titleKey: 'Account Transfers',
                    descKey: 'Move funds between cash, bank, and digital wallets.',
                    value: modules.transfer,
                    onChanged: (v) => ctl.setModule('transfer', v),
                  ),
                  moduleTile(
                    key: 'budget',
                    icon: Icons.pie_chart_outline_rounded,
                    titleKey: 'Category Budgets',
                    descKey: 'Set monthly or weekly spending limits per category.',
                    value: modules.budget,
                    onChanged: (v) => ctl.setModule('budget', v),
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
