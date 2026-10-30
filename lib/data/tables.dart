import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

enum TxType { income, expense, transfer }
enum RecurFrequency { daily, weekly, monthly }
enum NeedWant { need, want }
enum DebtDirection { lent, borrowed }

/// ID unik (UUID) supaya aman disinkronkan antar perangkat nanti.
String newId() => const Uuid().v4();

/// Kolom bersama untuk semua tabel (siap sinkronisasi cloud).
mixin SyncColumns on Table {
  TextColumn get id => text().clientDefault(() => newId())();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt => dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class Categories extends Table with SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get type => textEnum<TxType>()();
  TextColumn get icon => text().withDefault(const Constant('more'))();
  IntColumn get colorValue => integer().withDefault(const Constant(0xFF607D8B))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Wallet')
class Wallets extends Table with SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get type => text().withDefault(const Constant('bank'))(); // 'bank', 'digital', 'ewallet', 'cash'
  IntColumn get initialBalance => integer().withDefault(const Constant(0))();
  TextColumn get icon => text().withDefault(const Constant('account_balance'))();
  IntColumn get colorValue => integer().withDefault(const Constant(0xFF1E4238))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionEntry')
class Transactions extends Table with SyncColumns {
  IntColumn get amount => integer()();
  TextColumn get type => textEnum<TxType>()();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get date => dateTime()();
  @ReferenceName('walletTransactions')
  TextColumn get walletId => text().nullable().references(Wallets, #id)();
  @ReferenceName('incomingTransfers')
  TextColumn get toWalletId => text().nullable().references(Wallets, #id)();
  TextColumn get receiptPath => text().nullable()();
  TextColumn get needWant => textEnum<NeedWant>().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Budgets extends Table with SyncColumns {
  TextColumn get categoryId => text().references(Categories, #id)();
  IntColumn get amount => integer()();

  /// Format yyyy-MM, contoh: 2026-10.
  TextColumn get monthKey => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class SavingsGoals extends Table with SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 80)();
  IntColumn get targetAmount => integer()();
  IntColumn get currentAmount => integer().withDefault(const Constant(0))();
  DateTimeColumn get targetDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PendingTransaction')
class PendingTransactions extends Table {
  TextColumn get id => text().clientDefault(() => newId())();
  IntColumn get amount => integer()();
  TextColumn get type => textEnum<TxType>()();
  TextColumn get sourceApp => text()();
  TextColumn get rawNotification => text()();
  TextColumn get suggestedCategory => text().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();
  TextColumn get receiptPath => text().nullable()();
  TextColumn get needWant => textEnum<NeedWant>().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}


@DataClassName('RecurringRule')
class RecurringRules extends Table with SyncColumns {
  TextColumn get title => text().withLength(min: 1, max: 100)();
  IntColumn get amount => integer()();
  TextColumn get type => textEnum<TxType>()();
  TextColumn get categoryId => text().references(Categories, #id)();
  @ReferenceName('recurringSourceWallets')
  TextColumn get walletId => text().nullable().references(Wallets, #id)();
  @ReferenceName('recurringDestWallets')
  TextColumn get toWalletId => text().nullable().references(Wallets, #id)();
  TextColumn get frequency => textEnum<RecurFrequency>()();
  IntColumn get dayOfWeek => integer().nullable()();
  IntColumn get dayOfMonth => integer().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get nextDueDate => dateTime()();
  DateTimeColumn get lastGeneratedDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get note => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}


/// Utang-piutang dan patungan.
class Debts extends Table with SyncColumns {
  TextColumn get person => text().withLength(min: 1, max: 60)();
  TextColumn get direction => textEnum<DebtDirection>()();
  IntColumn get amount => integer()();
  IntColumn get paidAmount => integer().withDefault(const Constant(0))();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get date => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Template transaksi favorit untuk input sekali ketuk.
@DataClassName('TxTemplate')
class TxTemplates extends Table with SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 40)();
  TextColumn get type => textEnum<TxType>()();
  IntColumn get amount => integer()();
  TextColumn get categoryId => text()();
  TextColumn get walletId => text().nullable()();
  TextColumn get needWant => textEnum<NeedWant>().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}
