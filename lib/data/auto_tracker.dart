import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'providers.dart';
import 'tables.dart';

/// MethodChannel untuk komunikasi dengan Android Native Notification Listener Service.
const _channel = MethodChannel('com.example.wall_o_pay/notifications');

class ParsedNotification {
  const ParsedNotification({
    required this.amount,
    required this.type,
    required this.sourceApp,
    required this.rawText,
    this.suggestedCategoryId,
    this.suggestedCategoryName,
    required this.note,
    required this.timestamp,
  });

  final int amount;
  final TxType type;
  final String sourceApp;
  final String rawText;
  final String? suggestedCategoryId;
  final String? suggestedCategoryName;
  final String note;
  final DateTime timestamp;
}

class TransactionParser {
  /// Ekstrak nominal uang dalam format Rupiah (contoh: "Rp 25.000", "Rp25.000,00", "IDR 50.000").
  static int? extractAmount(String text) {
    // Cari pola Rp atau IDR diikuti angka
    final regex = RegExp(
      r'(?:Rp|IDR)\s*([0-9]{1,3}(?:\.[0-9]{3})*(?:,[0-9]{1,2})?|[0-9]+)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    if (match == null) return null;

    var numStr = match.group(1)!;
    // Hilangkan desimal koma (misal: ,00)
    if (numStr.contains(',')) {
      numStr = numStr.split(',')[0];
    }
    // Hilangkan titik ribuan
    numStr = numStr.replaceAll('.', '').trim();
    return int.tryParse(numStr);
  }

  /// Deteksi nama aplikasi bank/e-wallet berdasarkan teks atau package.
  static String detectSourceApp(String text, {String? packageName, String? title}) {
    final lower = '${title ?? ''} $text ${packageName ?? ''}'.toLowerCase();

    if (lower.contains('gopay') || lower.contains('gojek')) return 'GoPay';
    if (lower.contains('bca') || lower.contains('mybca')) return 'BCA';
    if (lower.contains('mandiri') || lower.contains('livin')) return "Livin' Mandiri";
    if (lower.contains('brimo') || lower.contains('bri')) return 'BRImo';
    if (lower.contains('dana')) return 'DANA';
    if (lower.contains('ovo')) return 'OVO';
    if (lower.contains('shopeepay') || lower.contains('shopee')) return 'ShopeePay';
    if (lower.contains('bni')) return 'BNI Mobile';

    return 'Bank / E-Wallet';
  }

  /// Deteksi tipe transaksi (Pemasukan vs Pengeluaran).
  static TxType detectType(String text) {
    final lower = text.toLowerCase();
    
    // Kata kunci pemasukan
    if (lower.contains('masuk') ||
        lower.contains('menerima') ||
        lower.contains('received') ||
        lower.contains('terima uang') ||
        lower.contains('transfer masuk') ||
        lower.contains('top up berhasil') ||
        lower.contains('kredit')) {
      return TxType.income;
    }

    // Default mayoritas notifikasi transaksi adalah pengeluaran
    return TxType.expense;
  }

  /// Menebak kategori pengeluaran berdasarkan nama toko/merchant atau kata kunci.
  static (String id, String name)? suggestCategory(String text, TxType type) {
    if (type == TxType.income) {
      return ('cat-inc-other', 'Other');
    }

    final lower = text.toLowerCase();

    // Makanan & Minuman
    if (lower.contains('kopi') ||
        lower.contains('coffee') ||
        lower.contains('cafe') ||
        lower.contains('kafe') ||
        lower.contains('resto') ||
        lower.contains('makan') ||
        lower.contains('food') ||
        lower.contains('gofood') ||
        lower.contains('shopeefood') ||
        lower.contains('grabfood') ||
        lower.contains('bakso') ||
        lower.contains('ayam') ||
        lower.contains('mie') ||
        lower.contains('boba') ||
        lower.contains('tea') ||
        lower.contains('martabak') ||
        lower.contains('burger') ||
        lower.contains('pizza')) {
      return ('cat-exp-food', 'Food & Drinks');
    }

    // Transportasi
    if (lower.contains('goride') ||
        lower.contains('gocar') ||
        lower.contains('grabride') ||
        lower.contains('grabcar') ||
        lower.contains('ojek') ||
        lower.contains('taksi') ||
        lower.contains('taxi') ||
        lower.contains('bensin') ||
        lower.contains('spbu') ||
        lower.contains('pertamina') ||
        lower.contains('shell') ||
        lower.contains('tol') ||
        lower.contains('parkir') ||
        lower.contains('kereta') ||
        lower.contains('krl') ||
        lower.contains('mrt')) {
      return ('cat-exp-transport', 'Transport');
    }

    // Belanja & Kebutuhan
    if (lower.contains('indomaret') ||
        lower.contains('alfamart') ||
        lower.contains('alfamidi') ||
        lower.contains('superindo') ||
        lower.contains('shopee') ||
        lower.contains('tokopedia') ||
        lower.contains('lazada') ||
        lower.contains('belanja') ||
        lower.contains('mart')) {
      return ('cat-exp-shopping', 'Shopping');
    }

    // Tagihan & Rumah Tangga
    if (lower.contains('pln') ||
        lower.contains('listrik') ||
        lower.contains('pdam') ||
        lower.contains('air') ||
        lower.contains('wifi') ||
        lower.contains('indihome') ||
        lower.contains('biznet') ||
        lower.contains('bpjs') ||
        lower.contains('kos') ||
        lower.contains('kontrakan') ||
        lower.contains('tagihan')) {
      return ('cat-exp-housing', 'Rent & Bills');
    }

    // Hiburan
    if (lower.contains('cinema') ||
        lower.contains('xxi') ||
        lower.contains('cgv') ||
        lower.contains('bioskop') ||
        lower.contains('netflix') ||
        lower.contains('spotify') ||
        lower.contains('game') ||
        lower.contains('steam') ||
        lower.contains('playstation')) {
      return ('cat-exp-fun', 'Entertainment');
    }

    // Kesehatan
    if (lower.contains('apotek') ||
        lower.contains('kimia farma') ||
        lower.contains('k24') ||
        lower.contains('obat') ||
        lower.contains('dokter') ||
        lower.contains('klinik') ||
        lower.contains('rs') ||
        lower.contains('rumah sakit')) {
      return ('cat-exp-health', 'Health');
    }

    return ('cat-exp-other', 'Other');
  }

  /// Ekstrak nama merchant atau catatan singkat dari teks notifikasi.
  static String extractMerchantNote(String text, String sourceApp) {
    // Pola umum: "...di/ke [Nama Merchant]..."
    final match = RegExp(
      r'(?:di|ke|merchant|pembayaran)\s+([A-Za-z0-9\s\.\-_&]{3,30}?)(?:\s+berhasil|\s+sukses|\s+sebesar|\.|$)',
      caseSensitive: false,
    ).firstMatch(text);

    if (match != null && match.group(1) != null) {
      final merchant = match.group(1)!.trim();
      if (merchant.isNotEmpty && merchant.length > 2) {
        return merchant;
      }
    }

    return 'Transaksi $sourceApp';
  }

  /// Parser lengkap untuk membedah teks notifikasi bank/e-wallet.
  static ParsedNotification? parse({
    required String text,
    String? title,
    String? packageName,
    DateTime? timestamp,
  }) {
    final amount = extractAmount(text) ?? (title != null ? extractAmount(title) : null);
    if (amount == null || amount <= 0) return null;

    final sourceApp = detectSourceApp(text, packageName: packageName, title: title);
    final type = detectType(text);
    final cat = suggestCategory(text, type);
    final note = extractMerchantNote(text, sourceApp);

    return ParsedNotification(
      amount: amount,
      type: type,
      sourceApp: sourceApp,
      rawText: text,
      suggestedCategoryId: cat?.$1,
      suggestedCategoryName: cat?.$2,
      note: note,
      timestamp: timestamp ?? DateTime.now(),
    );
  }
}

/// Service untuk menangani sinkronisasi notifikasi latar belakang dan konfirmasi pengguna.
class AutoTrackerService {
  AutoTrackerService(this._db);

