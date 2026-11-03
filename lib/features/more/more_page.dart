import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/module_prefs.dart';
import '../../data/tables.dart' show TxType;
import '../accounts/accounts_page.dart';
import '../categories/categories_page.dart';
import '../debts/debts_page.dart';
import '../goals/goals_page.dart';
import '../recurring/recurring_page.dart';
import '../settings/module_sheet.dart';
import '../settings/report_dialog.dart';
import '../settings/settings_page.dart';
import '../transactions/transaction_form.dart';

/// Pusat fitur dan modul: kelola modul aktif, akun & dompet, impian & tabungan,
/// utang & patungan, transaksi berulang, laporan PDF, dan pengaturan.
class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modules = ref.watch(modulePrefsProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.65);

    Widget tile(IconData icon, String title, String subtitle, VoidCallback onTap) {
      return ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
    }

    void open(Widget page) => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => page),
        );

    return Scaffold(
      appBar: pageAppBar(context, title: Text(context.tr('More Features'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          // Banner Modul & Fitur Aktif
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.sage.withValues(alpha: 0.3)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.sage.withValues(alpha: 0.12),
                  scheme.surface,
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.sage.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.widgets_outlined, color: AppColors.sage, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('Active Modules & Features'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('{count} of {total} modules active', {
                          'count': modules.activeCount,
                          'total': 5,
                        }),
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => showModuleSelectionSheet(context),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    backgroundColor: AppColors.sage.withValues(alpha: 0.2),
                    foregroundColor: AppColors.sage,
                  ),
                  child: Text(
                    context.tr('Customize'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                tile(
                  Icons.account_balance_wallet_outlined,
                  context.tr('Accounts'),
                  context.tr('Cash, bank, and e-wallet balances'),
                  () => open(const AccountsPage()),
                ),
                tile(
                  Icons.flag_outlined,
                  context.tr('Goals'),
                  context.tr('Savings goals and progress'),
                  () => open(const GoalsPage()),
                ),
                tile(
                  Icons.swap_horiz_rounded,
                  context.tr('Transfer balance'),
                  context.tr('Move money between accounts and wallets'),
                  () => showTransactionForm(context, initialType: TxType.transfer),
                ),
                tile(
                  Icons.handshake_outlined,
                  context.tr('Debts & splits'),
                  context.tr('Who owes whom, and splitting bills'),
                  () => open(const DebtsPage()),
                ),
                tile(
                  Icons.event_repeat,
                  context.tr('Recurring'),
                  context.tr('Allowance, rent, and other repeating items'),
                  () => open(const RecurringPage()),
                ),
                tile(
                  Icons.category_outlined,
                  context.tr('Categories'),
                  context.tr('Expense and income categories'),
                  () => open(const CategoriesPage()),
                ),
                tile(
                  Icons.picture_as_pdf_outlined,
                  context.tr('PDF report'),
                  context.tr('Export a report for any period'),
                  () => showReportDialog(context),
                ),
                tile(
                  Icons.settings_outlined,
                  context.tr('Settings'),
                  context.tr('Profile, language, security, and backup'),
                  () => open(const SettingsPage()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
