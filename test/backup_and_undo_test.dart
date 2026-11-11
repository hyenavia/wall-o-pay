import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/core/period.dart';
import 'package:wall_o_pay/data/app_database.dart';
import 'package:wall_o_pay/data/budget_rule.dart';
import 'package:wall_o_pay/data/cloud.dart';
import 'package:wall_o_pay/data/prefs.dart';
import 'package:wall_o_pay/data/tables.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Database Soft-Delete & Restore Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Transaction can be deleted and restored via soft-delete', () async {
      await db.addTransaction(
        amount: 50000,
        type: TxType.expense,
        categoryId: 'cat-exp-food',
        date: DateTime(2026, 11, 5),
        note: 'Lunch test',
      );

      final list1 = await db.allActiveTransactions();
      expect(list1.length, 1);
      final txId = list1.first.id;

      // Soft delete
      await db.deleteTransaction(txId);
      final listAfterDelete = await db.allActiveTransactions();
      expect(listAfterDelete, isEmpty);

      // Restore
      await db.restoreTransaction(txId);
      final listAfterRestore = await db.allActiveTransactions();
      expect(listAfterRestore.length, 1);
      expect(listAfterRestore.first.id, txId);
      expect(listAfterRestore.first.deletedAt, isNull);
    });

    test('Debt can be deleted and restored via soft-delete', () async {
      await db.addDebt(
        person: 'Budi',
        amount: 100000,
        direction: DebtDirection.lent,
        dueDate: DateTime(2026, 11, 20),
        note: 'Pinjam makan',
      );

      final debts1 = await db.watchDebts().first;
      expect(debts1.length, 1);
      final debtId = debts1.first.id;

      // Soft delete
      await db.deleteDebt(debtId);
      final debtsAfterDelete = await db.watchDebts().first;
      expect(debtsAfterDelete, isEmpty);

      // Restore
      await db.restoreDebt(debtId);
      final debtsAfterRestore = await db.watchDebts().first;
      expect(debtsAfterRestore.length, 1);
      expect(debtsAfterRestore.first.id, debtId);
      expect(debtsAfterRestore.first.deletedAt, isNull);
    });

    test('SavingsGoal can be deleted and restored via soft-delete', () async {
      await db.addSavingsGoal(
        'Dana Darurat',
        5000000,
        targetDate: DateTime(2027, 1, 1),
      );

      final goals1 = await db.watchSavingsGoals().first;
      expect(goals1.length, 1);
      final goalId = goals1.first.id;

      // Soft delete
      await db.deleteSavingsGoal(goalId);
      final goalsAfterDelete = await db.watchSavingsGoals().first;
      expect(goalsAfterDelete, isEmpty);

      // Restore
      await db.restoreSavingsGoal(goalId);
      final goalsAfterRestore = await db.watchSavingsGoals().first;
      expect(goalsAfterRestore.length, 1);
      expect(goalsAfterRestore.first.id, goalId);
      expect(goalsAfterRestore.first.deletedAt, isNull);
    });
  });

  group('Backup JSON Preferences & Budget Configuration Tests', () {
    late AppDatabase db;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('exportBackup includes preferences and budgetConfig when provided', () async {
      final samplePrefs = {
        'firstDayOfMonth': 25,
        'periodType': 'monthly',
        'rollover': true,
      };
      final sampleBudget = {
        'totalPools': {'2026-11': 10000000},
        'categoryBuckets': {'cat-food': 'needs'},
      };

      final exported = await db.exportBackup(
        preferences: samplePrefs,
        budgetConfig: sampleBudget,
      );

      expect(exported['app'], 'wall_o_pay');
      expect(exported['version'], 1);
      expect(exported['preferences'], samplePrefs);
      expect(exported['budgetConfig'], sampleBudget);
      expect(exported['categories'], isA<List>());
      expect(exported['transactions'], isA<List>());
    });

    test('importBackup ignores unrecognized preferences keys cleanly (backward compatibility)', () async {
      final data = {
        'app': 'wall_o_pay',
        'version': 1,
        'preferences': {'firstDayOfMonth': 25},
        'budgetConfig': {'totalPools': {}},
        'categories': <dynamic>[],
        'wallets': <dynamic>[],
        'transactions': <dynamic>[],
      };

      // importBackup processes tables and ignores non-table keys without throw
      final count = await db.importBackup(data);
      expect(count, 0);
    });

    test('AppPrefsController exports and imports settings correctly', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          firebaseReadyProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(appPrefsProvider.notifier);
      await controller.setFirstDayOfMonth(25);
      await controller.setPeriodType(PeriodType.weekly);

      final exported = controller.exportPreferences();
      expect(exported['firstDayOfMonth'], 25);
      expect(exported['periodType'], 'weekly');

      // Now reset and import
      await controller.setFirstDayOfMonth(1);
      await controller.setPeriodType(PeriodType.monthly);
      expect(container.read(appPrefsProvider).firstDayOfMonth, 1);
      expect(container.read(appPrefsProvider).periodType, PeriodType.monthly);

      await controller.importPreferences(exported);
      expect(container.read(appPrefsProvider).firstDayOfMonth, 25);
      expect(container.read(appPrefsProvider).periodType, PeriodType.weekly);
    });

    test('AppPrefsController ignores legacy Cyberpunk keys during JSON import cleanly', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          firebaseReadyProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(appPrefsProvider.notifier);
      await controller.importPreferences({
        'themeMode': 'dark',
        'themePreset': 'cyberpunk',
        'cyberpunkUnlocked': true,
        'localeCode': 'id',
        'periodType': 'weekly',
        'firstDayOfWeek': DateTime.sunday,
        'firstDayOfMonth': 25,
      });

      final state = container.read(appPrefsProvider);
      expect(state.localeCode, 'id');
      expect(state.periodType, PeriodType.weekly);
      expect(state.firstDayOfWeek, DateTime.sunday);
      expect(state.firstDayOfMonth, 25);
      expect(controller.exportPreferences().containsKey('themePreset'), isFalse);
      expect(controller.exportPreferences().containsKey('cyberpunkUnlocked'), isFalse);
    });

    test('BudgetRuleNotifier exports and imports configuration correctly', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          firebaseReadyProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(budgetRuleProvider.notifier);
      await controller.setTotalBudget('2026-11', 12500000);
      await controller.setCategoryBucket('cat-food', BudgetBucket.needs);

      final exported = controller.exportConfig();
      expect(exported['totalPools'], {'2026-11': 12500000});
      expect(exported['categoryBuckets'], {'cat-food': 'needs'});

      // Clear local
      await controller.clearLocal();
      expect(container.read(budgetRuleProvider).getTotalBudget('2026-11'), 0);

      // Import back
      await controller.importConfig(exported);
      expect(container.read(budgetRuleProvider).getTotalBudget('2026-11'), 12500000);
      expect(container.read(budgetRuleProvider).categoryBuckets['cat-food'], BudgetBucket.needs);
    });

    test('Undo and backup bilingual strings exist in EN and ID', () {
      AppLocale.code = 'en';
      expect(trG('Undo'), 'Undo');
      expect(trG('Transaction deleted'), 'Transaction deleted');
      expect(trG('Debt deleted'), 'Debt deleted');
      expect(trG('Savings goal deleted'), 'Savings goal deleted');
      expect(trG('Item restored'), 'Item restored');
      expect(
        trG('Settings and budget configuration imported.'),
        'Settings and budget configuration imported.',
      );

      AppLocale.code = 'id';
      expect(trG('Undo'), 'Urungkan');
      expect(trG('Transaction deleted'), 'Transaksi dihapus');
      expect(trG('Debt deleted'), 'Catatan utang dihapus');
      expect(trG('Savings goal deleted'), 'Target tabungan dihapus');
      expect(trG('Item restored'), 'Item berhasil dipulihkan');
      expect(
        trG('Settings and budget configuration imported.'),
        'Pengaturan dan konfigurasi anggaran berhasil diimpor.',
      );
    });
  });
}
