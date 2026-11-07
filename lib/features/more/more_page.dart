/// Halaman menu Fitur Lainnya ([MorePage]) yang menjadi pusat navigasi menuju seluruh modul aplikasi.
library;

import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/tables.dart' show TxType;
import '../accounts/accounts_page.dart';
import '../budget/budget_page.dart';
import '../categories/categories_page.dart';
import '../debts/debts_page.dart';
import '../goals/goals_page.dart';
import '../recurring/recurring_page.dart';
import '../settings/report_dialog.dart';
import '../settings/settings_page.dart';
import '../transactions/transaction_form.dart';

/// Pusat fitur: akun & rekening, anggaran, impian & tabungan, transfer saldo,
/// utang & patungan, transaksi berulang, kategori, laporan PDF, dan pengaturan.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    Widget tile(
      IconData icon,
      Color iconColor,
      String title,
      String subtitle,
      VoidCallback onTap,
    ) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      );
    }

    void open(Widget page) => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => page),
        );

    final colors = context.themeColors;
    final isCyber = colors.isCyberpunk;
    final primaryBadge = isCyber ? colors.primary : AppColors.sage;

    return Scaffold(
      appBar: pageAppBar(context, title: Text(context.tr('More Features'))),
      body: BotanicalBackgroundSheet(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
          children: [
            SectionHeader(title: context.tr('Money & Wallets')),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  tile(
                    Icons.account_balance_wallet_outlined,
                    primaryBadge,
                    context.tr('Accounts'),
                    context.tr('Cash, bank, and e-wallet balances'),
                    () => open(const AccountsPage()),
                  ),
                  const Divider(height: 1, indent: 68),
                  tile(
                    Icons.swap_horiz_rounded,
                    colors.income,
                    context.tr('Transfer balance'),
                    context.tr('Move money between accounts and wallets'),
                    () => showTransactionForm(context, initialType: TxType.transfer),
                  ),
                  const Divider(height: 1, indent: 68),
                  tile(
                    Icons.handshake_outlined,
                    colors.warning,
                    context.tr('Debts & splits'),
                    context.tr('Who owes whom, and splitting bills'),
                    () => open(const DebtsPage()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionHeader(title: context.tr('Planning & Goals')),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  tile(
                    Icons.pie_chart_outline_rounded,
                    colors.income,
                    context.tr('Budget'),
                    context.tr('Set monthly or weekly spending limits per category.'),
                    () => open(const BudgetPage()),
                  ),
                  const Divider(height: 1, indent: 68),
                  tile(
                    Icons.flag_outlined,
                    primaryBadge,
                    context.tr('Goals'),
                    context.tr('Savings goals and progress'),
                    () => open(const GoalsPage()),
                  ),
                  const Divider(height: 1, indent: 68),
                  tile(
                    Icons.event_repeat,
                    const Color(0xFF60A5FA),
                    context.tr('Recurring'),
                    context.tr('Allowance, rent, and other repeating items'),
                    () => open(const RecurringPage()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionHeader(title: context.tr('Tools & Settings')),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  tile(
                    Icons.category_outlined,
                    const Color(0xFFA78BFA),
                    context.tr('Categories'),
                    context.tr('Expense and income categories'),
                    () => open(const CategoriesPage()),
                  ),
                  const Divider(height: 1, indent: 68),
                  tile(
                    Icons.picture_as_pdf_outlined,
                    colors.expense,
                    context.tr('PDF report'),
                    context.tr('Export a report for any period'),
                    () => showReportDialog(context),
                  ),
                  const Divider(height: 1, indent: 68),
                  tile(
                    Icons.settings_outlined,
                    Colors.white70,
                    context.tr('Settings'),
                    context.tr('Profile, language, security, and backup'),
                    () => open(const SettingsPage()),
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
