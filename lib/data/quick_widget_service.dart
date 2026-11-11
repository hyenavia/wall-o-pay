/// Layanan jembatan sinkronisasi data antara aplikasi Flutter dan
/// Quick Finance Android Home Screen Widget melalui MethodChannel.
/// Mengirimkan total saldo dan status sensor privasi ke native Android
/// agar widget selalu menampilkan data terkini.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Channel komunikasi ke native Android untuk sinkronisasi data widget.
const _widgetChannel = MethodChannel('com.example.wall_o_pay/widget');

/// Mengirimkan data saldo dan status sensor ke Quick Finance Widget.
/// Dipanggil setiap kali total saldo atau status sensor berubah.
Future<void> syncWidgetData(WidgetRef ref) async {
  try {
    final totalBalance = ref.read(totalCurrentBalanceProvider);
    final hideBalance = ref.read(hideBalanceProvider);
    await _widgetChannel.invokeMethod('updateWidgetData', {
      'balance': totalBalance,
      'hideBalance': hideBalance,
    });
  } catch (e) {
    debugPrint('[QuickWidgetService] Failed to sync widget data: $e');
  }
}

/// Mengirimkan data saldo dan status sensor ke widget tanpa WidgetRef.
/// Digunakan saat lifecycle `didChangeAppLifecycleState`.
Future<void> syncWidgetDataDirect({
  required int totalBalance,
  required bool hideBalance,
}) async {
  try {
    await _widgetChannel.invokeMethod('updateWidgetData', {
      'balance': totalBalance,
      'hideBalance': hideBalance,
    });
  } catch (e) {
    debugPrint('[QuickWidgetService] Failed to sync widget data: $e');
  }
}

