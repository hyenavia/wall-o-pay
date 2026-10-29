import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/l10n.dart';
import '../core/theme.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseName,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.releasePageUrl,
    required this.hasUpdate,
  });

  final String currentVersion;
  final String latestVersion;
  final String releaseName;
  final String releaseNotes;
  final String downloadUrl;
  final String releasePageUrl;
  final bool hasUpdate;
}

class AvailableUpdateNotifier extends Notifier<AppUpdateInfo?> {
  @override
  AppUpdateInfo? build() => null;

  void setUpdate(AppUpdateInfo? info) => state = info;
  void dismiss() => state = null;
}

/// Provider reaktif untuk notifikasi pembaruan aplikasi di seluruh halaman.
final availableUpdateProvider =
    NotifierProvider<AvailableUpdateNotifier, AppUpdateInfo?>(AvailableUpdateNotifier.new);

class UpdateCheckerService {
  /// Versi aplikasi saat ini. Selalu disinkronkan dengan pubspec.yaml.
  static const currentVersion = '1.3.3';

  static const String _prefLastNotifiedKey = 'pref_last_notified_update_version';

  static const MethodChannel _channel =
      MethodChannel('com.example.wall_o_pay/notifications');

  static const String _latestReleaseApi =
      'https://api.github.com/repos/hyenavia/wall-o-pay/releases/latest';
  static const String _directDownloadUrl =
      'https://github.com/hyenavia/wall-o-pay/releases/latest/download/Wall_o_Pay.apk';

  /// Meminta izin notifikasi sistem Android (Android 13+).
  static Future<bool> requestNotificationPermission() async {
    try {
      final granted = await _channel.invokeMethod<bool>('requestNotificationPermission');
      return granted ?? false;
    } catch (e) {
      debugPrint('Failed to request notification permission: $e');
      return false;
    }
  }

  /// Memeriksa apakah notifikasi sistem diizinkan.
  static Future<bool> areNotificationsEnabled() async {
    try {
      final enabled = await _channel.invokeMethod<bool>('areNotificationsEnabled');
      return enabled ?? true;
    } catch (e) {
      return true;
    }
  }

