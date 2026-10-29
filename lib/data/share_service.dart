import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auto_tracker.dart';
import 'lock.dart';
import '../features/transactions/transaction_form.dart';

class ShareService {
  static const _channel = MethodChannel('com.example.wall_o_pay/share');
  static Map<String, dynamic>? _pendingShareData;
  static bool _initialized = false;

  static void initialize(BuildContext context, WidgetRef ref) {
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShareReceived') {
        final data = call.arguments;
        if (data is Map) {
          _queueOrProcess(context, Map<String, dynamic>.from(data));
        }
      }
    });

    // Check on startup after initial frame is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        checkSharedData(context);
      }
    });

    // If locked, listen until user unlocks to process queued share
    Lock.instance.isLocked.addListener(() {
      if (!Lock.instance.isLocked.value && _pendingShareData != null) {
        final data = _pendingShareData!;
        _pendingShareData = null;
        if (context.mounted) {
          _openTransactionWithData(context, data);
        }
      }
    });
  }

  static Future<void> checkSharedData(BuildContext context) async {
    try {
      final res = await _channel.invokeMethod<Map>('getSharedData');
      if (res != null && res.isNotEmpty) {
        await _channel.invokeMethod('clearSharedData');
        if (context.mounted) {
          _queueOrProcess(context, Map<String, dynamic>.from(res));
        }
      }
    } catch (e) {
      debugPrint('[ShareService] Error checking shared data: $e');
    }
  }

  static void _queueOrProcess(BuildContext context, Map<String, dynamic> data) {
    if (Lock.instance.isLocked.value) {
      _pendingShareData = data;
    } else {
      _openTransactionWithData(context, data);
    }
  }

  static void _openTransactionWithData(BuildContext context, Map<String, dynamic> data) {
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

    // Verify image file exists if provided
    String? validImagePath;
    if (imagePath != null && File(imagePath).existsSync()) {
      validImagePath = imagePath;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        showTransactionForm(
          context,
          initialAmount: parsedAmount,
          initialNote: note.trim(),
          initialReceiptPath: validImagePath,
        );
      }
    });
  }
}

