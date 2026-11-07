/// Kumpulan aksi fungsional pada halaman Pengaturan ([SettingsActions]), mencakup
/// unggah/pulihkan cloud manual, keluar akun (logout), hapus data lokal, dan hapus akun permanen.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/auth_service.dart';
import '../../data/budget_rule.dart';
import '../../data/cloud.dart';
import '../../data/cloud_sync.dart';
import '../../data/lock.dart';
import '../../data/notifications.dart';
import '../../data/prefs.dart';
import '../../data/profile.dart';
import '../../data/providers.dart';

/// Handler aksi sinkronisasi cloud, autentikasi, dan penghapusan akun pada halaman Pengaturan.
class SettingsActions {
  SettingsActions._();

  static Future<void> handleManualUpload(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('Sending data to cloud...')),
        duration: const Duration(seconds: 2),
      ),
    );
    try {
      final count = await ref.read(autoSyncServiceProvider).pushAllLocalToCloud();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cloud_done_rounded, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr(
                      'Successfully sent {count} items to the cloud.',
                      {'count': count},
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E4238),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr('Failed to send data: {error}', {'error': e.toString()}),
            ),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  static Future<void> handleManualRestore(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('Fetching data from cloud...')),
        duration: const Duration(seconds: 2),
      ),
    );
    try {
      final count = await ref.read(autoSyncServiceProvider).pullAllRemoteToLocal();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cloud_done_rounded, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr(
                      'Successfully restored {count} items from the cloud.',
                      {'count': count},
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E4238),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr('Failed to fetch data: {error}', {'error': e.toString()}),
            ),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  static Future<void> handleTwoWaySync(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(autoSyncServiceProvider).triggerTwoWaySync();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('Synced with cloud.')),
            backgroundColor: const Color(0xFF1E4238),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('Sync failed: {error}', {'error': e.toString()})),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  static Future<void> runAction(
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

  static Future<bool> confirm(
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

  static Future<void> signOut(BuildContext context, WidgetRef ref) async {
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
                  Text(context.tr('Logging out...')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      ref.read(autoSyncServiceProvider).stopSync();
      final db = ref.read(databaseProvider);

      // Reset database lokal perangkat agar tidak bocor ke akun berikutnya
      try {
        await db.resetAllData();
      } catch (e) {
        debugPrint('[SettingsPage] Error resetting local db on logout: $e');
      }
      try {
        await ref.read(profileProvider.notifier).clearLocal();
        await ref.read(budgetRuleProvider.notifier).clearLocal();
      } catch (e) {
        debugPrint('[SettingsPage] Error clearing local caches: $e');
      }
      try {
        await Lock.instance.loadForUser(null);
      } catch (e) {
        debugPrint('[SettingsPage] Error resetting lock: $e');
      }

      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.remove('current_sync_user_id');
      await ref.read(skipAuthProvider.notifier).reset();

      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      debugPrint('[SettingsPage] Sign out failed: $e');
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.themeColors.expense,
            content: Text(context.tr('Log out failed: {error}', {'error': e})),
          ),
        );
      }
    }
  }

  static Future<void> deleteAccount(BuildContext context, WidgetRef ref) async {
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
          style: TextStyle(color: ctx.themeColors.expense, fontWeight: FontWeight.bold),
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
            style: FilledButton.styleFrom(backgroundColor: ctx.themeColors.expense),
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
            backgroundColor: context.themeColors.expense,
            content: Text(context.tr('Password is required to delete account.')),
          ),
        );
      }
      return;
    }

    final db = ref.read(databaseProvider);
    final userUid = user?.uid;
    final username = ref.read(usernameProvider);

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
      await AuthService().deleteAccount(
        password: password.isNotEmpty ? password : null,
        username: username,
      );

      if (userUid != null) {
        await ref.read(profileProvider.notifier).clearLocal(userUid);
        await ref.read(budgetRuleProvider.notifier).clearLocal(userUid);
        await Lock.instance.clearLocal(userUid);
      }
      try {
        await db.resetAllData();
      } catch (e) {
        debugPrint('[SettingsPage] Error resetting local db on delete: $e');
      }
      await ref.read(profileProvider.notifier).clearLocal();
      await ref.read(budgetRuleProvider.notifier).clearLocal();
      await Lock.instance.loadForUser(null);

      // Batalkan seluruh jadwal pengingat harian lokal
      try {
        await NotificationService.instance.cancelDailyReminder();
      } catch (e) {
        debugPrint('[SettingsPage] Error cancelling reminder on delete: $e');
      }

      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.remove('current_sync_user_id');
      await ref.read(skipAuthProvider.notifier).reset();
      if (userUid != null) {
        await prefs.remove('onboarding_done_$userUid');
      }

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.themeColors.income,
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
          SnackBar(backgroundColor: context.themeColors.expense, content: Text(errorMsg)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.themeColors.expense,
            content: Text(context.tr('Error: {error}', {'error': e})),
          ),
        );
      }
    }
  }

  static Future<void> exitGuestMode(BuildContext context, WidgetRef ref) async {
    final ok = await confirm(
      context,
      title: context.tr('Exit Guest Mode?'),
      message: context.tr(
        'You will return to the login screen. Your local data stays on this device unless erased.',
      ),
      action: context.tr('Exit Guest Mode'),
    );
    if (!ok) return;
    await ref.read(skipAuthProvider.notifier).reset();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
    }
  }

  static Future<void> eraseGuestData(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          ctx.tr('Erase Local Guest Data?'),
          style: TextStyle(
            color: ctx.themeColors.expense,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(ctx.tr(
          'Warning: All local transactions, budgets, wallets, and settings recorded in Guest mode on this device will be permanently erased.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ctx.themeColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.tr('Erase All Data')),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref.read(databaseProvider).resetAllData();
      await ref.read(profileProvider.notifier).clearLocal(ProfileController.guestId);
      await ref.read(budgetRuleProvider.notifier).clearLocal();
      await Lock.instance.clearLocal('guest');
      try {
        await NotificationService.instance.cancelDailyReminder();
      } catch (_) {}
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.remove('onboarding_done_local');
      await ref.read(skipAuthProvider.notifier).reset();

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.themeColors.income,
            content: Text(context.tr('Local guest data erased.')),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.themeColors.expense,
            content: Text(context.tr('Error: {error}', {'error': e})),
          ),
        );
      }
    }
  }
}
