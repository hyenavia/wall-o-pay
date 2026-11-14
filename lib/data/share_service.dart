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
  static final List<Map<String, dynamic>> _pendingQueue = [];
  static BuildContext? _activeContext;
  static bool _listenerRegistered = false;
  static bool _isDrainingQueue = false;

  /// Bernilai true jika masih ada aksi pintasan cepat (App Shortcut) Android di antrean.
  static bool get hasPendingShortcut =>
      _pendingQueue.any((d) => d['shortcutType'] != null);

  /// Jumlah item aksi yang sedang menunggu diproses (untuk diagnostik & testing).
  @visibleForTesting
  static int get pendingQueueLength => _pendingQueue.length;

  /// Mengosongkan antrean internal pada lingkungan pengujian unit.
  @visibleForTesting
  static void resetForTesting() {
    _pendingQueue.clear();
    _activeContext = null;
    _isDrainingQueue = false;
  }

  static void _ensureListenerRegistered() {
    if (_listenerRegistered) return;
    _listenerRegistered = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShareReceived') {
        final data = call.arguments;
        if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          _enqueue(map);
          _drainQueue();
          return true;
        }
      }
      return false;
    });

    // Jika aplikasi terkunci saat menerima Share Intent atau App Shortcut, proses setelah kunci dibuka.
    Lock.instance.isLocked.addListener(() {
      if (!Lock.instance.isLocked.value) {
        _drainQueue();
      }
    });
  }

  static Future<Map<String, dynamic>?> _consumeNativeSharedData() async {
    try {
      final res = await _channel.invokeMethod<Map>('consumeSharedData');
      if (res != null && res.isNotEmpty) {
        return Map<String, dynamic>.from(res);
      }
      return null;
    } on MissingPluginException {
      // Kompatibilitas mundur dengan mock channel lama pada test yang hanya mengimplementasikan getSharedData/clearSharedData.
      try {
        final res = await _channel.invokeMethod<Map>('getSharedData');
        if (res != null && res.isNotEmpty) {
          final map = Map<String, dynamic>.from(res);
          await _channel.invokeMethod('clearSharedData');
          return map;
        }
      } catch (_) {}
      return null;
    } catch (e) {
      debugPrint('[ShareService] Error checking shared data: $e');
      return null;
    }
  }

  static void _enqueue(Map<String, dynamic> map) {
    final incomingShortcut = map['shortcutType'];
    if (incomingShortcut != null &&
        _pendingQueue.isNotEmpty &&
        _pendingQueue.last['shortcutType'] == incomingShortcut) {
      return;
    }
    _pendingQueue.add(map);
  }

  /// Memeriksa data intent awal sebelum frame pertama di-render agar pintasan cepat
  /// dapat melewati layar splash tanpa melewati kunci PIN/biometrik.
  static Future<void> preloadInitialData() async {
    try {
      _ensureListenerRegistered();
      final data = await _consumeNativeSharedData();
      if (data != null && data.isNotEmpty) {
        _enqueue(data);
      }
    } catch (_) {}
  }

  static void initialize(BuildContext context, WidgetRef ref) {
    _activeContext = context;
    _ensureListenerRegistered();

    // Periksa data shortcut/share yang sudah di-preload atau intent baru saat HomeShell siap.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_activeContext != context || !context.mounted) return;
      if (_pendingQueue.isNotEmpty) {
        _drainQueue();
      } else {
        checkSharedData(context);
      }
    });
  }

  /// Melepas referensi [BuildContext] saat [HomeShell] di-dispose agar tidak menahan context lama.
  static void detachContext(BuildContext context) {
    if (identical(_activeContext, context)) {
      _activeContext = null;
    }
  }

  static Future<void> checkSharedData(BuildContext context) async {
    _activeContext = context;
    _ensureListenerRegistered();
    final data = await _consumeNativeSharedData();
    if (data != null && data.isNotEmpty) {
      _enqueue(data);
    }
    _drainQueue();
  }

  static void _drainQueue() {
    if (_isDrainingQueue) return;
    if (Lock.instance.isLocked.value) return;
    final ctx = _activeContext;
    if (ctx == null || !ctx.mounted) return;
    if (_pendingQueue.isEmpty) return;

    _isDrainingQueue = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        while (_pendingQueue.isNotEmpty) {
          if (Lock.instance.isLocked.value) break;
          final currentCtx = _activeContext;
          if (currentCtx == null || !currentCtx.mounted) break;

          final next = _pendingQueue.removeAt(0);
          await _processPayload(currentCtx, next);
        }
      } finally {
        _isDrainingQueue = false;
        Lock.instance.bypassForQuickAction.value = false;
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  static Future<void> _processPayload(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final shortcutType = data['shortcutType'] as String?;
    if (shortcutType != null) {
      final initialType = switch (shortcutType) {
        'income' => TxType.income,
        'transfer' => TxType.transfer,
        _ => TxType.expense,
      };
      if (!Lock.instance.isLocked.value && context.mounted) {
        await showTransactionForm(context, initialType: initialType);
      } else {
        _pendingQueue.insert(0, data);
      }
      return;
    }

    final imagePath = data['imagePath'] as String?;
    final text = data['text'] as String?;

    if (imagePath == null && (text == null || text.trim().isEmpty)) return;

    int? parsedAmount;
    TxType? parsedType;
    String? parsedCategoryId;
    String note = '';

    if (text != null && text.trim().isNotEmpty) {
      final parsed = TransactionParser.parseSharedText(text);
      parsedAmount = parsed.amount;
      parsedType = parsed.type;
      parsedCategoryId = parsed.categoryId;
      note = parsed.note;
    }

    if (imagePath != null && note.isEmpty) {
      note = 'Receipt';
    }

    String? validImagePath;
    if (imagePath != null && File(imagePath).existsSync()) {
      validImagePath = imagePath;
    }

    if (!Lock.instance.isLocked.value && context.mounted) {
      await showTransactionForm(
        context,
        initialType: parsedType,
        initialAmount: parsedAmount,
        initialCategoryId: parsedCategoryId,
        initialNote: note.trim(),
        initialReceiptPath: validImagePath,
      );
    } else {
      _pendingQueue.insert(0, data);
    }
  }
}
