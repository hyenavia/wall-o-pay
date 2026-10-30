import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

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
  ('wallet-main', 'Main Account', 'bank', 0, 'account_balance', 0xFF1E4238),
  ('wallet-digital', 'Digital Bank', 'digital', 0, 'smartphone', 0xFF00897B),
  ('wallet-ewallet', 'E-Wallet', 'ewallet', 0, 'account_balance_wallet', 0xFFEF6C00),
  ('wallet-cash', 'Cash', 'cash', 0, 'payments', 0xFF558B2F),
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

@DriftDatabase(tables: [Categories, Wallets, Transactions, Budgets, SavingsGoals, PendingTransactions, RecurringRules, Debts, TxTemplates])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'wall_o_pay'));

  @override
  int get schemaVersion => 8;

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
          if (from < 6) {
            await m.addColumn(transactions, transactions.receiptPath);
            await m.addColumn(pendingTransactions, pendingTransactions.receiptPath);
            await m.createTable(recurringRules);
          }
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
          if (from < 8) {
            try {
              await m.createTable(debts);
            } catch (_) {}
            try {
              await m.createTable(txTemplates);
            } catch (_) {}
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          // Update default wallet names to multi-language English identifiers if still using legacy Indonesian names
          await customStatement("UPDATE wallets SET name = 'Main Account' WHERE id = 'wallet-main' AND name = 'Rekening Utama'");
          await customStatement("UPDATE wallets SET name = 'Digital Bank' WHERE id = 'wallet-digital' AND name = 'Bank Digital'");
          await customStatement("UPDATE wallets SET name = 'Cash' WHERE id = 'wallet-cash' AND name = 'Tunai'");
          // Self-healing: pastikan tabel debts dan tx_templates selalu tersedia
          await customStatement('''
            CREATE TABLE IF NOT EXISTS debts (
              id TEXT NOT NULL PRIMARY KEY,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              deleted_at INTEGER,
              person TEXT NOT NULL,
              direction TEXT NOT NULL,
              amount INTEGER NOT NULL,
              paid_amount INTEGER NOT NULL DEFAULT 0,
              note TEXT NOT NULL DEFAULT '',
              due_date INTEGER,
              date INTEGER NOT NULL
            );
          ''');
          await customStatement('''
            CREATE TABLE IF NOT EXISTS tx_templates (
              id TEXT NOT NULL PRIMARY KEY,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              deleted_at INTEGER,
              name TEXT NOT NULL,
              type TEXT NOT NULL,
              amount INTEGER NOT NULL,
              category_id TEXT NOT NULL,
              wallet_id TEXT,
              need_want TEXT,
              note TEXT NOT NULL DEFAULT ''
            );
          ''');
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
    String? receiptPath,
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
        receiptPath: Value(receiptPath),
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
    String? receiptPath,
  }) async {
    await into(transactions).insert(TransactionsCompanion.insert(
      amount: amount,
      type: type,
      categoryId: categoryId,
      date: date,
      note: Value(note),
      walletId: Value(walletId ?? 'wallet-main'),
      toWalletId: Value(toWalletId),
      receiptPath: Value(receiptPath),
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
    String? receiptPath,
    bool clearReceipt = false,
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
        receiptPath: clearReceipt
            ? const Value(null)
            : (receiptPath != null ? Value(receiptPath) : const Value.absent()),
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
    final existingList = await (select(budgets)
          ..where((b) =>
              b.categoryId.equals(categoryId) & b.monthKey.equals(monthKey)))
        .get();

    if (existingList.isEmpty) {
      if (amount <= 0) return;
      await into(budgets).insert(BudgetsCompanion.insert(
        categoryId: categoryId,
        monthKey: monthKey,
        amount: amount,
      ));
      return;
    }

    final existing = existingList.first;
    if (existingList.length > 1) {
      for (final dup in existingList.skip(1)) {
        await (delete(budgets)..where((b) => b.id.equals(dup.id))).go();
      }
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
              deletedAt: const Value(null),
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
      'recurringRules':
          (await select(recurringRules).get()).map((r) => r.toJson()).toList(),
      'debts':
          (await select(debts).get()).map((r) => r.toJson()).toList(),
      'txTemplates':
          (await select(txTemplates).get()).map((r) => r.toJson()).toList(),
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
      await delete(recurringRules).go();
      try {
        await delete(debts).go();
      } catch (e) {
        debugPrint('[AppDatabase] Warning resetting debts: $e');
      }
      try {
        await delete(txTemplates).go();
      } catch (e) {
        debugPrint('[AppDatabase] Warning resetting txTemplates: $e');
      }
      await delete(categories).go();
      await delete(wallets).go();
      await delete(pendingTransactions).go();
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
            final localById = await (select(budgets)
                  ..where((r) => r.id.equals(remote.id)))
                .getSingleOrNull();
            if (localById != null) {
              if (!remote.updatedAt.isAfter(localById.updatedAt)) {
                return false;
              }
              await into(budgets).insertOnConflictUpdate(remote);
              return true;
            }

            final localByKey = await (select(budgets)
                  ..where((r) =>
                      r.categoryId.equals(remote.categoryId) &
                      r.monthKey.equals(remote.monthKey)))
                .get();
            if (localByKey.isNotEmpty) {
              final first = localByKey.first;
              if (remote.updatedAt.isAfter(first.updatedAt)) {
                for (final row in localByKey) {
                  await (delete(budgets)..where((b) => b.id.equals(row.id))).go();
                }
                await into(budgets).insert(remote);
                return true;
              }
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
        SyncTable(
          name: 'recurringRules',
          changed: (since) async => (await (select(recurringRules)
                    ..where((r) => r.updatedAt.isBiggerThanValue(since)))
                  .get())
              .map((r) => r.toJson())
              .toList(),
          applyRemote: (json) async {
            final remote = RecurringRule.fromJson(json);
            final local = await (select(recurringRules)
                  ..where((r) => r.id.equals(remote.id)))
                .getSingleOrNull();
            if (local != null && !remote.updatedAt.isAfter(local.updatedAt)) {
              return false;
            }
            await into(recurringRules).insertOnConflictUpdate(remote);
            return true;
          },
        ),
        SyncTable(
          name: 'debts',
          changed: (since) async => (await (select(debts)
                    ..where((r) => r.updatedAt.isBiggerThanValue(since)))
                  .get())
              .map((r) => r.toJson())
              .toList(),
          applyRemote: (json) async {
            final remote = Debt.fromJson(json);
            final local = await (select(debts)
                  ..where((r) => r.id.equals(remote.id)))
                .getSingleOrNull();
            if (local != null && !remote.updatedAt.isAfter(local.updatedAt)) {
              return false;
            }
            await into(debts).insertOnConflictUpdate(remote);
            return true;
          },
        ),
        SyncTable(
          name: 'txTemplates',
          changed: (since) async => (await (select(txTemplates)
                    ..where((r) => r.updatedAt.isBiggerThanValue(since)))
                  .get())
              .map((r) => r.toJson())
              .toList(),
          applyRemote: (json) async {
            final remote = TxTemplate.fromJson(json);
            final local = await (select(txTemplates)
                  ..where((r) => r.id.equals(remote.id)))
                .getSingleOrNull();
            if (local != null && !remote.updatedAt.isAfter(local.updatedAt)) {
              return false;
            }
            await into(txTemplates).insertOnConflictUpdate(remote);
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

  // ---------------------------------------------------------------------------
  // Recurring Rules (Transaksi Berulang)
  // ---------------------------------------------------------------------------

  Stream<List<RecurringRule>> watchRecurringRules() =>
      (select(recurringRules)
            ..where((r) => r.deletedAt.isNull())
            ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
          .watch();

  Future<List<RecurringRule>> getDueRecurringRules(DateTime now) =>
      (select(recurringRules)
            ..where((r) =>
                r.deletedAt.isNull() &
                r.isActive.equals(true) &
                r.nextDueDate.isSmallerOrEqualValue(now)))
          .get();

  Future<void> addRecurringRule({
    required String title,
    required int amount,
    required TxType type,
    required String categoryId,
    String? walletId,
    String? toWalletId,
    required RecurFrequency frequency,
    int? dayOfWeek,
    int? dayOfMonth,
    required DateTime startDate,
    required DateTime nextDueDate,
    String note = '',
  }) async {
    await into(recurringRules).insert(
      RecurringRulesCompanion.insert(
        title: title,
        amount: amount,
        type: type,
        categoryId: categoryId,
        walletId: Value(walletId ?? 'wallet-main'),
        toWalletId: Value(toWalletId),
        frequency: frequency,
        dayOfWeek: Value(dayOfWeek),
        dayOfMonth: Value(dayOfMonth),
        startDate: startDate,
        nextDueDate: nextDueDate,
        note: Value(note),
      ),
    );
  }

  Future<void> updateRecurringNextDueDate(
    String id,
    DateTime nextDue,
    DateTime lastGenerated,
  ) async {
    await (update(recurringRules)..where((r) => r.id.equals(id))).write(
      RecurringRulesCompanion(
        nextDueDate: Value(nextDue),
        lastGeneratedDate: Value(lastGenerated),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> toggleRecurringRule(String id, bool active) async {
    await (update(recurringRules)..where((r) => r.id.equals(id))).write(
      RecurringRulesCompanion(
        isActive: Value(active),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteRecurringRule(String id) async {
    await (update(recurringRules)..where((r) => r.id.equals(id))).write(
      RecurringRulesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------- Utang-piutang dan patungan ----------

  Stream<List<Debt>> watchDebts() {
    return (select(debts)
          ..where((d) => d.deletedAt.isNull())
          ..orderBy([(d) => OrderingTerm.desc(d.createdAt)]))
        .watch();
  }

  Future<void> addDebt({
    required String person,
    required DebtDirection direction,
    required int amount,
    DateTime? dueDate,
    String note = '',
  }) async {
    await into(debts).insert(DebtsCompanion.insert(
      person: person,
      direction: direction,
      amount: amount,
      date: DateTime.now(),
      dueDate: Value(dueDate),
      note: Value(note),
    ));
  }

  /// Catat pembayaran sebagian atau pelunasan (tidak melebihi total utang).
  Future<void> addDebtPayment(String id, int amount) async {
    final d = await (select(debts)..where((x) => x.id.equals(id))).getSingle();
    final paid = (d.paidAmount + amount).clamp(0, d.amount).toInt();
    await (update(debts)..where((x) => x.id.equals(id))).write(
      DebtsCompanion(
        paidAmount: Value(paid),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteDebt(String id) async {
    await (update(debts)..where((x) => x.id.equals(id))).write(
      DebtsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------- Template transaksi ----------

  Stream<List<TxTemplate>> watchTemplates() {
    return (select(txTemplates)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<void> addTemplate({
    required String name,
    required TxType type,
    required int amount,
    required String categoryId,
    String? walletId,
    NeedWant? needWant,
    String note = '',
  }) async {
    await into(txTemplates).insert(TxTemplatesCompanion.insert(
      name: name,
      type: type,
      amount: amount,
      categoryId: categoryId,
      walletId: Value(walletId),
      needWant: Value(needWant),
      note: Value(note),
    ));
  }

  Future<void> deleteTemplate(String id) async {
    await (update(txTemplates)..where((t) => t.id.equals(id))).write(
      TxTemplatesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------- Statistik satu kali baca & laporan ----------

  Future<bool> hasAnyTransaction() async {
    final rows = await (select(transactions)
          ..where((t) => t.deletedAt.isNull())
          ..limit(1))
        .get();
    return rows.isNotEmpty;
  }

  Future<int> budgetAmount(String categoryId, String key) async {
    final b = await (select(budgets)
          ..where((x) =>
              x.deletedAt.isNull() &
              x.categoryId.equals(categoryId) &
              x.monthKey.equals(key)))
        .getSingleOrNull();
    return b?.amount ?? 0;
  }

  Future<int> expenseTotal(String categoryId, DateTime start, DateTime end) async {
    final rows = await (select(transactions)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.type.equalsValue(TxType.expense) &
              t.categoryId.equals(categoryId) &
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end)))
        .get();
    return rows.fold<int>(0, (s, t) => s + t.amount);
  }

  Future<List<TransactionEntry>> transactionsBetween(DateTime start, DateTime end) {
    return (select(transactions)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end))
          ..orderBy([
            (t) => OrderingTerm.asc(t.date),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();
  }
}
