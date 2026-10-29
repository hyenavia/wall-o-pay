import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// Kategori bawaan memakai ID tetap supaya tidak dobel saat sinkronisasi
/// antar perangkat. Format: (id, nama, ikon, warna, nama lama bahasa Indonesia).
/// Nama lama dipakai untuk migrasi data dari versi sebelumnya.
const _expenseSeed = <(String, String, String, int, String)>[
  ('cat-exp-food', 'Food & Drinks', 'restaurant', 0xFFEF6C00, 'Makan & minum'),
  ('cat-exp-transport', 'Transport', 'bus', 0xFF1E88E5, 'Transport'),
  ('cat-exp-housing', 'Rent & Bills', 'home', 0xFF6D4C41, 'Kos & tagihan'),
  ('cat-exp-study', 'Education', 'school', 0xFF5E35B1, 'Kuliah'),
  ('cat-exp-shopping', 'Shopping', 'shopping', 0xFFD81B60, 'Belanja'),
  ('cat-exp-fun', 'Entertainment', 'movie', 0xFF8E24AA, 'Hiburan'),
  ('cat-exp-health', 'Health', 'health', 0xFFE53935, 'Kesehatan'),
  ('cat-exp-other', 'Other', 'more', 0xFF607D8B, 'Lainnya'),
];

const _incomeSeed = <(String, String, String, int, String)>[
  ('cat-inc-parents', "Parents' allowance", 'family', 0xFF2E7D32, 'Kiriman orang tua'),
  ('cat-inc-scholarship', 'Scholarship', 'award', 0xFF00897B, 'Beasiswa'),
  ('cat-inc-parttime', 'Part-time job', 'work', 0xFF558B2F, 'Part-time'),
  ('cat-inc-other', 'Other', 'payments', 0xFF607D8B, 'Lainnya'),
];

const _transferSeed = <(String, String, String, int, String)>[
  ('cat-tra-transfer', 'Transfer', 'swap_horiz', 0xFF00897B, 'Transfer'),
];

const _walletSeed = <(String, String, String, int, String, int)>[
  ('wallet-main', 'Rekening Utama', 'bank', 0, 'account_balance', 0xFF1E4238),
  ('wallet-digital', 'Bank Digital', 'digital', 0, 'smartphone', 0xFF00897B),
  ('wallet-ewallet', 'E-Wallet', 'ewallet', 0, 'account_balance_wallet', 0xFFEF6C00),
  ('wallet-cash', 'Tunai', 'cash', 0, 'payments', 0xFF558B2F),
];

/// Jejak waktu "kosong" untuk data bawaan: perubahan apa pun dari pengguna
/// akan selalu dianggap lebih baru saat sinkronisasi.
final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0);

/// Penghubung antara database lokal dan lapisan sinkronisasi cloud.
class SyncTable {
  const SyncTable({
    required this.name,
    required this.changed,
    required this.applyRemote,
  });

  final String name;

  /// Baris lokal yang berubah setelah [since], dalam bentuk JSON.
  final Future<List<Map<String, dynamic>>> Function(DateTime since) changed;

  /// Terapkan baris dari cloud jika lebih baru dari yang lokal.
  final Future<bool> Function(Map<String, dynamic> json) applyRemote;
}

