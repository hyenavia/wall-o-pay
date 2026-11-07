/// Layanan penerima kiriman teks/gambar bukti transaksi (Share Intent) serta
/// pintasan cepat ikon beranda Android (App Shortcuts) melalui MethodChannel,
/// lalu mengarahkannya langsung ke form input transaksi.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lock.dart';
import 'tables.dart' show TxType;
import 'transaction_parser.dart';
import '../features/transactions/transaction_form.dart';

/// Kelas penghubung penerima data Share Intent & App Shortcuts Android dengan form transaksi.
class ShareService {
  static const _channel = MethodChannel('com.example.wall_o_pay/share');
  static Map<String, dynamic>? _pendingShareData;
  static Map<String, dynamic>? _preloadedShortcutData;
  static BuildContext? _activeContext;
  static bool _listenerRegistered = false;
  static bool _isOpeningShortcut = false;

  /// Bernilai true jika aplikasi dibuka melalui pintasan cepat (App Shortcut) Android.
  static bool get hasPendingShortcut =>
      _preloadedShortcutData != null && _preloadedShortcutData!['shortcutType'] != null;

  /// Memeriksa data intent awal sebelum frame pertama di-render agar pintasan cepat
  /// dapat melewati splash screen dan tidak memicu popup biometrik otomatis.
  static Future<void> preloadInitialData() async {
    try {
      final res = await _channel.invokeMethod<Map>('getSharedData');
      if (res != null && res.isNotEmpty) {
        final data = Map<String, dynamic>.from(res);
        if (data['shortcutType'] != null) {
          await _channel.invokeMethod('clearSharedData');
          _preloadedShortcutData = data;
          Lock.instance.bypassForQuickAction.value = true;
        }
      }
    } catch (_) {}
  }

  static void initialize(BuildContext context, WidgetRef ref) {
    _activeContext = context;

    if (!_listenerRegistered) {
      _listenerRegistered = true;

      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onShareReceived') {
          final data = call.arguments;
          if (data is Map) {
            final map = Map<String, dynamic>.from(data);
            if (map['shortcutType'] != null) {
              Lock.instance.bypassForQuickAction.value = true;
            }
            await _channel.invokeMethod('clearSharedData');
            final ctx = _activeContext;
            if (ctx != null && ctx.mounted) {
              _queueOrProcess(ctx, map);
            } else {
              _preloadedShortcutData = map;
            }
          }
        }
      });

      // Jika aplikasi terkunci saat menerima Share Intent biasa, proses setelah kunci dibuka.
      Lock.instance.isLocked.addListener(() {
        if (!Lock.instance.isLocked.value && _pendingShareData != null) {
          final data = _pendingShareData!;
          _pendingShareData = null;
          final ctx = _activeContext;
          if (ctx != null && ctx.mounted) {
            _openTransactionWithData(ctx, data);
          }
        }
      });
    }

    // Periksa data shortcut yang sudah di-preload atau share intent saat startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _activeContext;
      if (ctx == null || !ctx.mounted) return;
      if (_preloadedShortcutData != null) {
        final data = _preloadedShortcutData!;
        _preloadedShortcutData = null;
        _openTransactionWithData(ctx, data);
      } else {
        checkSharedData(ctx);
      }
    });
  }

  static Future<void> checkSharedData(BuildContext context) async {
    _activeContext = context;
    if (_preloadedShortcutData != null) {
      final data = _preloadedShortcutData!;
      _preloadedShortcutData = null;
      if (context.mounted) {
        _openTransactionWithData(context, data);
      }
      return;
    }
    try {
      final res = await _channel.invokeMethod<Map>('getSharedData');
      if (res != null && res.isNotEmpty) {
        final map = Map<String, dynamic>.from(res);
        if (map['shortcutType'] != null) {
          Lock.instance.bypassForQuickAction.value = true;
        }
        await _channel.invokeMethod('clearSharedData');
        if (context.mounted) {
          _queueOrProcess(context, map);
        }
      }
    } catch (e) {
      debugPrint('[ShareService] Error checking shared data: $e');
    }
  }

  static void _queueOrProcess(BuildContext context, Map<String, dynamic> data) {
    // Pintasan cepat (App Shortcuts) langsung membuka form tanpa perlu buka kunci PIN/biometrik.
    if (data['shortcutType'] != null) {
      _openTransactionWithData(context, data);
      return;
    }
    if (Lock.instance.isLocked.value) {
      _pendingShareData = data;
    } else {
      _openTransactionWithData(context, data);
    }
  }

  static void _openTransactionWithData(BuildContext context, Map<String, dynamic> data) {
    final shortcutType = data['shortcutType'] as String?;
    if (shortcutType != null) {
      if (_isOpeningShortcut) return;
      _isOpeningShortcut = true;
      Lock.instance.bypassForQuickAction.value = true;
      final initialType = switch (shortcutType) {
        'income' => TxType.income,
        'transfer' => TxType.transfer,
        _ => TxType.expense,
      };
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final ctx = _activeContext ?? context;
          if (ctx.mounted) {
            await showTransactionForm(ctx, initialType: initialType);
          }
        } finally {
          _isOpeningShortcut = false;
          Lock.instance.bypassForQuickAction.value = false;
        }
      });
      return;
    }

    final imagePath = data['imagePath'] as String?;
    final text = data['text'] as String?;

    if (imagePath == null && (text == null || text.trim().isEmpty)) return;

    int? parsedAmount;
    String note = '';

    if (text != null && text.trim().isNotEmpty) {
      parsedAmount = TransactionParser.extractAmount(text);
      final detectedSource = TransactionParser.detectSourceApp(text);
      note = detectedSource.isNotEmpty ? '[$detectedSource] $text' : text;
    }

    if (imagePath != null && note.isEmpty) {
      note = 'Receipt';
    }

    String? validImagePath;
    if (imagePath != null && File(imagePath).existsSync()) {
      validImagePath = imagePath;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _activeContext ?? context;
      if (ctx.mounted) {
        showTransactionForm(
          ctx,
          initialAmount: parsedAmount,
          initialNote: note.trim(),
          initialReceiptPath: validImagePath,
        );
      }
    });
  }
}
