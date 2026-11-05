/// Layanan ekspor riwayat transaksi ke format CSV (kompatibel Excel) serta ekspor/impor
/// berkas cadangan penuh berformat JSON melalui menu bagikan (Share) sistem.
library;

import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/l10n.dart';
import 'app_database.dart';
import 'tables.dart' show TxType;

/// Ekspor transaksi ke CSV dan backup seluruh data ke JSON, lalu dibagikan
/// lewat menu share bawaan HP (simpan ke Drive, kirim ke WhatsApp, dll.).
class ExportService {
  ExportService(this._db);

  final AppDatabase _db;

  String _stamp() => DateFormat('yyyyMMdd_HHmm').format(DateTime.now());

  Future<void> shareCsv() async {
    final names = {for (final c in await _db.allCategories()) c.id: c.name};
    final rows = await _db.allActiveTransactions();
    final df = DateFormat('yyyy-MM-dd');

    final buf = StringBuffer('\uFEFF'); // BOM agar Excel membaca UTF-8
    buf.writeln('Date,Type,Category,Amount,Note');
    for (final t in rows) {
      buf.writeln([
        df.format(t.date),
        t.type == TxType.income ? 'Income' : (t.type == TxType.transfer ? 'Transfer' : 'Expense'),
        _csv(names[t.categoryId] ?? ''),
        t.amount,
        _csv(t.note),
      ].join(','));
    }
    await _share('wall_o_pay_transactions_${_stamp()}.csv', buf.toString());
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

  String _csv(String s) => '"${s.replaceAll('"', '""')}"';

  Future<void> _share(String fileName, String content) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: fileName),
    );
  }
}
