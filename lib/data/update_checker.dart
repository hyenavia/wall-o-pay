/// Layanan pemeriksa pembaruan versi aplikasi melalui GitHub Releases API
/// beserta dialog unduh APK rilis terbaru.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import 'lock.dart';

/// Data informasi rilis pembaruan aplikasi yang diperoleh dari GitHub Releases.
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
    NotifierProvider<AvailableUpdateNotifier, AppUpdateInfo?>(
      AvailableUpdateNotifier.new,
    );

class UpdateCheckerService {
  /// Versi fallback jika native method channel gagal membaca PackageManager.
  static const fallbackVersion = '3.4.1';
  static String _resolvedVersion = fallbackVersion;

  /// Versi aplikasi saat ini. Dinamis dibaca dari native PackageManager Android atau fallback.
  static String get currentVersion => _resolvedVersion;

  static const MethodChannel _channel = MethodChannel(
    'com.example.wall_o_pay/notifications',
  );

  /// Membaca versi terpasang langsung dari native Android PackageManager (versionName di pubspec.yaml).
  static Future<String> getInstalledVersion() async {
    try {
      final nativeVersion = await _channel.invokeMethod<String>('getAppVersion');
      if (nativeVersion != null && nativeVersion.isNotEmpty) {
        final clean = nativeVersion.split('+').first.trim();
        _resolvedVersion = clean;
        return clean;
      }
    } catch (e) {
      debugPrint('Failed to get native version: $e');
    }
    return _resolvedVersion;
  }

  /// Mengambil daftar ABI CPU yang didukung perangkat Android berdasarkan urutan prioritas.
  static Future<List<String>> getSupportedAbis() async {
    try {
      final abis = await _channel.invokeListMethod<String>('getSupportedAbis');
      if (abis != null) {
        return abis;
      }
    } catch (e) {
      debugPrint('Failed to get supported ABIs: $e');
    }
    return const [];
  }

  /// Memilih URL unduhan APK terbaik berdasarkan prioritas ABI perangkat.
  /// Mencocokkan aset `_*_<abi>.apk` terlebih dahulu, lalu fallback ke `Wall_o_Pay.apk`.
  static String selectBestApkDownloadUrl(
    List<dynamic>? assets,
    List<String> supportedAbis,
  ) {
    if (assets == null || assets.isEmpty) return _directDownloadUrl;

    for (final rawAbi in supportedAbis) {
      final abi = rawAbi.trim().toLowerCase();
      if (abi.isEmpty) continue;
      final suffix = '_$abi.apk';
      for (final a in assets) {
        if (a is! Map) continue;
        final assetName = (a['name'] as String? ?? '').toLowerCase();
        if (assetName.endsWith(suffix)) {
          final candidate = a['browser_download_url'] as String?;
          if (candidate != null && isTrustedReleaseUrl(candidate)) {
            return candidate;
          }
        }
      }
    }

    for (final a in assets) {
      if (a is! Map) continue;
      final assetName = a['name'] as String? ?? '';
      if (assetName == 'Wall_o_Pay.apk') {
        final candidate = a['browser_download_url'] as String?;
        if (candidate != null && isTrustedReleaseUrl(candidate)) {
          return candidate;
        }
        break;
      }
    }

    return _directDownloadUrl;
  }

  static const String _latestReleaseApi =
      'https://api.github.com/repos/hyenavia/wall-o-pay/releases/latest';
  static const String _directDownloadUrl =
      'https://github.com/hyenavia/wall-o-pay/releases/latest/download/Wall_o_Pay.apk';

