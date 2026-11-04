import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_o_pay/data/app_database.dart';
import 'package:wall_o_pay/data/notifications.dart';
import 'package:wall_o_pay/data/tables.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('id');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Transfer Admin Fee Tests', () {
    test('Transfer with admin fee deducts fee from source wallet as expense', () async {
      final now = DateTime.now();

      // Transfer 50,000 from wallet-main to wallet-digital
      await db.transferBetweenWallets(
        amount: 50000,
        fromWalletId: 'wallet-main',
        toWalletId: 'wallet-digital',
        date: now,
        note: 'Transfer ke e-wallet',
      );

      // Record admin fee of 2,500
      const adminFee = 2500;
      await db.addTransaction(
        amount: adminFee,
        type: TxType.expense,
        categoryId: 'cat-exp-other',
        date: now,
        walletId: 'wallet-main',
        note: 'Biaya admin transfer ke Bank Digital',
      );

      final txs = await db.watchAllTransactions().first;
      expect(txs.length, 2);

      final transferTx = txs.firstWhere((t) => t.type == TxType.transfer);
      expect(transferTx.amount, 50000);
      expect(transferTx.walletId, 'wallet-main');
      expect(transferTx.toWalletId, 'wallet-digital');

      final feeTx = txs.firstWhere((t) => t.type == TxType.expense);
      expect(feeTx.amount, 2500);
      expect(feeTx.walletId, 'wallet-main');
      expect(feeTx.categoryId, 'cat-exp-other');
      expect(feeTx.note, contains('Biaya admin'));
    });

    test('Expense with admin fee records both primary expense and secondary fee transaction', () async {
      final now = DateTime.now();

      // Primary expense: Token listrik PLN 50,000 from wallet-main
      await db.addTransaction(
        amount: 50000,
        type: TxType.expense,
        categoryId: 'cat-exp-housing',
        date: now,
        walletId: 'wallet-main',
        note: 'Token Listrik PLN',
      );

      // Associated admin fee: 2,500
      await db.addTransaction(
        amount: 2500,
        type: TxType.expense,
        categoryId: 'cat-exp-other',
        date: now,
        walletId: 'wallet-main',
        note: 'Biaya admin: Token Listrik PLN',
      );

      final txs = await db.watchAllTransactions().first;
      expect(txs.length, 2);

      final primaryTx = txs.firstWhere((t) => t.categoryId == 'cat-exp-housing');
      expect(primaryTx.amount, 50000);
      expect(primaryTx.walletId, 'wallet-main');

      final feeTx = txs.firstWhere((t) => t.categoryId == 'cat-exp-other');
      expect(feeTx.amount, 2500);
      expect(feeTx.walletId, 'wallet-main');
      expect(feeTx.note, 'Biaya admin: Token Listrik PLN');
    });
  });

  group('Debt Due Date Reminder Tests', () {
    test('checkDebtDueReminders processes unpaid debts due soon and prevents daily duplicate', () async {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final tomorrow = todayDate.add(const Duration(days: 1));

      // 1. Debt due tomorrow (H-1)
      await db.addDebt(
        person: 'Andi',
        direction: DebtDirection.lent,
        amount: 100000,
        dueDate: tomorrow,
      );

      // 2. Debt already fully paid
      await db.addDebt(
        person: 'Citra',
        direction: DebtDirection.borrowed,
        amount: 50000,
        dueDate: todayDate,
      );
      final allDebts = await db.watchDebts().first;
      final citraDebt = allDebts.firstWhere((d) => d.person == 'Citra');
      await db.addDebtPayment(citraDebt.id, 50000);

      // Execute reminder check
      await checkDebtDueReminders(db);

      final prefs = await SharedPreferences.getInstance();
      final andiDebt = allDebts.firstWhere((d) => d.person == 'Andi');
      final andiKey = 'notified_debt_${andiDebt.id}_${todayDate.year}_${todayDate.month}_${todayDate.day}';
      final citraKey = 'notified_debt_${citraDebt.id}_${todayDate.year}_${todayDate.month}_${todayDate.day}';

      // Andi is unpaid and due tomorrow, so notification key should be set
      expect(prefs.getBool(andiKey), isTrue);

      // Citra is already fully paid, so notification key should NOT be set
      expect(prefs.getBool(citraKey), isNull);

      // Running check again should safely skip already notified debt
      await checkDebtDueReminders(db);
      expect(prefs.getBool(andiKey), isTrue);
    });
  });
}
