import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/widgets.dart';
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

/// Pusat fitur tambahan: akun & dompet, impian & tabungan, utang & patungan, transaksi berulang, laporan PDF, dan pengaturan.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
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
      appBar: pageAppBar(context, title: Text(context.tr('More'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                tile(
                  Icons.widgets_outlined,
                  context.tr('Active Modules & Features'),
                  context.tr('Customize which modules appear on your home screen and menus.'),
                  () => showModuleSelectionSheet(context),
                ),
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
