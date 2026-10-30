import 'package:wall_o_pay/core/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wall_o_pay/core/period.dart';
import 'package:wall_o_pay/data/app_database.dart';
import 'package:wall_o_pay/data/tables.dart';
import 'package:wall_o_pay/features/insights/insight_engine.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('id');
  });

  group('InsightEngine Tests', () {
    test('computeSummary correctly computes income, expense, and delta', () {
      final now = DateTime(2026, 10, 29);
      final currentTxs = [
        TransactionEntry(
          id: '1',
          amount: 1000000,
          type: TxType.income,
          categoryId: 'salary',
          note: 'Gaji',
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
        TransactionEntry(
          id: '2',
          amount: 400000,
          type: TxType.expense,
          categoryId: 'food',
          note: 'Makan',
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
        TransactionEntry(
          id: '3',
          amount: 200000,
          type: TxType.expense,
          categoryId: 'transport',
          note: 'Bensin',
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final prevTxs = [
        TransactionEntry(
          id: 'prev1',
          amount: 500000,
          type: TxType.expense,
          categoryId: 'food',
          note: 'Makan lalu',
          date: now.subtract(const Duration(days: 30)),
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final summary = InsightEngine.computeSummary(
        currentTxs: currentTxs,
        prevTxs: prevTxs,
      );

      expect(summary.totalIncome, 1000000);
      expect(summary.totalExpense, 600000);
      expect(summary.netBalance, 400000);
      expect(summary.isDeficit, isFalse);
      expect(summary.savingsRate, closeTo(40.0, 0.1));
      expect(summary.prevTotalExpense, 500000);
      expect(summary.expenseDiff, 100000);
      expect(summary.expensePctChange, closeTo(20.0, 0.1));
      expect(summary.isLowData, isTrue); // only 2 expense txs
    });

    test('computeChartPoints generates 7 daily points for weekly period', () {
      final period = Period.containing(PeriodType.weekly, DateTime(2026, 10, 29));
      final points = InsightEngine.computeChartPoints(
        currentTxs: [],
        period: period,
      );

      expect(points.length, 7);
    });

    test('computeChartPoints generates 4 or 5 points for monthly period', () {
      final period = Period.containing(PeriodType.monthly, DateTime(2026, 10, 29));
      final points = InsightEngine.computeChartPoints(
        currentTxs: [],
        period: period,
      );

      expect(points.length, greaterThanOrEqualTo(4));
    });

    test('Insight localization returns English in en and Indonesian in id', () {
      AppLocale.code = 'en';
      expect(trG('Weekly Summary'), 'Weekly Summary');
      expect(trG('Top Categories'), 'Top Categories');
      expect(trG('Positive Cashflow & Savings'), 'Positive Cashflow & Savings');
      expect(trG('Daily Expense Chart'), 'Daily Expense Chart');

      AppLocale.code = 'id';
      expect(trG('Weekly Summary'), 'Ringkasan Minggu Ini');
      expect(trG('Top Categories'), 'Kategori Teratas');
      expect(trG('Positive Cashflow & Savings'), 'Cashflow Positif & Tabungan');
      expect(trG('Daily Expense Chart'), 'Grafik Pengeluaran Harian');
    });

    test('Wallet localization converts both Indonesian and English keys correctly', () {
      AppLocale.code = 'en';
      expect(trG('Rekening Utama'), 'Main Account');
      expect(trG('Bank Digital'), 'Digital Bank');
      expect(trG('Tunai'), 'Cash');
      expect(trG('Main Account'), 'Main Account');
      expect(trG('Digital Bank'), 'Digital Bank');
      expect(trG('Cash'), 'Cash');
      expect(trG('E-Wallet'), 'E-Wallet');

      AppLocale.code = 'id';
      expect(trG('Rekening Utama'), 'Rekening Utama');
      expect(trG('Bank Digital'), 'Bank Digital');
      expect(trG('Tunai'), 'Tunai');
      expect(trG('Main Account'), 'Rekening Utama');
      expect(trG('Digital Bank'), 'Bank Digital');
      expect(trG('Cash'), 'Tunai');
      expect(trG('E-Wallet'), 'E-Wallet');
    });

    test('Period.containing with custom firstDayOfMonth (e.g. 25th Payday)', () {
      // Tanggal 30 Oktober 2026, gajian tanggal 25
      final p1 = Period.containing(
        PeriodType.monthly,
        DateTime(2026, 10, 30),
        firstDayOfMonth: 25,
      );
      expect(p1.start, DateTime(2026, 10, 25));
      expect(p1.end, DateTime(2026, 11, 25));
      expect(p1.contains(DateTime(2026, 10, 25)), isTrue);
      expect(p1.contains(DateTime(2026, 11, 15)), isTrue);
      expect(p1.contains(DateTime(2026, 11, 25)), isFalse);

      // Tanggal 10 November 2026 (sebelum gajian tanggal 25)
      final p2 = Period.containing(
        PeriodType.monthly,
        DateTime(2026, 11, 10),
        firstDayOfMonth: 25,
      );
      expect(p2.start, DateTime(2026, 10, 25));
      expect(p2.end, DateTime(2026, 11, 25));

      // Standar tanggal 1
      final p3 = Period.containing(
        PeriodType.monthly,
        DateTime(2026, 10, 15),
        firstDayOfMonth: 1,
      );
      expect(p3.start, DateTime(2026, 10, 1));
      expect(p3.end, DateTime(2026, 11, 1));
    });
  });
}