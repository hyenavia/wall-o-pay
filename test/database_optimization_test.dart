import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wall_o_pay/data/app_database.dart';
import 'package:wall_o_pay/data/tables.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Database Optimization & Indexing Tests', () {
    test('performance indexes exist in SQLite schema', () async {
      final rows = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%'",
      ).get();

      final indexNames = rows.map((r) => r.read<String>('name')).toSet();

      expect(indexNames, contains('tx_date_idx'));
      expect(indexNames, contains('tx_category_idx'));
      expect(indexNames, contains('tx_wallet_idx'));
      expect(indexNames, contains('tx_to_wallet_idx'));
      expect(indexNames, contains('budgets_month_idx'));
    });

    test('watchSearchTransactions finds transactions by note, category, type, and date', () async {
      final now = DateTime(2026, 11, 2, 10, 0);

      // Add test transactions
      await db.addTransaction(
        amount: 25000,
        type: TxType.expense,
        categoryId: 'cat-exp-food',
        date: now,
        note: 'Kopi Kenangan Mantan',
      );

      await db.addTransaction(
        amount: 150000,
        type: TxType.expense,
        categoryId: 'cat-exp-shopping',
        date: now.subtract(const Duration(days: 5)),
        note: 'Beli baju kaos Uniqlo',
      );

      await db.addTransaction(
        amount: 5000000,
        type: TxType.income,
        categoryId: 'cat-inc-parttime',
        date: now.subtract(const Duration(days: 10)),
        note: 'Gaji freelance bulanan',
      );

      // 1. Search by note keyword
      final searchCoffee = await db.watchSearchTransactions(query: 'kenangan').first;
      expect(searchCoffee.length, 1);
      expect(searchCoffee.first.amount, 25000);
      expect(searchCoffee.first.note, 'Kopi Kenangan Mantan');

      // 2. Search by category name
      final searchFood = await db.watchSearchTransactions(query: 'Food').first;
      expect(searchFood.length, 1);
      expect(searchFood.first.categoryId, 'cat-exp-food');

      // 3. Search with type filter
      final searchExpense = await db.watchSearchTransactions(
        query: '',
        type: TxType.expense,
      ).first;
      expect(searchExpense.length, 2);

      final searchIncome = await db.watchSearchTransactions(
        query: '',
        type: TxType.income,
      ).first;
      expect(searchIncome.length, 1);
      expect(searchIncome.first.amount, 5000000);

      // 4. Search with date range filter
      final searchDateRange = await db.watchSearchTransactions(
        query: '',
        start: now.subtract(const Duration(days: 6)),
        end: now.add(const Duration(days: 1)),
      ).first;
      expect(searchDateRange.length, 2); // Excludes the 10-days ago transaction
    });

    test('soft-deleted transactions are excluded from search results', () async {
      final now = DateTime.now();
      await db.addTransaction(
        amount: 50000,
        type: TxType.expense,
        categoryId: 'cat-exp-food',
        date: now,
        note: 'Makan siang padang',
      );

      var results = await db.watchSearchTransactions(query: 'padang').first;
      expect(results.length, 1);

      // Soft delete
      await db.deleteTransaction(results.first.id);

      results = await db.watchSearchTransactions(query: 'padang').first;
      expect(results.isEmpty, isTrue);
    });
  });
}

