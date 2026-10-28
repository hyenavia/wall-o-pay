import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/widgets.dart';
import '../../data/cloud.dart';
import '../../data/cloud_backup.dart';
import '../../data/cloud_sync.dart';
import '../../data/export_service.dart';
import '../../data/prefs.dart';
import '../../data/profile.dart';
import '../../data/providers.dart';
import '../../data/update_checker.dart';
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
                    leading: const Icon(Icons.sync),
                    title: Text(context.tr('Real-Time Cloud Sync')),
                    subtitle: Text(context.tr('Syncs automatically between devices in real-time.')),
                    trailing: const Chip(
                      label: Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                      backgroundColor: Color(0x1B4CAF50),
                      side: BorderSide.none,
                    ),
                    enabled: canUseCloud,
                    onTap: () async {
                      await ref.read(autoSyncServiceProvider).triggerTwoWaySync();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.tr('Synced with cloud.'))),
                        );
                      }
                    },
                  ),
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
          SectionHeader(title: context.tr('App Version & Updates')),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.system_update_alt_rounded),
              title: Text(context.tr('Check for Updates')),
              subtitle: Text('Wall o\' Pay v${UpdateCheckerService.currentVersion} • Latest Release'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('Checking for updates...')),
                    duration: const Duration(seconds: 1),
                  ),
                );
                UpdateCheckerService.checkAndPromptUpdate(context, silentIfUpToDate: false);
              },
            ),
          ),
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
    ref.read(autoSyncServiceProvider).stopSync();
    await FirebaseAuth.instance.signOut();
    if (choice == 'wipe') await db.resetAllData();
  }
}
