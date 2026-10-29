import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/period.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/auth_service.dart';
import '../../data/cloud.dart';
import '../../data/cloud_backup.dart';
import '../../data/cloud_sync.dart';
import '../../data/budget_rule.dart';
import '../recurring/recurring_page.dart';
import '../../data/export_service.dart';
import '../../data/prefs.dart';
import '../../data/profile.dart';
import '../../data/providers.dart';
import '../../data/update_checker.dart';
import '../categories/categories_page.dart';
import '../profile/profile_page.dart';
import '../../data/lock.dart';
import '../security/security_page.dart';

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
    final updateInfo = ref.watch(availableUpdateProvider);

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
                if (prefs.periodType == PeriodType.weekly) ...[
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
                if (backup.working) ...[
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
                          color: const Color(0x1B4CAF50),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_done_rounded, color: Colors.green, size: 24),
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
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0x1B4CAF50),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    context.tr('Active'),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr('All transactions, wallets, budgets, and goals are automatically saved to the cloud.'),
                              style: theme.textTheme.bodySmall?.copyWith(color: muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          lastText,
                          style: theme.textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        icon: const Icon(Icons.sync_rounded, size: 16),
                        label: Text(context.tr('Sync Now')),
                        onPressed: canUseCloud
                            ? () async {
                                await ref.read(autoSyncServiceProvider).triggerTwoWaySync();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(context.tr('Synced with cloud.'))),
                                  );
                                }
                              }
                            : null,
                      ),
                    ],
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
                  leading: const Icon(Icons.repeat_rounded),
                  title: Text(context.tr('Recurring & Subscriptions')),
                  subtitle: Text(context.tr('Manage routine expenses, incomes & transfers.')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const RecurringPage()),
                  ),
                ),
                const Divider(height: 1),
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
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: Text(context.tr('Log out')),
                    subtitle: Text(user.email ?? ''),
                    onTap: () => _signOut(context, ref),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.person_remove_outlined, color: AppColors.expense),
                    title: Text(
                      context.tr('Delete Account & Data'),
                      style: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(context.tr('Permanently delete your account and all data.')),
                    onTap: () => _deleteAccount(context, ref),
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

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('Log out?')),
        content: Text(context.tr(
          'Your financial data is safely stored in the cloud. You can log back in on this or another device anytime.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('Log out')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final db = ref.read(databaseProvider);
    if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    ref.read(autoSyncServiceProvider).stopSync();

    // Reset database lokal perangkat agar tidak bocor ke akun berikutnya
    await db.resetAllData();
    await ref.read(budgetRuleProvider.notifier).clearLocal();
    await Lock.instance.loadForUser(null);

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove('current_sync_user_id');

    await FirebaseAuth.instance.signOut();
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final passwordController = TextEditingController();
    var hasPasswordAuth = false;
    final user = ref.read(currentUserProvider);
    if (user != null) {
      for (final info in user.providerData) {
        if (info.providerId == 'password') hasPasswordAuth = true;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          context.tr('Delete Account Permanently?'),
          style: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr(
                'Warning: This action is permanent and cannot be undone. Your user account, all transactions, budgets, wallets, and settings will be permanently erased from the cloud and this device.',
              )),
              if (hasPasswordAuth) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: context.tr('Enter Password to Confirm'),
                    hintText: context.tr('Password'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('Delete Permanently')),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      passwordController.dispose();
      return;
    }

    final password = passwordController.text.trim();
    passwordController.dispose();

    if (hasPasswordAuth && password.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.expense,
            content: Text(context.tr('Password is required to delete account.')),
          ),
        );
      }
      return;
    }

    final db = ref.read(databaseProvider);
    final userUid = user?.uid;

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(context.tr('Deleting account and wiping data...')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      ref.read(autoSyncServiceProvider).stopSync();
      await AuthService().deleteAccount(password: password.isNotEmpty ? password : null);

      if (userUid != null) {
        await ref.read(budgetRuleProvider.notifier).clearLocal(userUid);
        await Lock.instance.clearLocal(userUid);
      }
      await db.resetAllData();
      await ref.read(budgetRuleProvider.notifier).clearLocal();
      await Lock.instance.loadForUser(null);

      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.remove('current_sync_user_id');

      if (context.mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.income,
            content: Text(context.tr('Account and all data successfully deleted.')),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading
        final errorMsg = e.code == 'wrong-password' || e.code == 'invalid-credential'
            ? context.tr('Incorrect password. Account was not deleted.')
            : e.message ?? e.code;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.expense, content: Text(errorMsg)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.expense,
            content: Text(context.tr('Error: {error}', {'error': e})),
          ),
        );
      }
    }
  }
}
