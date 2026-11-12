/// Layanan ekspor riwayat transaksi ke format CSV (kompatibel Excel) serta ekspor/impor
/// berkas cadangan penuh berformat JSON melalui menu bagikan (Share) sistem.
library;

import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/l10n.dart';
import 'app_database.dart';
import 'tables.dart' show NeedWant, TxType;

/// Key SharedPreferences untuk mencatat waktu backup JSON manual terakhir.
const kLastJsonBackupMsKey = 'last_json_backup_ms';

/// Key SharedPreferences untuk menyembunyikan sementara banner pengingat backup Mode Tamu.
const kGuestBackupNudgeDismissedAtMsKey = 'guest_backup_nudge_dismissed_ms';

/// Ekspor transaksi ke CSV dan backup seluruh data ke JSON, lalu dibagikan
/// lewat menu share bawaan HP (simpan ke Drive, kirim ke WhatsApp, dll.).
class ExportService {
  ExportService(this._db);

  final AppDatabase _db;

  String _stamp() => DateFormat('yyyyMMdd_HHmm').format(DateTime.now());

  /// Menentukan apakah pengguna Mode Tamu perlu diingatkan untuk membuat backup JSON lokal.
  static bool shouldShowGuestBackupNudge({
    required bool isGuest,
    required int txCount,
    required int? lastBackupMs,
    int? dismissedAtMs,
    required DateTime now,
    int minTxCount = 10,
    int staleDays = 14,
  }) {
    if (!isGuest || txCount < minTxCount) return false;
    final cutoffMs =
        now.subtract(Duration(days: staleDays)).millisecondsSinceEpoch;
    if (dismissedAtMs != null && dismissedAtMs > cutoffMs) {
      return false;
    }
    if (lastBackupMs == null || lastBackupMs <= 0) return true;
    return lastBackupMs <= cutoffMs;
  }

  /// Menyaring transaksi berdasarkan rentang tanggal inklusif ([range]) dan/atau [walletId].
  static List<TransactionEntry> filterTransactionsForExport({
    required List<TransactionEntry> rows,
    DateTimeRange? range,
    String? walletId,
  }) {
    final DateTime? start = range == null
        ? null
        : DateTime(range.start.year, range.start.month, range.start.day);
    final DateTime? endExclusive = range == null
        ? null
        : DateTime(range.end.year, range.end.month, range.end.day + 1);

    return rows.where((t) {
      if (start != null && t.date.isBefore(start)) return false;
      if (endExclusive != null && !t.date.isBefore(endExclusive)) return false;
      if (walletId != null &&
          t.walletId != walletId &&
          t.toWalletId != walletId) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Membentuk konten string CSV ber-BOM UTF-8 dengan kolom lengkap dan filter opsional.
  static String buildCsvContent({
    required List<TransactionEntry> rows,
    required Map<String, Category> categories,
    required Map<String, Wallet> wallets,
    DateTimeRange? range,
    String? walletId,
  }) {
    final filtered = filterTransactionsForExport(
      rows: rows,
      range: range,
      walletId: walletId,
    );
    final df = DateFormat('yyyy-MM-dd');
    final buf = StringBuffer('\uFEFF'); // BOM agar Excel membaca UTF-8
    buf.writeln('Date,Type,Category,Wallet,ToWallet,NeedWant,Amount,Note');

    for (final t in filtered) {
      final typeLabel = switch (t.type) {
        TxType.income => 'Income',
        TxType.transfer => 'Transfer',
        TxType.expense => 'Expense',
      };
      final catName = categories[t.categoryId]?.name ?? '';
      final walletName = wallets[t.walletId ?? 'wallet-main']?.name ?? '';
      final toWalletName =
          t.toWalletId != null ? (wallets[t.toWalletId!]?.name ?? '') : '';
      final needWantLabel = switch (t.needWant) {
        NeedWant.need => 'Need',
        NeedWant.want => 'Want',
        null => '',
      };

      buf.writeln([
        df.format(t.date),
        typeLabel,
        _csvEscape(catName),
        _csvEscape(walletName),
        _csvEscape(toWalletName),
        needWantLabel,
        t.amount,
        _csvEscape(t.note),
      ].join(','));
    }
    return buf.toString();
  }

  /// Mengekspor transaksi ke file CSV dan mengembalikan jumlah baris transaksi yang diekspor.
  Future<int> shareCsv({
    DateTimeRange? range,
    String? walletId,
  }) async {
    final catMap = {for (final c in await _db.allCategories()) c.id: c};
    final walletMap = {for (final w in await _db.watchWallets().first) w.id: w};
    final allRows = await _db.allActiveTransactions();
    final filtered = filterTransactionsForExport(
      rows: allRows,
      range: range,
      walletId: walletId,
    );
    final content = buildCsvContent(
      rows: filtered,
      categories: catMap,
      wallets: walletMap,
    );
    await _share('wall_o_pay_transactions_${_stamp()}.csv', content);
    return filtered.length;
  }

  Future<void> shareBackup({
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? budgetConfig,
  }) async {
    final data = await _db.exportBackup(
      preferences: preferences,
      budgetConfig: budgetConfig,
    );
    final json = const JsonEncoder.withIndent('  ').convert(data);
    await _share('wall_o_pay_backup_${_stamp()}.json', json);
  }

  /// Pilih file backup JSON dari penyimpanan, lalu gabungkan ke data lokal.
  /// Mengembalikan pesan hasil untuk ditampilkan ke pengguna.
  Future<String> importBackupFile({
    Future<void> Function(Map<String, dynamic> preferences)? onImportPreferences,
    Future<void> Function(Map<String, dynamic> budgetConfig)? onImportBudgetConfig,
  }) async {
    final file = await openFile();
    if (file == null) return trG('Import cancelled.');
    try {
      final data = jsonDecode(await file.readAsString());
      if (data is! Map<String, dynamic>) {
        throw const FormatException("This is not a Wall o' Pay backup file.");
      }
      final n = await _db.importBackup(data);
      var configImported = false;
      if (data['preferences'] is Map<String, dynamic>) {
        await onImportPreferences?.call(data['preferences'] as Map<String, dynamic>);
        configImported = true;
      }
      if (data['budgetConfig'] is Map<String, dynamic>) {
        await onImportBudgetConfig?.call(data['budgetConfig'] as Map<String, dynamic>);
        configImported = true;
      }
      if (n == 0 && !configImported) return trG('Backup file read. Nothing new to add.');
      if (n == 0 && configImported) return trG('Settings and budget configuration imported.');
      return n == 1
          ? trG('Imported 1 item from the backup file.')
          : trG('Imported {n} items from the backup file.', {'n': n});
    } on FormatException catch (e) {
      return trG('Import failed: {error}', {'error': trG(e.message)});
    }
  }

  static String _csvEscape(String s) => '"${s.replaceAll('"', '""')}"';

  Future<void> _share(String fileName, String content) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content);
    try {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: fileName),
      );
    } finally {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }
}
