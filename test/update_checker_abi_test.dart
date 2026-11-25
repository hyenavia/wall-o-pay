import 'package:flutter_test/flutter_test.dart';
import 'package:wall_o_pay/data/update_checker.dart';

void main() {
  const sampleAssets = [
    {
      'name': 'Wall_o_Pay.apk',
      'browser_download_url':
          'https://github.com/hyenavia/wall-o-pay/releases/download/v3.1.3/Wall_o_Pay.apk',
    },
    {
      'name': 'Wall_o_Pay_v3.1.3_arm64-v8a.apk',
      'browser_download_url':
          'https://github.com/hyenavia/wall-o-pay/releases/download/v3.1.3/Wall_o_Pay_v3.1.3_arm64-v8a.apk',
    },
    {
      'name': 'Wall_o_Pay_v3.1.3_armeabi-v7a.apk',
      'browser_download_url':
          'https://github.com/hyenavia/wall-o-pay/releases/download/v3.1.3/Wall_o_Pay_v3.1.3_armeabi-v7a.apk',
    },
    {
      'name': 'Wall_o_Pay_v3.1.3_x86_64.apk',
      'browser_download_url':
          'https://github.com/hyenavia/wall-o-pay/releases/download/v3.1.3/Wall_o_Pay_v3.1.3_x86_64.apk',
    },
  ];

  group('UpdateCheckerService.selectBestApkDownloadUrl', () {
    test('selects armeabi-v7a APK for 32-bit devices', () {
      final url = UpdateCheckerService.selectBestApkDownloadUrl(
        sampleAssets,
        ['armeabi-v7a'],
      );
      expect(url, endsWith('Wall_o_Pay_v3.1.3_armeabi-v7a.apk'));
    });

    test('selects arm64-v8a APK when prioritized in supportedAbis', () {
      final url = UpdateCheckerService.selectBestApkDownloadUrl(
        sampleAssets,
        ['arm64-v8a', 'armeabi-v7a'],
      );
      expect(url, endsWith('Wall_o_Pay_v3.1.3_arm64-v8a.apk'));
    });

    test('selects x86_64 APK for x86_64 emulators/tablets', () {
      final url = UpdateCheckerService.selectBestApkDownloadUrl(
        sampleAssets,
        ['x86_64', 'x86'],
      );
      expect(url, endsWith('Wall_o_Pay_v3.1.3_x86_64.apk'));
    });

    test('falls back to Wall_o_Pay.apk when supportedAbis is empty or unknown', () {
      expect(
        UpdateCheckerService.selectBestApkDownloadUrl(sampleAssets, const []),
        endsWith('/Wall_o_Pay.apk'),
      );
      expect(
        UpdateCheckerService.selectBestApkDownloadUrl(sampleAssets, ['mips']),
        endsWith('/Wall_o_Pay.apk'),
      );
    });

    test('ignores untrusted release URLs and falls back safely', () {
      final untrustedAssets = [
        {
          'name': 'Wall_o_Pay_v3.1.3_armeabi-v7a.apk',
          'browser_download_url': 'https://evil.example.com/malware.apk',
        },
        {
          'name': 'Wall_o_Pay.apk',
          'browser_download_url':
              'https://github.com/hyenavia/wall-o-pay/releases/download/v3.1.3/Wall_o_Pay.apk',
        },
      ];
      final url = UpdateCheckerService.selectBestApkDownloadUrl(
        untrustedAssets,
        ['armeabi-v7a'],
      );
      expect(
        url,
        'https://github.com/hyenavia/wall-o-pay/releases/download/v3.1.3/Wall_o_Pay.apk',
      );
    });
  });
}