  /// Memeriksa apakah URL unduhan pembaruan berasal dari repositori GitHub resmi melalui HTTPS.
  static bool isTrustedReleaseUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.scheme != 'https') return false;
    final host = uri.host.toLowerCase();
    if (host == 'github.com') {
      return uri.path.startsWith('/hyenavia/wall-o-pay/releases/');
    }
    if (host == 'objects.githubusercontent.com') {
      return true;
    }
    return false;
  }

  /// Membuka URL di browser atau installer eksternal via native intent.
  static Future<void> openUrl(String url) async {
    if (!isTrustedReleaseUrl(url)) {
      debugPrint('Blocked untrusted update URL: $url');
      return;
    }
    try {
      await _channel.invokeMethod('openUrl', {'url': url});
    } catch (e) {
      debugPrint('Failed to open URL via native: $e');
    }
  }

  static String? _promptedVersion;
  static bool _isShowingDialog = false;
  static VoidCallback? _pendingUnlockListener;

  /// Membatalkan listener pop-up pembaruan yang menunggu kunci dibuka
  /// agar tidak terjadi kebocoran listener atau menahan [BuildContext] yang sudah di-dispose.
  static void cancelPendingPrompt() {
    final existing = _pendingUnlockListener;
    if (existing != null) {
      Lock.instance.isLocked.removeListener(existing);
      _pendingUnlockListener = null;
    }
  }

  /// Memeriksa pembaruan dan otomatis memunculkan pop-up dialog ke pengguna jika ada rilis baru.
  static Future<AppUpdateInfo?> checkAndNotify(
    WidgetRef ref, {
    BuildContext? context,
  }) async {
    final info = await checkForUpdate();
    if (info != null && info.hasUpdate) {
      ref.read(availableUpdateProvider.notifier).setUpdate(info);

      if (context != null &&
          context.mounted &&
          _promptedVersion != info.latestVersion &&
          !_isShowingDialog) {
        // Jika aplikasi sedang terkunci dengan PIN, tunggu sampai pengguna selesai membuka kunci
        if (Lock.instance.isLocked.value) {
          cancelPendingPrompt();
          void listener() {
            if (!context.mounted) {
              cancelPendingPrompt();
              return;
            }
            if (!Lock.instance.isLocked.value) {
              cancelPendingPrompt();
              if (_promptedVersion != info.latestVersion && !_isShowingDialog) {
                _promptedVersion = info.latestVersion;
                showUpdateDialog(context, info);
              }
            }
          }

          _pendingUnlockListener = listener;
          Lock.instance.isLocked.addListener(listener);
        } else {
          _promptedVersion = info.latestVersion;
          showUpdateDialog(context, info);
        }
      }
    }
    return info;
  }

  /// Memeriksa apakah ada pembaruan rilis terbaru di GitHub.
  static Future<AppUpdateInfo?> checkForUpdate() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final installedVersion = await getInstalledVersion();
      final request = await client.getUrl(Uri.parse(_latestReleaseApi));
      request.headers.set('User-Agent', 'Wall-o-Pay-Android/$installedVersion');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close();
      if (response.statusCode != 200) {
        return null;
      }

      final body = await response.transform(utf8.decoder).join();

      final data = jsonDecode(body) as Map<String, dynamic>;
      final rawTag = (data['tag_name'] as String? ?? '').trim();
      final cleanTag = rawTag.startsWith('v') ? rawTag.substring(1) : rawTag;
      final releaseName = (data['name'] as String? ?? 'Wall o\' Pay $rawTag')
          .trim();
      final releaseNotes = (data['body'] as String? ?? '').trim();
      final releasePageUrl = (data['html_url'] as String? ?? '').trim();

      // Pilih URL download APK yang sesuai ABI perangkat (fallback ke Wall_o_Pay.apk)
      final assets = data['assets'] as List<dynamic>?;
      final supportedAbis = await getSupportedAbis();
      final downloadUrl = selectBestApkDownloadUrl(assets, supportedAbis);

      final hasUpdate = _isVersionGreater(cleanTag, installedVersion);

      return AppUpdateInfo(
        currentVersion: installedVersion,
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
    } finally {
      client.close();
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
      ref.read(availableUpdateProvider.notifier).setUpdate(info);
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
    if (_isShowingDialog) return;
    _isShowingDialog = true;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colors = ctx.themeColors;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.rocket_launch_rounded,
                  color: colors.primary,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'v${info.currentVersion} ➔ v${info.latestVersion}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
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
                ctx.tr(
                  'A new version of Wall o\' Pay is ready with the latest improvements:',
                ),
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              if (info.releaseNotes.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      info.releaseNotes,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.85,
                        ),
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
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                openUrl(info.downloadUrl);
              },
            ),
          ],
        );
      },
    ).then((_) {
      _isShowingDialog = false;
    });
  }
}
