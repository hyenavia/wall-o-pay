import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';
import '../../data/tables.dart' show TxType;
import '../debts/debts_page.dart';
import '../recurring/recurring_page.dart';
import '../settings/report_dialog.dart';
import '../settings/settings_page.dart';
import '../transactions/transaction_form.dart';

/// Pusat fitur tambahan: utang & patungan, transaksi berulang, laporan PDF, dan pengaturan.
class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  Icons.swap_horiz_rounded,
                  context.tr('Transfer Saldo'),
                  context.tr('Pindahkan uang antar rekening dan kantong'),
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
                  Icons.insights_outlined,
                  context.tr('Insight'),
                  context.tr('Charts, needs vs wants, and trends'),
                  () {
                    ref.read(tabIndexProvider.notifier).set(3);
                    Navigator.pop(context);
                  },
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