  final AppDatabase _db;

  /// Periksa apakah izin Notification Access di Android sudah diberikan.
  static Future<bool> isNotificationAccessGranted() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final granted = await _channel.invokeMethod<bool>('isNotificationAccessGranted');
      return granted ?? false;
    } catch (e) {
      debugPrint('Error checking notification access: $e');
      return false;
    }
  }

  /// Buka menu pengaturan Android agar pengguna dapat mengaktifkan Notification Access.
  static Future<void> openNotificationSettings() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } catch (e) {
      debugPrint('Error opening notification settings: $e');
    }
  }

  /// Buka halaman Info Aplikasi Wall o' Pay di Setelan HP Android
  /// agar pengguna dapat langsung mengizinkan "Setelan Terbatas" (Restricted Settings).
  static Future<void> openAppSettings() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (e) {
      debugPrint('Error opening app details settings: $e');
    }
  }

  /// Buka URL di browser bawaan perangkat (misal tautan unduh APK rilis terbaru).
  static Future<void> openUrl(String url) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('openUrl', {'url': url});
    } catch (e) {
      debugPrint('Error opening URL: $e');
    }
  }

  /// Tarik notifikasi yang ditangkap oleh Android Service di background,
  /// parsing, dan masukkan ke tabel PendingTransactions.
  Future<int> syncPendingFromNative() async {
    if (defaultTargetPlatform != TargetPlatform.android) return 0;
    try {
      final rawList = await _channel.invokeMethod<List<dynamic>>('getPendingNotifications');
      if (rawList == null || rawList.isEmpty) return 0;

      var count = 0;
      for (final item in rawList) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final text = (map['text'] ?? '').toString();
        final title = (map['title'] ?? '').toString();
        final pkg = (map['package'] ?? '').toString();
        final timeMs = map['timestamp'] as int?;
        final time = timeMs != null
            ? DateTime.fromMillisecondsSinceEpoch(timeMs)
            : DateTime.now();

        final parsed = TransactionParser.parse(
          text: text,
          title: title,
          packageName: pkg,
          timestamp: time,
        );

        if (parsed != null) {
          await _db.insertPendingTransaction(
            PendingTransactionsCompanion.insert(
              amount: parsed.amount,
              type: parsed.type,
              sourceApp: parsed.sourceApp,
              rawNotification: parsed.rawText,
              suggestedCategory: Value(parsed.suggestedCategoryId),
              note: Value(parsed.note),
              date: parsed.timestamp,
            ),
          );
          count++;
        }
      }

      await _channel.invokeMethod('clearPendingNotifications');
      return count;
    } catch (e) {
      debugPrint('Error syncing pending notifications: $e');
      return 0;
    }
  }

  /// Simulasi notifikasi bank untuk pengetesan langsung di aplikasi.
  Future<void> simulateNotification({
    required String sourceApp,
    required String text,
  }) async {
    final parsed = TransactionParser.parse(
      text: text,
      title: sourceApp,
      packageName: 'com.simulator.$sourceApp',
      timestamp: DateTime.now(),
    );

    if (parsed != null) {
      await _db.insertPendingTransaction(
        PendingTransactionsCompanion.insert(
          amount: parsed.amount,
          type: parsed.type,
          sourceApp: parsed.sourceApp,
          rawNotification: parsed.rawText,
          suggestedCategory: Value(parsed.suggestedCategoryId),
          note: Value(parsed.note),
          date: parsed.timestamp,
        ),
      );
    }
  }

  /// Konfirmasi transaksi pending dan masukkan ke buku transaksi utama.
  Future<void> confirmPending({
    required PendingTransaction pending,
    required String categoryId,
    required int amount,
    required TxType type,
    required String note,
    required DateTime date,
  }) async {
    await _db.into(_db.transactions).insert(
      TransactionsCompanion.insert(
        amount: amount,
        type: type,
        categoryId: categoryId,
        note: Value(note),
        date: date,
      ),
    );
    await _db.deletePendingTransaction(pending.id);
  }

  /// Tolak / abaikan transaksi pending tanpa mengubah saldo.
  Future<void> dismissPending(String id) async {
    await _db.deletePendingTransaction(id);
  }
}

final autoTrackerServiceProvider = Provider<AutoTrackerService>((ref) {
  final db = ref.watch(databaseProvider);
  return AutoTrackerService(db);
});