@DriftDatabase(tables: [Categories, Wallets, Transactions, Budgets, SavingsGoals, PendingTransactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'wall_o_pay'));

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedCategories();
          await _seedWallets();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) await _remapDefaultCategoryIds();
          if (from < 3) await _renameDefaultCategories();
          if (from < 4) await m.createTable(pendingTransactions);
          if (from < 5) {
            await m.createTable(wallets);
            await _seedWallets();
            await m.addColumn(transactions, transactions.walletId);
            await m.addColumn(transactions, transactions.toWalletId);
            await customStatement("UPDATE transactions SET wallet_id = 'wallet-main' WHERE wallet_id IS NULL");
            final existingTransfer = await (select(categories)..where((c) => c.id.equals('cat-tra-transfer'))).getSingleOrNull();
            if (existingTransfer == null) {
              await into(categories).insert(
                CategoriesCompanion.insert(
                  id: const Value('cat-tra-transfer'),
                  name: 'Transfer',
                  type: TxType.transfer,
                  icon: const Value('swap_horiz'),
                  colorValue: const Value(0xFF00897B),
                  createdAt: Value(_epoch),
                  updatedAt: Value(_epoch),
                ),
              );
            }
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _seedCategories() async {
    await batch((b) {
      b.insertAll(categories, [
        for (final s in _expenseSeed) _seedRow(s, TxType.expense),
        for (final s in _incomeSeed) _seedRow(s, TxType.income),
        for (final s in _transferSeed) _seedRow(s, TxType.transfer),
      ]);
    });
  }

  Future<void> _seedWallets() async {
    await batch((b) {
      b.insertAll(wallets, [
        for (final s in _walletSeed)
          WalletsCompanion.insert(
            id: Value(s.$1),
            name: s.$2,
            type: Value(s.$3),
            initialBalance: Value(s.$4),
            icon: Value(s.$5),
            colorValue: Value(s.$6),
            createdAt: Value(_epoch),
            updatedAt: Value(_epoch),
          ),
      ]);
    });
  }

  CategoriesCompanion _seedRow(
    (String, String, String, int, String) s,
    TxType type,
  ) {
    return CategoriesCompanion.insert(
      id: Value(s.$1),
      name: s.$2,
      type: type,
      icon: Value(s.$3),
      colorValue: Value(s.$4),
      createdAt: Value(_epoch),
      updatedAt: Value(_epoch),
    );
  }

  /// Migrasi v1 -> v2: kategori bawaan lama (ID acak) dipindah ke ID tetap,
  /// transaksi dan anggaran ikut diarahkan ke ID baru.
  Future<void> _remapDefaultCategoryIds() async {
    Future<void> remap(
      TxType type,
      (String, String, String, int, String) seed,
    ) async {
      final newId = seed.$1;
      final olds = await (select(categories)
            ..where((c) =>
                c.name.equals(seed.$5) &
                c.type.equalsValue(type) &
                c.id.equals(newId).not()))
          .get();
      for (final old in olds) {
        final exists = await (select(categories)
              ..where((c) => c.id.equals(newId)))
            .getSingleOrNull();
        if (exists == null) {
          await customStatement(
            'INSERT INTO categories (id, name, type, icon, color_value, '
            'created_at, updated_at, deleted_at) '
            'SELECT ?, name, type, icon, color_value, created_at, updated_at, '
            'deleted_at FROM categories WHERE id = ?',
            [newId, old.id],
          );
        }
        await customStatement(
          'UPDATE transactions SET category_id = ? WHERE category_id = ?',
          [newId, old.id],
        );
        await customStatement(
          'UPDATE budgets SET category_id = ? WHERE category_id = ?',
          [newId, old.id],
        );
        await customStatement('DELETE FROM categories WHERE id = ?', [old.id]);
      }
    }

    for (final s in _expenseSeed) {
      await remap(TxType.expense, s);
    }
    for (final s in _incomeSeed) {
      await remap(TxType.income, s);
    }
  }

  /// Migrasi v2 -> v3: ubah nama kategori bawaan dari bahasa Indonesia ke
  /// bahasa Inggris, hanya jika namanya belum diubah sendiri oleh pengguna.
  Future<void> _renameDefaultCategories() async {
    for (final s in [..._expenseSeed, ..._incomeSeed]) {
      await customStatement(
        'UPDATE categories SET name = ? WHERE id = ? AND name = ?',
        [s.$2, s.$1, s.$5],
      );
    }
  }

  // ---------- Kategori ----------

  /// Hanya kategori aktif (untuk pilihan di form).
  Stream<List<Category>> watchCategories() {
    return (select(categories)
          ..where((c) => c.deletedAt.isNull())
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  /// Termasuk yang sudah dihapus (supaya transaksi lama tetap punya nama).
  Stream<List<Category>> watchAllCategories() {
    return (select(categories)..orderBy([(c) => OrderingTerm.asc(c.name)])).watch();
  }

  Future<void> addCategory({
    required String name,
    required TxType type,
    String icon = 'more',
    int colorValue = 0xFF607D8B,
  }) async {
    await into(categories).insert(CategoriesCompanion.insert(
      name: name,
      type: type,
      icon: Value(icon),
      colorValue: Value(colorValue),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> updateCategory(
    String id, {
    required String name,
    TxType? type,
    required String icon,
    required int colorValue,
  }) async {
    await (update(categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(name),
        type: type == null ? const Value.absent() : Value(type),
        icon: Value(icon),
        colorValue: Value(colorValue),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteCategory(String id) async {
    await (update(categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Jumlah transaksi per kategori, untuk mengurutkan kategori yang sering dipakai.
  Future<Map<String, int>> categoryUsageCounts() async {
    final rows =
        await (select(transactions)..where((t) => t.deletedAt.isNull())).get();
    final result = <String, int>{};
    for (final t in rows) {
      result[t.categoryId] = (result[t.categoryId] ?? 0) + 1;
    }
    return result;
  }

  // ---------- Dompet & Rekening (Wallets) ----------

  Stream<List<Wallet>> watchWallets() {
    return (select(wallets)
          ..where((w) => w.deletedAt.isNull())
          ..orderBy([(w) => OrderingTerm.asc(w.createdAt)]))
        .watch();
  }

  Future<List<Wallet>> getAllWallets() {
    return (select(wallets)
          ..where((w) => w.deletedAt.isNull())
          ..orderBy([(w) => OrderingTerm.asc(w.createdAt)]))
        .get();
  }

  Future<void> updateWalletInitialBalance(String id, int initialBalance) async {
    await (update(wallets)..where((w) => w.id.equals(id))).write(
      WalletsCompanion(
        initialBalance: Value(initialBalance),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateWallet(
    String id, {
    String? name,
    String? type,
    String? icon,
    int? colorValue,
    int? initialBalance,
  }) async {
    await (update(wallets)..where((w) => w.id.equals(id))).write(
      WalletsCompanion(
        name: name == null ? const Value.absent() : Value(name),
        type: type == null ? const Value.absent() : Value(type),
        icon: icon == null ? const Value.absent() : Value(icon),
        colorValue: colorValue == null ? const Value.absent() : Value(colorValue),
        initialBalance: initialBalance == null ? const Value.absent() : Value(initialBalance),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> addWallet({
    required String name,
    required String type,
    int initialBalance = 0,
    String icon = 'account_balance',
    int colorValue = 0xFF1E4238,
  }) async {
    await into(wallets).insert(
      WalletsCompanion.insert(
        name: name,
        type: Value(type),
        initialBalance: Value(initialBalance),
        icon: Value(icon),
        colorValue: Value(colorValue),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteWallet(String id) async {
    await (update(wallets)..where((w) => w.id.equals(id))).write(
      WalletsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> transferBetweenWallets({
    required int amount,
    required String fromWalletId,
    required String toWalletId,
    required DateTime date,
    String note = '',
  }) async {
    await into(transactions).insert(
      TransactionsCompanion.insert(
        amount: amount,
        type: TxType.transfer,
        categoryId: 'cat-tra-transfer',
        date: date,
        note: Value(note),
        walletId: Value(fromWalletId),
        toWalletId: Value(toWalletId),
      ),
    );
  }

  // ---------- Transaksi ----------

  Stream<List<TransactionEntry>> watchAllTransactions() {
    return (select(transactions)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  Stream<List<TransactionEntry>> watchTransactionsBetween(
    DateTime start,
    DateTime end,
  ) {
    return (select(transactions)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end))
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  Stream<List<TransactionEntry>> watchTransactionsInMonth(DateTime month) {
    return watchTransactionsBetween(
      DateTime(month.year, month.month),
      DateTime(month.year, month.month + 1),
    );
  }

  Future<void> addTransaction({
    required int amount,
    required TxType type,
    required String categoryId,
    required DateTime date,
    String note = '',
    String? walletId,
    String? toWalletId,
  }) async {
    await into(transactions).insert(TransactionsCompanion.insert(
      amount: amount,
      type: type,
      categoryId: categoryId,
      date: date,
      note: Value(note),
      walletId: Value(walletId ?? 'wallet-main'),
      toWalletId: Value(toWalletId),
    ));
  }

  Future<void> updateTransaction(
    String id, {
    required int amount,
    required TxType type,
    required String categoryId,
    required DateTime date,
    String note = '',
    String? walletId,
    String? toWalletId,
  }) async {
    await (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        amount: Value(amount),
        type: Value(type),
        categoryId: Value(categoryId),
        date: Value(date),
        note: Value(note),
        walletId: Value(walletId ?? 'wallet-main'),
        toWalletId: Value(toWalletId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Soft delete: baris ditandai, tidak dihapus permanen.
  Future<void> deleteTransaction(String id) async {
    await (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------- Anggaran ----------

  Stream<List<Budget>> watchBudgets(String monthKey) {
    return (select(budgets)
          ..where((b) => b.deletedAt.isNull() & b.monthKey.equals(monthKey)))
        .watch();
  }

  /// Atur anggaran kategori untuk satu bulan. Nominal 0 menghapus anggaran.
  Future<void> setBudget(
    String categoryId,
    String monthKey,
    int amount,
  ) async {
    final existing = await (select(budgets)
          ..where((b) =>
              b.categoryId.equals(categoryId) & b.monthKey.equals(monthKey)))
        .getSingleOrNull();

    if (existing == null) {
      if (amount <= 0) return;
      await into(budgets).insert(BudgetsCompanion.insert(
        categoryId: categoryId,
        monthKey: monthKey,
        amount: amount,
      ));
      return;
    }

    await (update(budgets)..where((b) => b.id.equals(existing.id))).write(
      amount <= 0
          ? BudgetsCompanion(
              deletedAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            )
          : BudgetsCompanion(
              amount: Value(amount),
              updatedAt: Value(DateTime.now()),
            ),
    );
  }

  // ---------- Target Tabungan ----------

  Stream<List<SavingsGoal>> watchSavingsGoals() {
    return (select(savingsGoals)
          ..where((g) => g.deletedAt.isNull())
          ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
        .watch();
  }

  Future<void> addSavingsGoal(
    String name,
    int targetAmount, {
    DateTime? targetDate,
  }) async {
    await into(savingsGoals).insert(SavingsGoalsCompanion.insert(
      name: name,
      targetAmount: targetAmount,
      targetDate: Value(targetDate),
    ));
  }

  Future<void> addToSavings(String id, int amount) async {
    final goal = await (select(savingsGoals)..where((g) => g.id.equals(id)))
        .getSingle();
    await (update(savingsGoals)..where((g) => g.id.equals(id))).write(
      SavingsGoalsCompanion(
        currentAmount: Value(goal.currentAmount + amount),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateSavingsGoal(
    String id, {
    required String name,
    required int targetAmount,
    required int currentAmount,
    DateTime? targetDate,
  }) async {
    await (update(savingsGoals)..where((g) => g.id.equals(id))).write(
      SavingsGoalsCompanion(
        name: Value(name),
        targetAmount: Value(targetAmount),
        currentAmount: Value(currentAmount),
        targetDate: Value(targetDate),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteSavingsGoal(String id) async {
    await (update(savingsGoals)..where((g) => g.id.equals(id))).write(
      SavingsGoalsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------- Laporan & Cadangan ----------

  Future<List<Category>> allCategories() => select(categories).get();

  Future<List<TransactionEntry>> allActiveTransactions() {
    return (select(transactions)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<List<TransactionEntry>> getTransactionsBetween(
    DateTime start,
    DateTime end,
  ) {
    return (select(transactions)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Seluruh isi database (termasuk yang ditandai terhapus) dalam bentuk JSON.
  Future<Map<String, dynamic>> exportBackup() async {
    return {
      'app': 'wall_o_pay',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories':
          (await select(categories).get()).map((r) => r.toJson()).toList(),
      'wallets':
          (await select(wallets).get()).map((r) => r.toJson()).toList(),
      'transactions':
          (await select(transactions).get()).map((r) => r.toJson()).toList(),
      'budgets': (await select(budgets).get()).map((r) => r.toJson()).toList(),
      'savingsGoals':
          (await select(savingsGoals).get()).map((r) => r.toJson()).toList(),
    };
  }

  /// Gabungkan isi file backup JSON ke database lokal (yang terbaru menang).
  /// Mengembalikan jumlah baris yang ditambah atau diperbarui.
  Future<int> importBackup(Map<String, dynamic> data) async {
    if (data['app'] != 'wall_o_pay') {
      throw const FormatException("This is not a Wall o' Pay backup file.");
    }
    var applied = 0;
    await transaction(() async {
      for (final t in syncTables) {
        final rows = data[t.name];
        if (rows is! List) continue;
        for (final r in rows) {
          if (r is Map<String, dynamic> && await t.applyRemote(r)) applied++;
        }
      }
    });
    return applied;
  }

  /// Hapus semua data di perangkat ini, lalu isi ulang kategori bawaan.
  Future<void> resetAllData() async {
    await transaction(() async {
      await delete(transactions).go();
      await delete(budgets).go();
      await delete(savingsGoals).go();
      await delete(categories).go();
      await delete(wallets).go();
      await _seedCategories();
      await _seedWallets();
    });
  }

  // ---------- Sinkronisasi cloud ----------

  /// Urutan penting: kategori & dompet lebih dulu karena dipakai transaksi.
  List<SyncTable> get syncTables => [
        SyncTable(
          name: 'categories',
          changed: (since) async => (await (select(categories)
                    ..where((r) => r.updatedAt.isBiggerThanValue(since)))
                  .get())
              .map((r) => r.toJson())
              .toList(),
          applyRemote: (json) async {
            final remote = Category.fromJson(json);
            final local = await (select(categories)
                  ..where((r) => r.id.equals(remote.id)))
                .getSingleOrNull();
            if (local != null && !remote.updatedAt.isAfter(local.updatedAt)) {
              return false;
            }
            await into(categories).insertOnConflictUpdate(remote);
            return true;
          },
        ),
        SyncTable(
          name: 'wallets',
          changed: (since) async => (await (select(wallets)
                    ..where((r) => r.updatedAt.isBiggerThanValue(since)))
                  .get())
              .map((r) => r.toJson())
              .toList(),
          applyRemote: (json) async {
            final remote = Wallet.fromJson(json);
            final local = await (select(wallets)
                  ..where((r) => r.id.equals(remote.id)))
                .getSingleOrNull();
            if (local != null && !remote.updatedAt.isAfter(local.updatedAt)) {
              return false;
            }
            await into(wallets).insertOnConflictUpdate(remote);
            return true;
          },
        ),
        SyncTable(
          name: 'transactions',
          changed: (since) async => (await (select(transactions)
                    ..where((r) => r.updatedAt.isBiggerThanValue(since)))
                  .get())
              .map((r) => r.toJson())
              .toList(),
          applyRemote: (json) async {
            final remote = TransactionEntry.fromJson(json);
            final local = await (select(transactions)
                  ..where((r) => r.id.equals(remote.id)))
                .getSingleOrNull();
            if (local != null && !remote.updatedAt.isAfter(local.updatedAt)) {
              return false;
            }
            await into(transactions).insertOnConflictUpdate(remote);
            return true;
          },
        ),
        SyncTable(
          name: 'budgets',
          changed: (since) async => (await (select(budgets)
                    ..where((r) => r.updatedAt.isBiggerThanValue(since)))
                  .get())
              .map((r) => r.toJson())
              .toList(),
          applyRemote: (json) async {
            final remote = Budget.fromJson(json);
            final local = await (select(budgets)
                  ..where((r) => r.id.equals(remote.id)))
                .getSingleOrNull();
            if (local != null && !remote.updatedAt.isAfter(local.updatedAt)) {
              return false;
            }
            await into(budgets).insertOnConflictUpdate(remote);
            return true;
          },
        ),
        SyncTable(
          name: 'savingsGoals',
          changed: (since) async => (await (select(savingsGoals)
                    ..where((r) => r.updatedAt.isBiggerThanValue(since)))
                  .get())
              .map((r) => r.toJson())
              .toList(),
          applyRemote: (json) async {
            final remote = SavingsGoal.fromJson(json);
            final local = await (select(savingsGoals)
                  ..where((r) => r.id.equals(remote.id)))
                .getSingleOrNull();
            if (local != null && !remote.updatedAt.isAfter(local.updatedAt)) {
              return false;
            }
            await into(savingsGoals).insertOnConflictUpdate(remote);
            return true;
          },
        ),
      ];

  // ---------------------------------------------------------------------------
  // Pending Transactions (Auto-Track Inbox)
  // ---------------------------------------------------------------------------

  Stream<List<PendingTransaction>> watchPendingTransactions() =>
      (select(pendingTransactions)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  Future<List<PendingTransaction>> getPendingTransactions() =>
      (select(pendingTransactions)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Future<int> insertPendingTransaction(PendingTransactionsCompanion companion) =>
      into(pendingTransactions).insert(companion);

  Future<int> deletePendingTransaction(String id) =>
      (delete(pendingTransactions)..where((t) => t.id.equals(id))).go();

  Future<int> clearAllPendingTransactions() =>
      delete(pendingTransactions).go();
}
