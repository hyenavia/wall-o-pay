import 'package:flutter/material.dart';
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

    test('computeChartPoints buckets custom firstDayOfMonth period accurately across calendar months', () {
      // Payday 25th: 25 Oct 2026 -> 25 Nov 2026 (31 days -> 5 buckets)
      final period = Period.containing(
        PeriodType.monthly,
        DateTime(2026, 11, 10),
        firstDayOfMonth: 25,
      );
      final txs = [
        TransactionEntry(
          id: 'oct26',
          amount: 100000,
          type: TxType.expense,
          categoryId: 'cat-exp-food',
          note: 'Late Oct expense',
          date: DateTime(2026, 10, 26),
          createdAt: DateTime(2026, 10, 26),
          updatedAt: DateTime(2026, 10, 26),
        ),
        TransactionEntry(
          id: 'nov12',
          amount: 250000,
          type: TxType.expense,
          categoryId: 'cat-exp-food',
          note: 'Mid Nov expense',
          date: DateTime(2026, 11, 12),
          createdAt: DateTime(2026, 11, 12),
          updatedAt: DateTime(2026, 11, 12),
        ),
        TransactionEntry(
          id: 'nov24',
          amount: 75000,
          type: TxType.expense,
          categoryId: 'cat-exp-transport',
          note: 'End of custom period',
          date: DateTime(2026, 11, 24),
          createdAt: DateTime(2026, 11, 24),
          updatedAt: DateTime(2026, 11, 24),
        ),
      ];

      final points = InsightEngine.computeChartPoints(
        currentTxs: txs,
        period: period,
      );

      expect(points.length, 5);
      // W1: 25 Oct - 31 Oct -> includes Oct 26
      expect(points[0].amount, 100000);
      // W2: 1 Nov - 7 Nov -> 0
      expect(points[1].amount, 0);
      // W3: 8 Nov - 14 Nov -> includes Nov 12
      expect(points[2].amount, 250000);
      // W5: 22 Nov - 24 Nov -> includes Nov 24
      expect(points[4].amount, 75000);
      expect(points.fold<int>(0, (s, p) => s + p.amount), 425000);
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

    test('Accounts and Insights tabs localization in English and Indonesian', () {
      AppLocale.code = 'en';
      expect(trG('Accounts'), 'Accounts');
      expect(trG('Overview'), 'Overview');
      expect(trG('Categories'), 'Categories');
      expect(trG('Trend'), 'Trend');
      expect(trG('Transfer Between Accounts'), 'Transfer Between Accounts');
      expect(trG('Balance'), 'Balance');

      AppLocale.code = 'id';
      expect(trG('Accounts'), 'Akun & Rekening');
      expect(trG('Overview'), 'Ringkasan');
      expect(trG('Categories'), 'Kategori');
      expect(trG('Trend'), 'Tren');
      expect(trG('Transfer Between Accounts'), 'Transfer Antar Akun');
      expect(trG('Balance'), 'Saldo');
      expect(trG('Cashflow Calendar'), 'Kalender Arus Kas');
      expect(trG('Frequent Small Purchases'), 'Pengeluaran Kecil Berulang');
      expect(trG('My share only'), 'Hanya bagianku');
      expect(trG('Full bill paid by me'), 'Seluruh tagihan kubayar');
      expect(trG('Payment Account'), 'Rekening Pembayaran');
    });

    testWidgets('generateSmartInsights detects Frequent Small Purchases (Latte Factor)', (tester) async {
      AppLocale.code = 'en';
      final now = DateTime(2026, 11, 7);
      final period = Period.containing(PeriodType.monthly, now);
      final catMap = {
        'cat-exp-food': Category(
          id: 'cat-exp-food',
          name: 'Food & Drinks',
          type: TxType.expense,
          icon: 'restaurant',
          colorValue: 0xFFEF6C00,
          createdAt: now,
          updatedAt: now,
        ),
      };
      final txs = [
        for (int i = 0; i < 4; i++)
          TransactionEntry(
            id: 'm$i',
            amount: 20000,
            type: TxType.expense,
            categoryId: 'cat-exp-food',
            note: 'Coffee',
            date: now,
            createdAt: now,
            updatedAt: now,
          ),
      ];

      late List<SmartInsightItem> items;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final summary = InsightEngine.computeSummary(currentTxs: txs, prevTxs: []);
              final cats = InsightEngine.computeCategories(
                context: context,
                currentTxs: txs,
                prevTxs: [],
                categoryMap: catMap,
                totalExpense: summary.totalExpense,
              );
              items = InsightEngine.generateSmartInsights(
                context: context,
                summary: summary,
                categories: cats,
                currentTxs: txs,
                period: period,
                categoryMap: catMap,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final latte = items.where((i) => i.title == 'Frequent Small Purchases').toList();
      expect(latte.length, 1);
      expect(latte.first.badge, '4x');
      expect(latte.first.description, contains('Rp 80.000'));
    });
  });
}
