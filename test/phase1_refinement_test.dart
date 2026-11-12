import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_o_pay/core/period.dart';
import 'package:wall_o_pay/data/app_database.dart';
import 'package:wall_o_pay/data/budget_rule.dart';
import 'package:wall_o_pay/data/cloud.dart';
import 'package:wall_o_pay/data/notifications.dart';
import 'package:wall_o_pay/data/prefs.dart';
import 'package:wall_o_pay/data/providers.dart';
import 'package:wall_o_pay/data/recurring_service.dart';
import 'package:wall_o_pay/data/tables.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1 Refinement Regression Tests', () {
    late AppDatabase db;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('addTransaction and updateTransaction persist and clear needWant accurately', () async {
      final now = DateTime(2026, 11, 12);
      await db.addTransaction(
        amount: 45000,
        type: TxType.expense,
        categoryId: 'cat-exp-food',
        date: now,
        note: 'Makan siang',
        needWant: NeedWant.need,
      );

      var txs = await db.allActiveTransactions();
      expect(txs.length, 1);
      expect(txs.first.needWant, NeedWant.need);

      await db.updateTransaction(
        txs.first.id,
        amount: 55000,
        type: TxType.expense,
        categoryId: 'cat-exp-fun',
        date: now,
        note: 'Kopi kekinian',
        needWant: NeedWant.want,
      );

      txs = await db.allActiveTransactions();
      expect(txs.first.amount, 55000);
      expect(txs.first.needWant, NeedWant.want);

      await db.updateTransaction(
        txs.first.id,
        amount: 55000,
        type: TxType.expense,
        categoryId: 'cat-exp-fun',
        date: now,
        clearNeedWant: true,
      );

      txs = await db.allActiveTransactions();
      expect(txs.first.needWant, isNull);
    });

    test('system categories cat-exp-admin, cat-exp-savings, and cat-inc-savings are seeded', () async {
      final cats = await db.watchCategories().first;
      final ids = {for (final c in cats) c.id};

      expect(ids, contains('cat-exp-admin'));
      expect(ids, contains('cat-exp-savings'));
      expect(ids, contains('cat-inc-savings'));
      expect(defaultBucketForCategory('cat-exp-savings', 'Savings Deposit'), BudgetBucket.savings);
    });

    test('deleteTemplate soft-deletes saved template from watchTemplates stream', () async {
      await db.addTemplate(
        name: 'Daily Coffee',
        type: TxType.expense,
        amount: 25000,
        categoryId: 'cat-exp-food',
        needWant: NeedWant.want,
      );

      var templates = await db.watchTemplates().first;
      expect(templates.length, 1);
      final id = templates.first.id;

      await db.deleteTemplate(id);
      templates = await db.watchTemplates().first;
      expect(templates, isEmpty);
    });

    test('updateDebt updates fields, clears dueDate, and clamps paidAmount when amount shrinks', () async {
      final due = DateTime(2026, 12, 1);
      await db.addDebt(
        person: 'Raka',
        direction: DebtDirection.lent,
        amount: 200000,
        dueDate: due,
        note: 'Pinjam makan',
      );

      var list = await db.watchDebts().first;
      final debtId = list.first.id;
      await db.addDebtPayment(debtId, 150000);

      await db.updateDebt(
        debtId,
        person: 'Raka Pratama',
        direction: DebtDirection.borrowed,
        amount: 100000,
        clearDueDate: true,
        note: 'Dikoreksi',
      );

      list = await db.watchDebts().first;
      expect(list.first.person, 'Raka Pratama');
      expect(list.first.direction, DebtDirection.borrowed);
      expect(list.first.amount, 100000);
      expect(list.first.paidAmount, 100000);
      expect(list.first.dueDate, isNull);
      expect(list.first.note, 'Dikoreksi');
    });

    test('SelectedAnchor.step preserves custom firstDayOfMonth payday anchor', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          firebaseReadyProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appPrefsProvider.notifier).setFirstDayOfMonth(25);
      container.read(selectedAnchorProvider.notifier).step(-1);

      final shiftedPeriod = container.read(selectedPeriodProvider);
      expect(shiftedPeriod.start.day, 25);
      expect(shiftedPeriod.end.day, 25);
    });

    test('checkBudgetAfterExpense respects custom firstDayOfMonth period key', () async {
      final prefs = await SharedPreferences.getInstance();
      final date = DateTime(2026, 11, 10);
      final customPeriod = Period.containing(
        PeriodType.monthly,
        date,
        firstDayOfMonth: 25,
      );
      await db.setBudget('cat-exp-food', customPeriod.key, 100000);
      await db.addTransaction(
        amount: 90000,
        type: TxType.expense,
        categoryId: 'cat-exp-food',
        date: date,
      );

      await checkBudgetAfterExpense(
        db: db,
        prefs: prefs,
        periodType: PeriodType.monthly,
        categoryId: 'cat-exp-food',
        categoryName: 'Food & Drinks',
        date: date,
        firstDayOfMonth: 25,
      );

      expect(prefs.getInt('alert_${customPeriod.key}_cat-exp-food'), 80);
    });

    test('RecurringService.calculateUpcomingExpense counts remaining active expenses in period', () async {
      final now = DateTime(2026, 11, 10);
      final period = Period.containing(PeriodType.monthly, now);

      await db.addRecurringRule(
        title: 'Kos',
        amount: 1200000,
        type: TxType.expense,
        categoryId: 'cat-exp-housing',
        frequency: RecurFrequency.monthly,
        dayOfMonth: 20,
        startDate: DateTime(2026, 10, 20),
        nextDueDate: DateTime(2026, 11, 20),
      );
      await db.addRecurringRule(
        title: 'Internet Mingguan',
        amount: 50000,
        type: TxType.expense,
        categoryId: 'cat-exp-housing',
        frequency: RecurFrequency.weekly,
        startDate: DateTime(2026, 11, 15),
        nextDueDate: DateTime(2026, 11, 15),
      );
      // Income should be excluded
      await db.addRecurringRule(
        title: 'Part time',
        amount: 500000,
        type: TxType.income,
        categoryId: 'cat-inc-parttime',
        frequency: RecurFrequency.monthly,
        startDate: DateTime(2026, 11, 25),
        nextDueDate: DateTime(2026, 11, 25),
      );

      final rules = await db.watchRecurringRules().first;
      final upcoming = RecurringService.calculateUpcomingExpense(rules, period, now: now);

      // Kos once (Nov 20 = 1,200,000) + Internet weekly (Nov 15, Nov 22, Nov 29 = 3 * 50,000 = 150,000)
      expect(upcoming, 1350000);
    });
  });
}

