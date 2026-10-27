import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/widgets.dart';
import '../../data/cloud.dart';
import '../../data/cloud_backup.dart';
import '../../data/export_service.dart';
import '../../data/prefs.dart';
import '../../data/profile.dart';
import '../../data/providers.dart';
import '../../data/auto_tracker.dart';
import '../categories/categories_page.dart';
import '../profile/profile_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final ready = ref.watch(firebaseReadyProvider);
    final user = ref.watch(currentUserProvider);
    final backup = ref.watch(cloudBackupProvider);
    final prefs = ref.watch(appPrefsProvider);
    final prefsCtl = ref.read(appPrefsProvider.notifier);
    final name = ref.watch(displayNameProvider);
    final username = ref.watch(usernameProvider);
    final canUseCloud = ready && user != null && !backup.working;

    final lastText = backup.lastBackup == null
        ? context.tr('No cloud backup yet.')
        : context.tr('Last backup {date}', {'date': dateTimeLabel(backup.lastBackup!)});

    return Scaffold(
      appBar: pageAppBar(context, title: Text(context.tr('Settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          AppCard(
            padding: const EdgeInsets.all(14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
            ),
            child: Row(
              children: [
                const UserAvatar(size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name ?? context.tr('Profile'),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (username != null)
                        Text('@$username',
                            style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          SectionHeader(title: context.tr('Preferences')),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('Budget period'),
                    style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  context.tr('Choose how you manage money: by month or by week.'),
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                const SizedBox(height: 10),
                const SizedBox(width: double.infinity, child: PeriodTypeToggle()),
                const SizedBox(height: 20),
                Text(context.tr('Theme'), style: theme.textTheme.labelLarge),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: const Icon(Icons.brightness_auto_outlined, size: 18),
                        label: Text(context.tr('System')),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: const Icon(Icons.light_mode_outlined, size: 18),
                        label: Text(context.tr('Light')),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: const Icon(Icons.dark_mode_outlined, size: 18),
                        label: Text(context.tr('Dark')),
                      ),
                    ],
                    selected: {prefs.themeMode},
                    onSelectionChanged: (s) => prefsCtl.setThemeMode(s.first),
                  ),
                ),
                const SizedBox(height: 20),
                Text(context.tr('Language'), style: theme.textTheme.labelLarge),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 'en', label: Text('English')),
                      ButtonSegment(value: 'id', label: Text('Bahasa Indonesia')),
                    ],
                    selected: {prefs.localeCode},
                    onSelectionChanged: (s) => prefsCtl.setLocale(s.first),
                  ),
                ),
              ],
            ),
          ),
          SectionHeader(title: context.tr('Cloud backup (online)')),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                if (backup.working) const LinearProgressIndicator(minHeight: 3),
                if (!ready)
                  ListTile(
                    leading: const Icon(Icons.cloud_off_outlined),
                    title: Text(context.tr('Firebase is not connected')),
                    subtitle: Text(context.tr(
                      'Run "flutterfire configure" in the project, then restart the app to enable login and cloud backup.',
                    )),
                  )
                else ...[
                  ListTile(
                    leading: const Icon(Icons.cloud_upload_outlined),
                    title: Text(context.tr('Back up to cloud')),
                    subtitle: Text(lastText),
                    enabled: canUseCloud,
                    onTap: () => _runAction(
                      context,
                      () => ref.read(cloudBackupProvider.notifier).backup(),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.cloud_download_outlined),
                    title: Text(context.tr('Restore from cloud')),
                    subtitle: Text(context.tr(
                      'Merges your cloud backup into this device. Newer data wins.',
                    )),
                    enabled: canUseCloud,
                    onTap: () async {
                      final ok = await _confirm(
                        context,
                        title: context.tr('Restore from cloud?'),
                        message: context.tr(
                          'Data from your cloud backup will be merged into this device. Items changed more recently on this device are kept.',
                        ),
                        action: context.tr('Restore'),
                      );
                      if (ok && context.mounted) {
                        await _runAction(
                          context,
                          () => ref.read(cloudBackupProvider.notifier).restore(),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          SectionHeader(title: context.tr('Backup file (offline)')),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: Text(context.tr('Export backup file (JSON)')),
                  subtitle: Text(context.tr('Save or share a copy of all your data.')),
                  onTap: () => _runAction(context, () async {
                    await ExportService(ref.read(databaseProvider)).shareBackup();
                    return trG('Backup file ready to share.');
                  }),
                ),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: Text(context.tr('Import backup file (JSON)')),
                  subtitle: Text(context.tr('Merges a backup file into this device.')),
                  onTap: () async {
                    final ok = await _confirm(
                      context,
                      title: context.tr('Import backup file?'),
                      message: context.tr(
                        'Data from the file will be merged into this device. Items changed more recently on this device are kept.',
                      ),
                      action: context.tr('Choose file'),
                    );
                    if (ok && context.mounted) {
                      await _runAction(
                        context,
                        () => ExportService(ref.read(databaseProvider))
                            .importBackupFile(),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          SectionHeader(title: context.tr('Data')),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: Text(context.tr('Manage categories')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const CategoriesPage()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.table_view_outlined),
                  title: Text(context.tr('Export transactions (CSV)')),
                  subtitle: Text(context.tr('Open in Excel or Google Sheets.')),
                  onTap: () => _runAction(context, () async {
                    await ExportService(ref.read(databaseProvider)).shareCsv();
                    return trG('CSV file ready to share.');
                  }),
                ),
              ],
            ),
          ),
          SectionHeader(title: context.tr('Auto-Detect Transactions')),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(context.tr('Notification Access Permission')),
                  subtitle: Text(context.tr('Allows Wall o\' Pay to detect bank & e-wallet notifications.')),
                  trailing: TextButton(
                    onPressed: () => AutoTrackerService.openNotificationSettings(),
                    child: Text(context.tr('Open Settings')),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.science_outlined),
                  title: Text(context.tr('Simulate Bank Notification')),
                  subtitle: Text(context.tr('Test detected transaction inbox with sample notifications.')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showSimulationDialog(context, ref),
                ),
              ],
            ),
          ),
          if (ready && user != null) ...[
            SectionHeader(title: context.tr('Account')),
            AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: Text(context.tr('Log out')),
                subtitle: Text(user.email ?? ''),
                onTap: () => _signOut(context, ref),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Menjalankan aksi lalu menampilkan pesan hasilnya.
  Future<void> _runAction(
    BuildContext context,
    Future<String> Function() action,
  ) async {
    String message;
    try {
      message = await action();
    } catch (e) {
      message = trG('Failed: {error}', {'error': e});
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('Log out?')),
        content: Text(context.tr(
          'Your cloud backup is not deleted. Back up first if you have recent changes, especially before erasing data on this device.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'wipe'),
            child: Text(context.tr('Log out & erase data')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'keep'),
            child: Text(context.tr('Log out')),
          ),
        ],
      ),
    );
    if (choice == null) return;

    final db = ref.read(databaseProvider);
    if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    await FirebaseAuth.instance.signOut();
    if (choice == 'wipe') await db.resetAllData();
  }

  void _showSimulationDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final samples = [
          (
            'GoPay',
            'Pembayaran QRIS sebesar Rp 28.000 di Kopi Kenangan berhasil.',
            Icons.local_cafe_outlined,
          ),
          (
            'BCA',
            'm-Transfer berhasil Rp 75.000 ke Toko Roti Manis.',
            Icons.bakery_dining_outlined,
          ),
          (
            "Livin' Mandiri",
            'Pembayaran QRIS Rp 120.000 di Superindo Mall berhasil.',
            Icons.shopping_cart_outlined,
          ),
          (
            'DANA',
            'Kirim Uang Rp 50.000 ke Budi Santoso berhasil!',
            Icons.send_outlined,
          ),
          (
            'BCA (Income)',
            'Dana masuk sebesar Rp 1.500.000 dari PT Mitra Solusi.',
            Icons.account_balance_wallet_outlined,
          ),
        ];

        return SafeArea(
          child: SingleChildScrollView(
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
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  ctx.tr('Simulate Sample Notification'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  ctx.tr('Pick a sample notification below to see how Wall o\' Pay captures it into your confirmation inbox.'),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
                ),
                const SizedBox(height: 16),
                for (final s in samples)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(s.$3, color: theme.colorScheme.primary, size: 20),
                    ),
                    title: Text(s.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(s.$2, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await ref.read(autoTrackerServiceProvider).simulateNotification(
                            sourceApp: s.$1,
                            text: s.$2,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.tr('Sample notification added! Check your Home dashboard.')),
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
