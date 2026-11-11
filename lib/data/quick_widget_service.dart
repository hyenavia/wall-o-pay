/// Layanan jembatan sinkronisasi data antara aplikasi Flutter dan
/// Quick Finance Android Home Screen Widget melalui MethodChannel.
/// Mengirimkan total saldo, status sensor privasi, bahasa aktif ke native Android,
/// serta mendeteksi transaksi yang dicatat langsung dari widget agar UI Flutter segera terbarui.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n.dart';
import 'prefs.dart';
import 'providers.dart';

/// Channel komunikasi ke native Android untuk sinkronisasi data widget.
const _widgetChannel = MethodChannel('com.example.wall_o_pay/widget');

/// Mengirimkan data saldo, status sensor, dan bahasa ke Quick Finance Widget.
/// Dipanggil setiap kali total saldo, status sensor, atau bahasa berubah.
Future<void> syncWidgetData(WidgetRef ref) async {
  try {
    final hideBalance = ref.read(hideBalanceProvider);
    final totalBalance = hideBalance ? 0 : ref.read(totalCurrentBalanceProvider);
    final locale = ref.read(appPrefsProvider).localeCode;
    await _widgetChannel.invokeMethod('updateWidgetData', {
      'balance': totalBalance,
      'hideBalance': hideBalance,
      'locale': locale,
    });
  } catch (e) {
    debugPrint('[QuickWidgetService] Failed to sync widget data: $e');
  }
}

/// Mengirimkan data saldo dan status sensor ke widget tanpa WidgetRef.
Future<void> syncWidgetDataDirect({
  required int totalBalance,
  required bool hideBalance,
  String? locale,
}) async {
  try {
    await _widgetChannel.invokeMethod('updateWidgetData', {
      'balance': hideBalance ? 0 : totalBalance,
      'hideBalance': hideBalance,
      'locale': locale ?? AppLocale.code,
    });
  } catch (e) {
    debugPrint('[QuickWidgetService] Failed to sync widget data: $e');
  }
}

/// Memeriksa apakah widget/dialog native baru saja menulis transaksi ke SQLite
/// saat aplikasi di latar belakang. Jika ya, beri tahu Drift untuk memicu pembaruan stream & sync.
Future<bool> checkNativeWidgetDbDirty(WidgetRef ref) async {
  try {
    final dirty = await _widgetChannel.invokeMethod<bool>('consumeNativeDbDirty');
    if (dirty == true) {
      final db = ref.read(databaseProvider);
      db.markTablesUpdated({db.transactions});
      return true;
    }
  } catch (e) {
    debugPrint('[QuickWidgetService] Failed to check native DB dirty flag: $e');
  }
  return false;
}
