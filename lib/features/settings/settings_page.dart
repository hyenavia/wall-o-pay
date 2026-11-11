/// Halaman Pengaturan utama ([SettingsPage]) yang memuat kartu profil, preferensi periode & bahasa,
/// pengingat notifikasi, keamanan PIN, sinkronisasi cloud, ekspor/impor berkas, dan informasi aplikasi.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/period.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/budget_rule.dart';
import '../../data/cloud.dart';
import '../../data/cloud_backup.dart';
import '../../data/cloud_sync.dart';
import '../../data/feature_prefs.dart';
import '../../data/notifications.dart';
import 'app_changelog.dart';
import 'about_sheet.dart';
import '../../data/export_service.dart';
import '../../data/prefs.dart';
import '../../data/profile.dart';
import '../../data/providers.dart';
import '../../data/update_checker.dart';
import '../auth/auth_page.dart';
import '../categories/categories_page.dart';
import '../profile/profile_page.dart';
import '../../data/lock.dart';
import '../security/security_page.dart';
import 'settings_actions.dart';

/// Widget halaman Pengaturan aplikasi.
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
    final name = ref.watch(displayNameProvider);
    final username = ref.watch(usernameProvider);
    final canUseCloud = ready && user != null && !isSyncing;
    final updateInfo = ref.watch(availableUpdateProvider);
    final colors = context.themeColors;

    final lastSyncTime = sync.lastSynced ?? backup.lastBackup;
    final lastText = lastSyncTime == null
        ? context.tr('No cloud backup yet.')
        : context.tr('Last backup {date}', {'date': dateTimeLabel(lastSyncTime)});

    Widget iconBadge(IconData icon, Color color) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
            width: 0.8,
          ),
        ),
        child: Icon(icon, color: color, size: 20),
      );
    }

    return Scaffold(
      appBar: secondaryAppBar(context, title: Text(context.tr('Settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
        children: [
          _GlasshouseProfileCard(
            name: name,
            username: username,
            email: user?.email,
            isGuest: user == null,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
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
                SwitchListTile(
                  secondary: iconBadge(Icons.redo_rounded, colors.income),
                  title: Text(
                    context.tr('Carry over unused budget'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    context.tr('Leftover budget from the previous period is added to the next one.'),
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                  value: features.rollover,
                  onChanged: featuresCtl.setRollover,
                ),
                const Divider(height: 1, indent: 68),
                SwitchListTile(
                  secondary: iconBadge(Icons.notifications_active_outlined, colors.warning),
                  title: Text(
                    context.tr('Budget alerts'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    context.tr('Get notified when a category reaches 80% and 100% of its budget.'),
                    style: TextStyle(fontSize: 12, color: muted),
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
                const Divider(height: 1, indent: 68),
                SwitchListTile(
                  secondary: iconBadge(Icons.alarm_rounded, const Color(0xFF60A5FA)),
                  title: Text(
                    context.tr('Daily reminder'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    context.tr('A gentle nudge to log your spending.'),
                    style: TextStyle(fontSize: 12, color: muted),
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
                if (features.dailyReminder) ...[
                  const Divider(height: 1, indent: 68),
                  ListTile(
                    leading: iconBadge(Icons.schedule_rounded, AppColors.sage),
                    title: Text(
                      context.tr('Reminder time'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    trailing: Text(
                      features.reminderTime.format(context),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.sage,
                      ),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: iconBadge(
                    Icons.lock_outline_rounded,
                    lockState.enabled
                        ? colors.income
                        : colors.primary,
                  ),
                  title: Text(
                    context.tr('App PIN Lock'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    lockState.enabled
                        ? (lockState.biometricEnabled
                            ? context.tr('Active (PIN + Biometric) • Timeout: {time}', {'time': timeoutLabel})
                            : context.tr('Active • Timeout: {time}', {'time': timeoutLabel}))
                        : context.tr('Protect your financial data with a 6-digit PIN.'),
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
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
                else if (user == null) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.sage.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_off_outlined,
                          color: AppColors.sage,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('Guest Mode (Offline)'),
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr(
                                'Your records are stored locally on this device. Sign in or create an account to back up and sync across devices.',
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(color: muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
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
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: Text(context.tr('Sign In / Create Account')),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(builder: (_) => const AuthPage()),
                      ),
                    ),
                  ),
                ] else ...[
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: iconBadge(Icons.file_upload_outlined, colors.income),
                  title: Text(
                    context.tr('Export backup file (JSON)'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    context.tr('Save or share a copy of all your data.'),
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => SettingsActions.runAction(context, () async {
                    final prefs = ref.read(appPrefsProvider.notifier).exportPreferences();
                    final budget = ref.read(budgetRuleProvider.notifier).exportConfig();
                    await ExportService(ref.read(databaseProvider)).shareBackup(
                      preferences: prefs,
                      budgetConfig: budget,
                    );
                    return trG('Backup file ready to share.');
                  }),
                ),
                const Divider(height: 1, indent: 68),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: iconBadge(Icons.file_download_outlined, const Color(0xFF60A5FA)),
                  title: Text(
                    context.tr('Import backup file (JSON)'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    context.tr('Merges a backup file into this device.'),
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
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
                        () => ExportService(ref.read(databaseProvider)).importBackupFile(
                          onImportPreferences: (p) =>
                              ref.read(appPrefsProvider.notifier).importPreferences(p),
                          onImportBudgetConfig: (b) =>
                              ref.read(budgetRuleProvider.notifier).importConfig(b),
                        ),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: iconBadge(Icons.category_outlined, const Color(0xFFA78BFA)),
                  title: Text(
                    context.tr('Manage categories'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const CategoriesPage()),
                  ),
                ),
                const Divider(height: 1, indent: 68),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: iconBadge(Icons.table_view_outlined, AppColors.sage),
                  title: Text(
                    context.tr('Export transactions (CSV)'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    context.tr('Open in Excel or Google Sheets.'),
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: iconBadge(Icons.logout_rounded, colors.warning),
                    title: Text(
                      context.tr('Log out'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      user.email ?? '',
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                    onTap: () => SettingsActions.signOut(context, ref),
                  ),
                  const Divider(height: 1, indent: 68),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: iconBadge(Icons.person_remove_outlined, colors.expense),
                    title: Text(
                      context.tr('Delete Account & Data'),
                      style: TextStyle(color: colors.expense, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      context.tr('Permanently delete your account and all data.'),
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                    onTap: () => SettingsActions.deleteAccount(context, ref),
                  ),
                ],
              ),
            ),
          ] else if (user == null) ...[
            SectionHeader(title: context.tr('Account')),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  if (ready) ...[
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: iconBadge(Icons.logout_rounded, colors.warning),
                      title: Text(
                        context.tr('Exit Guest Mode'),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        context.tr('Return to the login screen.'),
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                      onTap: () => SettingsActions.exitGuestMode(context, ref),
                    ),
                    const Divider(height: 1, indent: 68),
                  ],
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: iconBadge(Icons.delete_forever_outlined, colors.expense),
                    title: Text(
                      context.tr('Erase Local Guest Data'),
                      style: TextStyle(
                        color: colors.expense,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      context.tr('Permanently delete all local data on this device.'),
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                    onTap: () => SettingsActions.eraseGuestData(context, ref),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: iconBadge(Icons.info_outline_rounded, AppColors.sage),
                  title: Text(
                    context.tr('About Wall o\' Pay'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    context.tr('Philosophy, brand lore & app details'),
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => showAboutWallOPaySheet(context),
                ),
                const Divider(height: 1, indent: 68),
                _UpdateTile(
                  updateInfo: updateInfo,
                  muted: muted,
                  iconBadge: iconBadge,
                ),
                const Divider(height: 1, indent: 68),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: iconBadge(Icons.history_edu_rounded, const Color(0xFF60A5FA)),
                  title: Text(
                    context.tr('Version Changelog'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    context.tr(
                      'See what\'s new in v{version} and past releases',
                      {'version': UpdateCheckerService.currentVersion},
                    ),
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => showAppChangelogSheet(context),
                ),
                const Divider(height: 1, indent: 68),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: iconBadge(Icons.feedback_outlined, const Color(0xFFA78BFA)),
                  title: Text(
                    context.tr('Send Feedback'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    context.tr('Help us improve with your suggestions & bug reports.'),
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
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

class _UpdateTile extends StatelessWidget {
  const _UpdateTile({
    required this.updateInfo,
    required this.muted,
    required this.iconBadge,
  });

  final dynamic updateInfo;
  final Color muted;
  final Widget Function(IconData, Color) iconBadge;

  void _handleTap(BuildContext context, WidgetRef ref) {
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
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    return Consumer(
      builder: (context, ref, _) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: iconBadge(
            Icons.system_update_alt_rounded,
            updateInfo != null
                ? colors.warning
                : colors.income,
          ),
          title: Row(
            children: [
              Text(
                context.tr('Check for Updates'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
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
                : 'Wall o\' Pay v${UpdateCheckerService.currentVersion} • ${context.tr('Latest Release')}',
            style: TextStyle(
              fontSize: 12,
              color: updateInfo != null ? const Color(0xFFE65100) : muted,
              fontWeight: updateInfo != null ? FontWeight.w700 : null,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () => _handleTap(context, ref),
        );
      },
    );
  }
}

/// Kartu profil pengguna bergaya premium botanical glassmorphism untuk halaman Pengaturan.
class _GlasshouseProfileCard extends StatelessWidget {
  const _GlasshouseProfileCard({
    required this.name,
    required this.username,
    required this.email,
    required this.isGuest,
    required this.onTap,
  });

  final String? name;
  final String? username;
  final String? email;
  final bool isGuest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.mossShadow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.dewMint.withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.dewMint.withValues(alpha: 0.05),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: AppColors.dewMint.withValues(alpha: 0.10),
            highlightColor: AppColors.dewMint.withValues(alpha: 0.05),
            child: Stack(
              children: [
                // Glasshouse gradient background
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1B3D30).withValues(alpha: 0.90),
                          AppColors.mossShadow,
                        ],
                      ),
                    ),
                  ),
                ),
                // Specular glass glare & greenhouse arch overlay
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ProfileCardGlassPainter(),
                    ),
                  ),
                ),
                // Subtle botanical corner ornament
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.09,
                      child: Image.asset(
                        'assets/icons/glasshouse/savings.png',
                        width: 90,
                        height: 90,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // Foreground content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  child: Row(
                    children: [
                      // Circular Profile Avatar with Botanical Glass Frame
                      const UserAvatar(size: 60, withGlassFrame: true),
                      const SizedBox(width: 14),
                      // Information Hierarchy
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Minimalist Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF23483B).withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.dewMint.withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.dewMint,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isGuest
                                        ? context.tr('Guest Mode')
                                        : context.tr('Personal Account'),
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                      color: AppColors.dewMint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            // User Name in Outfit SemiBold
                            Text(
                              name ??
                                  (isGuest
                                      ? context.tr('Guest')
                                      : context.tr('Profile')),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 17.5,
                                color: AppColors.softIvory,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Email or username in DM Sans
                            Text(
                              email ??
                                  (username != null
                                      ? '@$username'
                                      : (isGuest
                                          ? context.tr('Offline local storage')
                                          : 'user@wallopay.local')),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                                color: AppColors.freshSage,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Edit Profile Button at the Top-Right
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.mossShadow.withValues(alpha: 0.70),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.dewMint.withValues(alpha: 0.40),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.dewMint.withValues(alpha: 0.12),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.dewMint,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Painter efek specular sheen dan garis arsitektur conservatory untuk kartu profil.
class _ProfileCardGlassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Specular glass diagonal sheen
    final sheenPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.7],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), sheenPaint);

    // 2. Subtle greenhouse mullion lines in top-right
    final archPaint = Paint()
      ..color = AppColors.dewMint.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path()
      ..moveTo(size.width * 0.65, 0)
      ..cubicTo(
        size.width * 0.75,
        size.height * 0.3,
        size.width * 0.9,
        size.height * 0.4,
        size.width,
        size.height * 0.5,
      );
    canvas.drawPath(path, archPaint);

    final path2 = Path()
      ..moveTo(size.width * 0.8, 0)
      ..cubicTo(
        size.width * 0.88,
        size.height * 0.25,
        size.width * 0.95,
        size.height * 0.35,
        size.width,
        size.height * 0.45,
      );
    canvas.drawPath(path2, archPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