  /// Menampilkan notifikasi sistem Android di bilah status / heads-up notification.
  static Future<bool> postSystemNotification({
    required String title,
    required String body,
    required String downloadUrl,
    String actionText = 'Download APK',
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('postUpdateNotification', {
        'title': title,
        'body': body,
        'downloadUrl': downloadUrl,
        'actionText': actionText,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Failed to post system notification: $e');
      return false;
    }
  }

  /// Membuka URL di browser atau installer eksternal via native intent.
  static Future<void> openUrl(String url) async {
    try {
      await _channel.invokeMethod('openUrl', {'url': url});
    } catch (e) {
      debugPrint('Failed to open URL via native: $e');
    }
  }

  /// Memeriksa pembaruan di latar belakang, memicu notifikasi sistem bilah status HP,
  /// dan memperbarui state banner notifikasi di dalam aplikasi.
  static Future<AppUpdateInfo?> checkAndNotify(
    WidgetRef ref, {
    bool forceSystemNotification = false,
  }) async {
    final info = await checkForUpdate();
    if (info != null && info.hasUpdate) {
      ref.read(availableUpdateProvider.notifier).setUpdate(info);

      try {
        final prefs = await SharedPreferences.getInstance();
        final lastNotified = prefs.getString(_prefLastNotifiedKey);

        if (forceSystemNotification || lastNotified != info.latestVersion) {
          final isId = AppLocale.code == 'id';
          final title = isId
              ? '🚀 Pembaruan Tersedia! (v${info.latestVersion})'
              : '🚀 Update Available! (v${info.latestVersion})';
          final body = isId
              ? 'Versi baru Wall o\' Pay telah rilis. Ketuk untuk download APK.'
              : 'A new version of Wall o\' Pay is ready. Tap to download APK.';
          final action = isId ? 'Unduh APK' : 'Download APK';

          await postSystemNotification(
            title: title,
            body: body,
            downloadUrl: info.downloadUrl,
            actionText: action,
          );

          await prefs.setString(_prefLastNotifiedKey, info.latestVersion);
        }
      } catch (e) {
        debugPrint('Error managing system notification persistence: $e');
      }
    }
    return info;
  }

  /// Memeriksa apakah ada pembaruan rilis terbaru di GitHub.
  static Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.getUrl(Uri.parse(_latestReleaseApi));
      request.headers.set('User-Agent', 'Wall-o-Pay-Android/$currentVersion');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close();
      if (response.statusCode != 200) {
        client.close();
        return null;
      }

      final body = await response.transform(utf8.decoder).join();
      client.close();

      final data = jsonDecode(body) as Map<String, dynamic>;
      final rawTag = (data['tag_name'] as String? ?? '').trim();
      final cleanTag = rawTag.startsWith('v') ? rawTag.substring(1) : rawTag;
      final releaseName = (data['name'] as String? ?? 'Wall o\' Pay $rawTag').trim();
      final releaseNotes = (data['body'] as String? ?? '').trim();
      final releasePageUrl = (data['html_url'] as String? ?? '').trim();

      // Cari URL download langsung untuk file Wall_o_Pay.apk
      var downloadUrl = _directDownloadUrl;
      final assets = data['assets'] as List<dynamic>?;
      if (assets != null) {
        for (final a in assets) {
          final assetName = a['name'] as String? ?? '';
          if (assetName == 'Wall_o_Pay.apk') {
            downloadUrl = a['browser_download_url'] as String? ?? downloadUrl;
            break;
          }
        }
      }

      final hasUpdate = _isVersionGreater(cleanTag, currentVersion);

      return AppUpdateInfo(
        currentVersion: currentVersion,
        latestVersion: cleanTag,
        releaseName: releaseName,
        releaseNotes: releaseNotes,
        downloadUrl: downloadUrl,
        releasePageUrl: releasePageUrl,
        hasUpdate: hasUpdate,
      );
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return null;
    }
  }

  /// Membandingkan dua nomor versi SemVer (misal "1.2.3" > "1.2.2").
  static bool _isVersionGreater(String remote, String current) {
    if (remote.isEmpty) return false;
    final rParts = remote.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final cParts = current.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    while (rParts.length < 3) {
      rParts.add(0);
    }
    while (cParts.length < 3) {
      cParts.add(0);
    }

    for (var i = 0; i < 3; i++) {
      if (rParts[i] > cParts[i]) return true;
      if (rParts[i] < cParts[i]) return false;
    }
    return false;
  }

  /// Memeriksa update dan langsung memunculkan dialog/snackbar.
  static Future<void> checkAndPromptUpdate(
    BuildContext context, {
    WidgetRef? ref,
    bool silentIfUpToDate = false,
  }) async {
    final info = await checkForUpdate();
    if (info != null && info.hasUpdate && ref != null) {
      await checkAndNotify(ref, forceSystemNotification: true);
    }
    if (!context.mounted) return;

    if (info != null && info.hasUpdate) {
      showUpdateDialog(context, info);
    } else if (!silentIfUpToDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('You are using the latest version ({version}).', {
              'version': 'v$currentVersion',
            }),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Menampilkan dialog pembaruan aplikasi modern.
  static void showUpdateDialog(BuildContext context, AppUpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.deepForest.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: AppColors.deepForest,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ctx.tr('Update Available!'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'v${info.currentVersion} ➔ v${info.latestVersion}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ctx.tr('A new version of Wall o\' Pay is ready with the latest improvements:'),
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              if (info.releaseNotes.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      info.releaseNotes,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                ctx.tr('Tap below to download and install the new APK.'),
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(ctx.tr('Later')),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(ctx.tr('Update Now')),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.deepForest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                openUrl(info.downloadUrl);
              },
            ),
          ],
        );
      },
    );
  }
}
