/// Halaman menu Fitur Lainnya ([MorePage]) yang menjadi pusat navigasi menuju seluruh modul aplikasi.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/module_prefs.dart';
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
class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modules = ref.watch(modulePrefsProvider);

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
            color: iconColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
            color: AppColors.softIvory,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.freshSage,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.dewMint),
        onTap: onTap,
      );
    }

    List<Widget> withDividers(List<Widget> tiles) {
      final result = <Widget>[];
      for (var i = 0; i < tiles.length; i++) {
        if (i > 0) result.add(const Divider(height: 1, indent: 68));
        result.add(tiles[i]);
      }
      return result;
    }

    void open(Widget page) => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => page),
        );

    final colors = context.themeColors;
    const primaryBadge = AppColors.sage;

    final moneyTiles = <Widget>[
      tile(
        Icons.account_balance_wallet_outlined,
        primaryBadge,
        context.tr('Accounts'),
        context.tr('Cash, bank, and e-wallet balances'),
        () => open(const AccountsPage()),
      ),
      if (modules.transfer)
        tile(
          Icons.swap_horiz_rounded,
          colors.income,
          context.tr('Transfer balance'),
          context.tr('Move money between accounts and wallets'),
          () => showTransactionForm(context, initialType: TxType.transfer),
        ),
      if (modules.debts)
        tile(
          Icons.handshake_outlined,
          colors.warning,
          context.tr('Debts & splits'),
          context.tr('Who owes whom, and splitting bills'),
          () => open(const DebtsPage()),
        ),
    ];

    final planningTiles = <Widget>[
      if (modules.budget)
        tile(
          Icons.pie_chart_outline_rounded,
          colors.income,
          context.tr('Budget'),
          context.tr('Set monthly or weekly spending limits per category.'),
          () => open(const BudgetPage()),
        ),
      if (modules.goals)
        tile(
          Icons.flag_outlined,
          primaryBadge,
          context.tr('Goals'),
          context.tr('Savings goals and progress'),
          () => open(const GoalsPage()),
        ),
      if (modules.recurring)
        tile(
          Icons.event_repeat,
          const Color(0xFF60A5FA),
          context.tr('Recurring'),
          context.tr('Allowance, rent, and other repeating items'),
          () => open(const RecurringPage()),
        ),
    ];

    final toolTiles = <Widget>[
      tile(
        Icons.category_outlined,
        const Color(0xFFA78BFA),
        context.tr('Categories'),
        context.tr('Expense and income categories'),
        () => open(const CategoriesPage()),
      ),
      tile(
        Icons.picture_as_pdf_outlined,
        colors.expense,
        context.tr('PDF report'),
        context.tr('Export a report for any period'),
        () => showReportDialog(context),
      ),
      tile(
        Icons.settings_outlined,
        Colors.white70,
        context.tr('Settings'),
        context.tr('Profile, language, security, and backup'),
        () => open(const SettingsPage()),
      ),
    ];

    return Scaffold(
      appBar: secondaryAppBar(context, title: Text(context.tr('More Features'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
        children: [
          SectionHeader(title: context.tr('Money & Wallets')),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: withDividers(moneyTiles)),
          ),
          if (planningTiles.isNotEmpty) ...[
            const SizedBox(height: 16),
            SectionHeader(title: context.tr('Planning & Goals')),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(children: withDividers(planningTiles)),
            ),
          ],
          const SizedBox(height: 16),
          SectionHeader(title: context.tr('Tools & Settings')),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: withDividers(toolTiles)),
          ),
        ],
      ),
    );
  }
}
