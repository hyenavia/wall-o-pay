import 'dart:io';

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../core/format.dart';
import '../core/l10n.dart';
import 'app_database.dart';
import 'tables.dart' show NeedWant, TxType;

/// Membuat laporan PDF untuk rentang tanggal tertentu lalu membagikannya.
class ReportService {
  ReportService(this._db);

  final AppDatabase _db;

  /// [range.end] bersifat inklusif (hari terakhir yang ikut dihitung).
  Future<void> shareReport(DateTimeRange range) async {
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day + 1);
    final txs = await _db.transactionsBetween(start, end);
    final cats = {for (final cat in await _db.allCategories()) cat.id: cat};
    final wallets = {for (final w in await _db.watchWallets().first) w.id: w};

    String catName(String id) => trG(cats[id]?.name ?? 'Uncategorized');
    String walletName(String? id) =>
        trG(wallets[id ?? 'wallet-main']?.name ?? 'Wallet');

    final income = txs.where((t) => t.type == TxType.income).fold<int>(0, (s, t) => s + t.amount);
    final expense = txs.where((t) => t.type == TxType.expense).fold<int>(0, (s, t) => s + t.amount);

    final byCat = <String, int>{};
    var need = 0, want = 0;
    for (final t in txs.where((t) => t.type == TxType.expense)) {
      byCat[t.categoryId] = (byCat[t.categoryId] ?? 0) + t.amount;
      if (t.needWant == NeedWant.need) need += t.amount;
      if (t.needWant == NeedWant.want) want += t.amount;
    }
    final catRows = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final doc = pw.Document();
    final df = DateFormat('d MMM yyyy', AppLocale.code);
    final cell = const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4);

    pw.Widget c(String text, {bool bold = false, bool right = false}) => pw.Padding(
          padding: cell,
          child: pw.Align(
            alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        );

    pw.Widget h(String text) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
          child: pw.Text(text,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        );

    pw.TableRow headRow(List<String> labels, {int rightFrom = 99}) => pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            for (var i = 0; i < labels.length; i++)
              c(labels[i], bold: true, right: i >= rightFrom),
          ],
        );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          pw.Text("Wall o' Pay",
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text(trG('Financial report'), style: const pw.TextStyle(fontSize: 12)),
          pw.Text('${df.format(start)} - ${df.format(range.end)}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          h(trG('Summary')),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(2)},
            children: [
              pw.TableRow(children: [c(trG('Income')), c(rupiah(income), right: true)]),
              pw.TableRow(children: [c(trG('Expense')), c(rupiah(expense), right: true)]),
              pw.TableRow(children: [
                c(trG('Balance'), bold: true),
                c(rupiah(income - expense), bold: true, right: true),
              ]),
            ],
          ),
          if (catRows.isNotEmpty) ...[
            h(trG('Spending by category')),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1),
              },
              children: [
                headRow([trG('Category'), trG('Amount'), '%'], rightFrom: 1),
                for (final e in catRows)
                  pw.TableRow(children: [
                    c(catName(e.key)),
                    c(rupiah(e.value), right: true),
                    c('${expense == 0 ? 0 : (e.value * 100 / expense).round()}%', right: true),
                  ]),
              ],
            ),
          ],
          if (need + want > 0) ...[
            h(trG('Needs vs wants')),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              children: [
                pw.TableRow(children: [c(trG('Needs')), c(rupiah(need), right: true)]),
                pw.TableRow(children: [c(trG('Wants')), c(rupiah(want), right: true)]),
              ],
            ),
          ],
          h(trG('Transactions')),
          if (txs.isEmpty)
            pw.Text(trG('No transactions in this period.'),
                style: const pw.TextStyle(fontSize: 10))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2.4),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(2.4),
              },
              children: [
                headRow([
                  trG('Date'),
                  trG('Category'),
                  trG('Note'),
                  trG('Wallet'),
                  trG('Amount'),
                ], rightFrom: 4),
                for (final t in txs)
                  pw.TableRow(children: [
                    c(DateFormat('d MMM yy', AppLocale.code).format(t.date)),
                    c(catName(t.categoryId)),
                    c(t.note),
                    c(walletName(t.walletId)),
                    c('${t.type == TxType.income ? '+' : '-'}${rupiah(t.amount)}', right: true),
                  ]),
              ],
            ),
        ],
      ),
    );

    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd').format(range.start);
    final file = File('${dir.path}/wall_o_pay_report_$stamp.pdf');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'Wall o\' Pay report'),
    );
  }

}
