import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/period.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/cloud.dart';
import '../../data/cloud_backup.dart';
import '../../data/cloud_sync.dart';
import '../../data/feature_prefs.dart';
import '../../data/module_prefs.dart';
import '../../data/notifications.dart';
import 'app_changelog.dart';
import 'about_sheet.dart';
import 'module_sheet.dart';
import '../../data/export_service.dart';
import '../../data/prefs.dart';
import '../../data/profile.dart';
import '../../data/providers.dart';
import '../../data/update_checker.dart';
import '../categories/categories_page.dart';
import '../profile/profile_page.dart';
import '../../data/lock.dart';
import '../security/security_page.dart';
import 'settings_actions.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final ready = ref.watch(firebaseReadyProvider);
    final user = ref.watch(currentUserProvider);
    final backup = ref.watch(cloudBackupProvider);
    final sync = ref.watch(syncStateProvider);
    final isSyncing = backup.working || sync.status == SyncStatus.syncing;
    final prefs = ref.watch(appPrefsProvider);
    final prefsCtl = ref.read(appPrefsProvider.notifier);
    final features = ref.watch(featurePrefsProvider);
    final featuresCtl = ref.read(featurePrefsProvider.notifier);
    final modulePrefs = ref.watch(modulePrefsProvider);
    final name = ref.watch(displayNameProvider);
    final username = ref.watch(usernameProvider);
    final canUseCloud = ready && user != null && !isSyncing;
    final updateInfo = ref.watch(availableUpdateProvider);

    final lastSyncTime = sync.lastSynced ?? backup.lastBackup;
    final lastText = lastSyncTime == null
        ? context.tr('No cloud backup yet.')
        : context.tr('Last backup {date}', {'date': dateTimeLabel(lastSyncTime)});

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
                if (prefs.periodType == PeriodType.monthly) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr('Monthly Start Day'), style: theme.textTheme.labelMedium),
                            Text(
                              context.tr('Day of the month to start monthly period (e.g. Payday on 25th)'),
                              style: theme.textTheme.bodySmall?.copyWith(color: muted),
                            ),
                          ],
                        ),
                      ),
                      DropdownButton<int>(
                        value: prefs.firstDayOfMonth,
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(12),
                        items: [
                          for (int d = 1; d <= 28; d++)
                            DropdownMenuItem(
                              value: d,
                              child: Text(
                                d == 25
                                    ? context.tr('Day {day} (Payday)', {'day': d})
                                    : context.tr('Day {day}', {'day': d}),
                              ),
                            ),
                        ],
                        onChanged: (val) {
                          if (val != null) prefsCtl.setFirstDayOfMonth(val);
                        },
                      ),
                    ],
                  ),
                ] else if (prefs.periodType == PeriodType.weekly) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr('Weekly Start Day'), style: theme.textTheme.labelMedium),
                            Text(
                              context.tr('Week starts on {day}', {
                                'day': _getDayName(context, prefs.firstDayOfWeek),
                              }),
                              style: theme.textTheme.bodySmall?.copyWith(color: muted),
                            ),
                          ],
                        ),
                      ),
                      DropdownButton<int>(
                        value: prefs.firstDayOfWeek,
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(12),
                        items: [
                          DropdownMenuItem(value: DateTime.monday, child: Text(context.tr('Monday'))),
                          DropdownMenuItem(value: DateTime.tuesday, child: Text(context.tr('Tuesday'))),
                          DropdownMenuItem(value: DateTime.wednesday, child: Text(context.tr('Wednesday'))),
                          DropdownMenuItem(value: DateTime.thursday, child: Text(context.tr('Thursday'))),
                          DropdownMenuItem(value: DateTime.friday, child: Text(context.tr('Friday'))),
                          DropdownMenuItem(value: DateTime.saturday, child: Text(context.tr('Saturday'))),
                          DropdownMenuItem(value: DateTime.sunday, child: Text(context.tr('Sunday'))),
                        ],
                        onChanged: (val) {
                          if (val != null) prefsCtl.setFirstDayOfWeek(val);
                        },
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                Text(context.tr('Theme'), style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  context.tr("Signature Botanical Forest — Wall o' Pay exclusive aesthetic"),
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.deepForest.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.deepForest.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.deepForest,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.forest_rounded, color: AppColors.sage, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('Deep Forest Botanical'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr('Curated signature palette (Night Pine, Velvet Forest & Sage)'),
                              style: TextStyle(fontSize: 11, color: muted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.deepForest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          context.tr('SIGNATURE'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
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

          SectionHeader(title: context.tr('Budget & reminders')),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.widgets_outlined),
                  title: Text(context.tr('Active Modules & Features')),
                  subtitle: Text(
                    context.tr('{count} of {total} modules active', {
                      'count': modulePrefs.activeCount,
                      'total': 5,
                    }),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showModuleSelectionSheet(context),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.redo),
                  title: Text(context.tr('Carry over unused budget')),
                  subtitle: Text(
                    context.tr('Leftover budget from the previous period is added to the next one.'),
                  ),
                  value: features.rollover,
                  onChanged: featuresCtl.setRollover,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: Text(context.tr('Budget alerts')),
                  subtitle: Text(
                    context.tr('Get notified when a category reaches 80% and 100% of its budget.'),
                  ),
                  value: features.budgetAlerts,
                  onChanged: (v) async {
                    if (v && !await NotificationService.instance.requestPermission()) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.tr('Notification permission was not granted.'))),
                        );
                      }
                      return;
                    }
                    featuresCtl.setBudgetAlerts(v);
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.alarm),
                  title: Text(context.tr('Daily reminder')),
                  subtitle: Text(
                    context.tr('A gentle nudge to log your spending.'),
                  ),
                  value: features.dailyReminder,
                  onChanged: (v) async {
                    if (v && !await NotificationService.instance.requestPermission()) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.tr('Notification permission was not granted.'))),
                        );
                      }
                      return;
                    }
                    await featuresCtl.setDailyReminder(v);
                    await NotificationService.instance.syncReminder(
                      enabled: v,
                      time: features.reminderTime,
                    );
                  },
                ),
                if (features.dailyReminder)
                  ListTile(
                    leading: const SizedBox(width: 24),
                    title: Text(context.tr('Reminder time')),
                    trailing: Text(
                      features.reminderTime.format(context),
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: features.reminderTime,
                      );
                      if (picked != null) {
                        await featuresCtl.setReminderTime(picked);
                        await NotificationService.instance.syncReminder(
                          enabled: true,
                          time: picked,
                        );
                      }
                    },
                  ),
              ],
            ),
          ),

          SectionHeader(title: context.tr('Security')),
          ValueListenableBuilder<AppLockState>(
            valueListenable: Lock.instance.state,
            builder: (context, lockState, _) {
              final timeoutLabel = switch (lockState.delayMin) {
                0 => context.tr('Immediately'),
                5 => context.tr('5 minutes'),
                _ => context.tr('1 minute'),
              };
              return AppCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.lock_outline_rounded),
                  title: Text(context.tr('App PIN Lock')),
                  subtitle: Text(
                    lockState.enabled
                        ? context.tr('Active • Timeout: {time}', {'time': timeoutLabel})
                        : context.tr('Protect your financial data with a 6-digit PIN.'),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const SecurityPage()),
                  ),
                ),
              );
            },
          ),
          SectionHeader(title: context.tr('Cloud Sync & Storage')),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSyncing) ...[
                  const LinearProgressIndicator(minHeight: 3),
                  const SizedBox(height: 12),
                ],
                if (!ready)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_off_outlined),
                    title: Text(context.tr('Firebase is not connected')),
                    subtitle: Text(context.tr(
                      'Run "flutterfire configure" in the project, then restart the app to enable login and cloud backup.',
                    )),
                  )
                else ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: sync.status == SyncStatus.error
                              ? const Color(0x1BFF5722)
                              : const Color(0x1B4CAF50),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          sync.status == SyncStatus.syncing
                              ? Icons.sync_rounded
                              : (sync.status == SyncStatus.error
                                  ? Icons.sync_problem_rounded
                                  : Icons.cloud_done_rounded),
                          color: sync.status == SyncStatus.error
                              ? Colors.deepOrange
                              : Colors.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  context.tr('Real-Time Cloud Sync'),
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: sync.status == SyncStatus.error
                                        ? const Color(0x1BFF5722)
                                        : const Color(0x1B4CAF50),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    sync.status == SyncStatus.syncing
                                        ? context.tr('Syncing in progress...')
                                        : (sync.status == SyncStatus.error
                                            ? 'Error'
                                            : context.tr('Active')),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: sync.status == SyncStatus.error
                                          ? Colors.deepOrange
                                          : Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr(
                                'Automatic background sync keeps your data safe across devices.',
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(color: muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    lastText,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                          label: Text(context.tr('Send to Cloud')),
                          onPressed: canUseCloud ? () => SettingsActions.handleManualUpload(context, ref) : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.cloud_download_outlined, size: 16),
                          label: Text(context.tr('Fetch from Cloud')),
                          onPressed: canUseCloud ? () => SettingsActions.handleManualRestore(context, ref) : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.sync_rounded, size: 16),
                      label: Text(context.tr('Sync Now (Two-Way)')),
                      onPressed: canUseCloud ? () => SettingsActions.handleTwoWaySync(context, ref) : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SectionHeader(title: context.tr('Manual Backup & Export')),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: Text(context.tr('Export backup file (JSON)')),
                  subtitle: Text(context.tr('Save or share a copy of all your data.')),
                  onTap: () => SettingsActions.runAction(context, () async {
                    await ExportService(ref.read(databaseProvider)).shareBackup();
                    return trG('Backup file ready to share.');
                  }),
                ),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: Text(context.tr('Import backup file (JSON)')),
                  subtitle: Text(context.tr('Merges a backup file into this device.')),
                  onTap: () async {
                    final ok = await SettingsActions.confirm(
                      context,
                      title: context.tr('Import backup file?'),
                      message: context.tr(
                        'Data from the file will be merged into this device. Items changed more recently on this device are kept.',
                      ),
                      action: context.tr('Choose file'),
                    );
                    if (ok && context.mounted) {
                      await SettingsActions.runAction(
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
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.table_view_outlined),
                  title: Text(context.tr('Export transactions (CSV)')),
                  subtitle: Text(context.tr('Open in Excel or Google Sheets.')),
                  onTap: () => SettingsActions.runAction(context, () async {
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
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: Text(context.tr('Log out')),
                    subtitle: Text(user.email ?? ''),
                    onTap: () => SettingsActions.signOut(context, ref),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.person_remove_outlined, color: AppColors.expense),
                    title: Text(
                      context.tr('Delete Account & Data'),
                      style: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(context.tr('Permanently delete your account and all data.')),
                    onTap: () => SettingsActions.deleteAccount(context, ref),
                  ),
                ],
              ),
            ),
          ],
          SectionHeader(title: context.tr('About & Support')),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text(context.tr('About Wall o\' Pay')),
                  subtitle: Text(context.tr('Philosophy, brand lore & app details')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showAboutWallOPaySheet(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.system_update_alt_rounded),
                  title: Row(
                    children: [
                      Text(context.tr('Check for Updates')),
                      if (updateInfo != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE65100),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            context.tr('NEW'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    updateInfo != null
                        ? 'v${UpdateCheckerService.currentVersion} ➔ v${updateInfo.latestVersion} (${context.tr('Update Available!')})'
                        : 'Wall o\' Pay v${UpdateCheckerService.currentVersion} • Latest Release',
                    style: TextStyle(
                      color: updateInfo != null ? const Color(0xFFE65100) : null,
                      fontWeight: updateInfo != null ? FontWeight.w700 : null,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    if (updateInfo != null) {
                      UpdateCheckerService.showUpdateDialog(context, updateInfo);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.tr('Checking for updates...')),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                      UpdateCheckerService.checkAndPromptUpdate(context, ref: ref, silentIfUpToDate: false);
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history_edu_rounded),
                  title: Text(context.tr('Version Changelog')),
                  subtitle: Text(
                    context.tr(
                      'See what\'s new in v{version} and past releases',
                      {'version': UpdateCheckerService.currentVersion},
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showAppChangelogSheet(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: Text(context.tr('Send Feedback')),
                  subtitle: Text(context.tr('Help us improve with your suggestions & bug reports.')),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () {
                    final isIndonesian = prefs.localeCode == 'id';
                    final url = isIndonesian
                        ? 'https://forms.gle/jzhTG5HmxA96xCsX8'
                        : 'https://forms.gle/W5MNr8eeZcmiiPbp9';
                    UpdateCheckerService.openUrl(url);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(BuildContext context, int day) {
    return switch (day) {
      DateTime.monday => context.tr('Monday'),
      DateTime.tuesday => context.tr('Tuesday'),
      DateTime.wednesday => context.tr('Wednesday'),
      DateTime.thursday => context.tr('Thursday'),
      DateTime.friday => context.tr('Friday'),
      DateTime.saturday => context.tr('Saturday'),
      DateTime.sunday => context.tr('Sunday'),
      _ => context.tr('Monday'),
    };
  }
}
