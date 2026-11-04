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

  group('Debt, Goal, and Wallet Integration Tests', () {
    test('Debt payment records with walletId and updates balance properly', () async {
      // Create a debt: someone owes us 50,000
      await db.addDebt(
        person: 'Budi',
        direction: DebtDirection.lent,
        amount: 50000,
      );

      final debts = await db.watchDebts().first;
      expect(debts.length, 1);
      final debt = debts.first;

      // Record repayment of 30,000 to main wallet
      await db.addDebtPayment(debt.id, 30000);
      await db.addTransaction(
        amount: 30000,
        type: TxType.income,
        categoryId: 'cat-inc-other',
        walletId: 'wallet-main',
        date: DateTime.now(),
        note: 'Repayment from Budi',
      );

      final updatedDebts = await db.watchDebts().first;
      expect(updatedDebts.first.paidAmount, 30000);

      final txs = await db.watchAllTransactions().first;
      expect(txs.length, 1);
      expect(txs.first.walletId, 'wallet-main');
      expect(txs.first.type, TxType.income);
      expect(txs.first.amount, 30000);
    });

    test('Savings goal deposit and withdrawal update goal amount and transactions', () async {
      // Add savings goal
      await db.addSavingsGoal('Emergency Fund', 1000000);

      var goals = await db.watchSavingsGoals().first;
      expect(goals.length, 1);
      final goal = goals.first;

      // Deposit 200,000 from digital bank wallet
      await db.addToSavings(goal.id, 200000);
      await db.addTransaction(
        amount: 200000,
        type: TxType.expense,
        categoryId: 'cat-exp-other',
        walletId: 'wallet-digital',
        date: DateTime.now(),
        note: 'Savings deposit: Emergency Fund',
      );

      goals = await db.watchSavingsGoals().first;
      expect(goals.first.currentAmount, 200000);

      var txs = await db.watchAllTransactions().first;
      expect(txs.length, 1);
      expect(txs.first.walletId, 'wallet-digital');
      expect(txs.first.type, TxType.expense);
      expect(txs.first.amount, 200000);

      // Withdraw 50,000 back to wallet
      await db.addToSavings(goal.id, -50000);
      await db.addTransaction(
        amount: 50000,
        type: TxType.income,
        categoryId: 'cat-inc-other',
        walletId: 'wallet-digital',
        date: DateTime.now(),
        note: 'Savings withdrawal: Emergency Fund',
      );

      goals = await db.watchSavingsGoals().first;
      expect(goals.first.currentAmount, 150000);

      txs = await db.watchAllTransactions().first;
      expect(txs.length, 2);
    });

    test('Transactions can be filtered by walletId and categoryId', () async {
      final now = DateTime.now();

      await db.addTransaction(
        amount: 50000,
        type: TxType.expense,
        categoryId: 'cat-exp-food',
        walletId: 'wallet-main',
        date: now,
      );

      await db.addTransaction(
        amount: 100000,
        type: TxType.expense,
        categoryId: 'cat-exp-transport',
        walletId: 'wallet-digital',
        date: now,
      );

      final allTxs = await db.watchAllTransactions().first;
      expect(allTxs.length, 2);

      // Filter by wallet-main
      final walletFiltered = allTxs.where((t) => t.walletId == 'wallet-main').toList();
      expect(walletFiltered.length, 1);
      expect(walletFiltered.first.amount, 50000);

      // Filter by category food
      final catFiltered = allTxs.where((t) => t.categoryId == 'cat-exp-food').toList();
      expect(catFiltered.length, 1);
      expect(catFiltered.first.walletId, 'wallet-main');
    });
  });
}
