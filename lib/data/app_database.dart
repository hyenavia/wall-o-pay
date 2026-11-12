/// Database lokal utama aplikasi menggunakan Drift (SQLite) dengan prinsip Offline-First.
/// Menangani migrasi skema, pengisian data bawaan (seed), operasi CRUD dengan soft-delete (`deletedAt`),
/// ekspor/impor cadangan JSON, serta pemetaan sinkronisasi dua arah ([SyncTable]).
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

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
  ('cat-exp-admin', 'Admin Fee', 'receipt', 0xFF607D8B, 'Biaya Admin'),
  ('cat-exp-savings', 'Savings Deposit', 'savings', 0xFF00897B, 'Setoran Tabungan'),
  ('cat-exp-other', 'Other', 'more', 0xFF607D8B, 'Lainnya'),
];

const _incomeSeed = <(String, String, String, int, String)>[
  ('cat-inc-parents', "Parents' allowance", 'family', 0xFF2E7D32, 'Kiriman orang tua'),
  ('cat-inc-scholarship', 'Scholarship', 'award', 0xFF00897B, 'Beasiswa'),
  ('cat-inc-parttime', 'Part-time job', 'work', 0xFF558B2F, 'Part-time'),
  ('cat-inc-savings', 'Savings Withdrawal', 'savings', 0xFF00897B, 'Penarikan Tabungan'),
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

/// Kelas utama database SQLite lokal yang mengelola seluruh tabel data keuangan pengguna.
@DriftDatabase(tables: [
  Categories,
  Wallets,
  Transactions,
  Budgets,
  SavingsGoals,
  RecurringRules,
  Debts,
  DebtPayments,
  PendingTransactions,
  TxTemplates,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'wall_o_pay'));

  @override
  int get schemaVersion => 9;

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
          if (from < 6) {
            await m.addColumn(transactions, transactions.receiptPath);
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
          if (from < 9) {
            await _dropLegacyPendingTableIfIncompatible();
            try {
              await m.createTable(debtPayments);
            } catch (_) {}
            try {
              await m.createTable(pendingTransactions);
            } catch (_) {}
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          // Indeks performa untuk mempercepat query tabel transaksi, anggaran, dan kategori
          await customStatement('CREATE INDEX IF NOT EXISTS tx_date_idx ON transactions (date, deleted_at)');
          await customStatement('CREATE INDEX IF NOT EXISTS tx_category_idx ON transactions (category_id, deleted_at)');
          await customStatement('CREATE INDEX IF NOT EXISTS tx_wallet_idx ON transactions (wallet_id, deleted_at)');
          await customStatement('CREATE INDEX IF NOT EXISTS tx_to_wallet_idx ON transactions (to_wallet_id, deleted_at)');
          await customStatement('CREATE INDEX IF NOT EXISTS budgets_month_idx ON budgets (month_key, deleted_at)');
          // Update default wallet names to multi-language English identifiers if still using legacy Indonesian names
          await customStatement("UPDATE wallets SET name = 'Main Account' WHERE id = 'wallet-main' AND name = 'Rekening Utama'");
          await customStatement("UPDATE wallets SET name = 'Digital Bank' WHERE id = 'wallet-digital' AND name = 'Bank Digital'");
          await customStatement("UPDATE wallets SET name = 'Cash' WHERE id = 'wallet-cash' AND name = 'Tunai'");
          // Self-healing: pastikan tabel debts, debt_payments, pending_transactions, dan tx_templates selalu tersedia
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
            CREATE TABLE IF NOT EXISTS debt_payments (
              id TEXT NOT NULL PRIMARY KEY,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              deleted_at INTEGER,
              debt_id TEXT NOT NULL,
              amount INTEGER NOT NULL,
              date INTEGER NOT NULL,
              wallet_id TEXT,
              transaction_id TEXT,
              note TEXT NOT NULL DEFAULT ''
            );
          ''');
          await customStatement(
            'CREATE INDEX IF NOT EXISTS debt_payments_debt_idx ON debt_payments (debt_id, deleted_at)',
          );
          await _dropLegacyPendingTableIfIncompatible();
          await customStatement('''
            CREATE TABLE IF NOT EXISTS pending_transactions (
              id TEXT NOT NULL PRIMARY KEY,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              deleted_at INTEGER,
              recurring_rule_id TEXT,
              title TEXT NOT NULL,
              amount INTEGER NOT NULL,
              type TEXT NOT NULL,
              category_id TEXT NOT NULL,
              wallet_id TEXT,
              to_wallet_id TEXT,
              due_date INTEGER NOT NULL,
              note TEXT NOT NULL DEFAULT ''
            );
          ''');
          await customStatement(
            'CREATE INDEX IF NOT EXISTS pending_tx_rule_idx ON pending_transactions (recurring_rule_id, deleted_at)',
          );
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
          await _ensureSystemCategories();
        },
      );

  /// Hapus tabel legacy `pending_transactions` dari v1.11.14 ke bawah jika tidak punya
  /// kolom `updated_at` / `due_date`, agar skema v9 SyncColumns dapat dibuat bersih.
  Future<void> _dropLegacyPendingTableIfIncompatible() async {
    try {
      final cols = await customSelect("PRAGMA table_info('pending_transactions')").get();
      if (cols.isEmpty) return;
      final names = cols.map((c) => c.read<String>('name')).toSet();
      if (!names.contains('updated_at') || !names.contains('due_date')) {
        await customStatement('DROP TABLE IF EXISTS pending_transactions');
      }
    } catch (_) {}
  }

  /// Memastikan kategori sistem tambahan (`cat-exp-admin`, `cat-exp-savings`, `cat-inc-savings`)
  /// tersedia pada database lama tanpa menaikkan schemaVersion.
  Future<void> _ensureSystemCategories() async {
    const extraExpenseIds = {'cat-exp-admin', 'cat-exp-savings'};
    const extraIncomeIds = {'cat-inc-savings'};
    await batch((b) {
      b.insertAll(
        categories,
        [
          for (final s in _expenseSeed)
            if (extraExpenseIds.contains(s.$1)) _seedRow(s, TxType.expense),
          for (final s in _incomeSeed)
            if (extraIncomeIds.contains(s.$1)) _seedRow(s, TxType.income),
        ],
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

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
    final rows = await customSelect(
      'SELECT category_id, COUNT(*) AS cnt FROM transactions '
      'WHERE deleted_at IS NULL GROUP BY category_id',
      readsFrom: {transactions},
    ).get();
    return <String, int>{
      for (final row in rows)
        row.read<String>('category_id'): row.read<int>('cnt'),
    };
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

  /// Menghitung selisih arus kas bersih (net flow: income - expense - transfer_out + transfer_in)
  /// per dompet langsung melalui agregasi SQLite tanpa memuat seluruh riwayat transaksi ke memori Dart.
  Stream<Map<String, int>> watchWalletNetFlows() {
    return customSelect(
      '''
      SELECT wallet_id, SUM(delta) AS net_flow
      FROM (
        SELECT wallet_id,
               CASE
                 WHEN type = 'income' THEN amount
                 WHEN type IN ('expense', 'transfer') THEN -amount
                 ELSE 0
               END AS delta
        FROM transactions
        WHERE deleted_at IS NULL AND wallet_id IS NOT NULL
        UNION ALL
        SELECT to_wallet_id AS wallet_id,
               amount AS delta
        FROM transactions
        WHERE deleted_at IS NULL AND type = 'transfer' AND to_wallet_id IS NOT NULL
      )
      GROUP BY wallet_id
      ''',
      readsFrom: {transactions},
    ).watch().map((rows) {
      return <String, int>{
        for (final row in rows)
          if (row.readNullable<String>('wallet_id') != null)
            row.read<String>('wallet_id'): row.readNullable<int>('net_flow') ?? 0,
      };
    });
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

  /// Mencari transaksi langsung pada database SQLite berdasarkan catatan (note) atau kategori,
  /// dengan filter tipe transaksi, dompet, kategori, need/want, dan rentang tanggal opsional.
  Stream<List<TransactionEntry>> watchSearchTransactions({
    required String query,
    TxType? type,
    DateTime? start,
    DateTime? end,
    String? walletId,
    String? categoryId,
    NeedWant? needWant,
    List<String> matchedCategoryIds = const [],
    int limit = 250,
  }) {
    final trimmed = query.trim();
    final pattern = '%${trimmed.toLowerCase()}%';
    final q = select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId)),
    ]);

    q.where(transactions.deletedAt.isNull());

    if (trimmed.isNotEmpty) {
      Expression<bool> expr =
          transactions.note.lower().like(pattern) |
          categories.name.lower().like(pattern);
      if (matchedCategoryIds.isNotEmpty) {
        expr = expr | transactions.categoryId.isIn(matchedCategoryIds);
      }
      q.where(expr);
    }

    if (type != null) {
      q.where(transactions.type.equalsValue(type));
    }

    if (walletId != null) {
      q.where(
        transactions.walletId.equals(walletId) |
            transactions.toWalletId.equals(walletId),
      );
    }

    if (categoryId != null) {
      q.where(transactions.categoryId.equals(categoryId));
    }

    if (needWant != null) {
      q.where(transactions.needWant.equalsValue(needWant));
    }

    if (start != null) {
      q.where(transactions.date.isBiggerOrEqualValue(start));
    }
    if (end != null) {
      q.where(transactions.date.isSmallerThanValue(end));
    }

    q.orderBy([
      OrderingTerm.desc(transactions.date),
      OrderingTerm.desc(transactions.createdAt),
    ]);

    q.limit(limit);

    return q.watch().map((rows) => rows.map((row) => row.readTable(transactions)).toList());
  }

  Future<String> addTransaction({
    required int amount,
    required TxType type,
    required String categoryId,
    required DateTime date,
    String note = '',
    String? walletId,
    String? toWalletId,
    String? receiptPath,
    NeedWant? needWant,
  }) async {
    final txId = newId();
    await into(transactions).insert(TransactionsCompanion.insert(
      id: Value(txId),
      amount: amount,
      type: type,
      categoryId: categoryId,
      date: date,
      note: Value(note),
      walletId: Value(walletId ?? 'wallet-main'),
      toWalletId: Value(toWalletId),
      receiptPath: Value(receiptPath),
      needWant: Value(needWant),
    ));
    return txId;
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
    NeedWant? needWant,
    bool clearNeedWant = false,
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
        needWant: clearNeedWant
            ? const Value(null)
            : (needWant != null ? Value(needWant) : const Value.absent()),
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

  /// Mengembalikan transaksi yang di-soft-delete.
  Future<void> restoreTransaction(String id) async {
    await (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        deletedAt: const Value(null),
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

  /// Mengembalikan target tabungan yang di-soft-delete.
  Future<void> restoreSavingsGoal(String id) async {
    await (update(savingsGoals)..where((g) => g.id.equals(id))).write(
      SavingsGoalsCompanion(
        deletedAt: const Value(null),
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
  Future<Map<String, dynamic>> exportBackup({
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? budgetConfig,
  }) async {
    return {
      'app': 'wall_o_pay',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'preferences': ?preferences,
      'budgetConfig': ?budgetConfig,
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
      'debtPayments':
          (await select(debtPayments).get()).map((r) => r.toJson()).toList(),
      'pendingTransactions':
          (await select(pendingTransactions).get()).map((r) => r.toJson()).toList(),
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

  /// Hapus semua data di perangkat ini (termasuk file gambar struk & cache ekspor sementara),
  /// lalu isi ulang kategori bawaan.
  Future<void> resetAllData() async {
    final receiptPaths = <String>{};
    try {
      final rows = await (select(transactions)
            ..where((t) => t.receiptPath.isNotNull()))
          .get();
      for (final r in rows) {
        if (r.receiptPath != null && r.receiptPath!.isNotEmpty) {
          receiptPaths.add(r.receiptPath!);
        }
      }
    } catch (_) {}

    await transaction(() async {
      await delete(transactions).go();
      await delete(budgets).go();
      await delete(savingsGoals).go();
      await delete(recurringRules).go();
      try {
        await delete(debtPayments).go();
      } catch (e) {
        debugPrint('[AppDatabase] Warning resetting debtPayments: $e');
      }
      try {
        await delete(debts).go();
      } catch (e) {
        debugPrint('[AppDatabase] Warning resetting debts: $e');
      }
      try {
        await delete(pendingTransactions).go();
      } catch (e) {
        debugPrint('[AppDatabase] Warning resetting pendingTransactions: $e');
      }
      try {
        await delete(txTemplates).go();
      } catch (e) {
        debugPrint('[AppDatabase] Warning resetting txTemplates: $e');
      }
      await delete(categories).go();
      await delete(wallets).go();
      await _seedCategories();
      await _seedWallets();
    });

    await _purgeLocalSensitiveFiles(receiptPaths);
  }

  Future<void> _purgeLocalSensitiveFiles(Set<String> receiptPaths) async {
    if (kIsWeb) return;
    for (final path in receiptPaths) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    try {
      final supportDir = await getApplicationSupportDirectory();
      final sharedReceiptsDir = Directory('${supportDir.path}/shared_receipts');
      if (await sharedReceiptsDir.exists()) {
        await sharedReceiptsDir.delete(recursive: true);
      }
    } catch (_) {}
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list()) {
          final name = entity.uri.pathSegments.lastWhere(
            (s) => s.isNotEmpty,
            orElse: () => '',
          );
          if (entity is File && name.startsWith('wall_o_pay_')) {
            try {
              await entity.delete();
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
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
          name: 'debtPayments',
          changed: (since) async => (await (select(debtPayments)
                    ..where((r) => r.updatedAt.isBiggerThanValue(since)))
                  .get())
              .map((r) => r.toJson())
              .toList(),
          applyRemote: (json) async {
            final remote = DebtPayment.fromJson(json);
            final local = await (select(debtPayments)
                  ..where((r) => r.id.equals(remote.id)))
                .getSingleOrNull();
            if (local != null && !remote.updatedAt.isAfter(local.updatedAt)) {
              return false;
            }
            await into(debtPayments).insertOnConflictUpdate(remote);
            return true;
          },
        ),
        SyncTable(
          name: 'pendingTransactions',
          changed: (since) async => (await (select(pendingTransactions)
                    ..where((r) => r.updatedAt.isBiggerThanValue(since)))
                  .get())
              .map((r) => r.toJson())
              .toList(),
          applyRemote: (json) async {
            // Abaikan dokumen legacy pre-v9 yang tidak memiliki `title` / `dueDate`
            if (!json.containsKey('title') || !json.containsKey('dueDate')) {
              return false;
            }
            final remote = PendingTransaction.fromJson(json);
            final local = await (select(pendingTransactions)
                  ..where((r) => r.id.equals(remote.id)))
                .getSingleOrNull();
            if (local != null && !remote.updatedAt.isAfter(local.updatedAt)) {
              return false;
            }
            await into(pendingTransactions).insertOnConflictUpdate(remote);
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

  Future<void> updateRecurringRule(
    String id, {
    required String title,
    required int amount,
    required TxType type,
    required String categoryId,
    String? walletId,
    String? toWalletId,
    bool clearToWalletId = false,
    required RecurFrequency frequency,
    int? dayOfWeek,
    int? dayOfMonth,
    DateTime? nextDueDate,
    String note = '',
  }) async {
    await (update(recurringRules)..where((r) => r.id.equals(id))).write(
      RecurringRulesCompanion(
        title: Value(title),
        amount: Value(amount),
        type: Value(type),
        categoryId: Value(categoryId),
        walletId: Value(walletId ?? 'wallet-main'),
        toWalletId: clearToWalletId
            ? const Value(null)
            : (toWalletId != null ? Value(toWalletId) : const Value.absent()),
        frequency: Value(frequency),
        dayOfWeek: Value(dayOfWeek),
        dayOfMonth: Value(dayOfMonth),
        nextDueDate: nextDueDate != null ? Value(nextDueDate) : const Value.absent(),
        note: Value(note),
        updatedAt: Value(DateTime.now()),
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

  Future<void> restoreRecurringRule(String id) async {
    await (update(recurringRules)..where((r) => r.id.equals(id))).write(
      RecurringRulesCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pending Transactions (Antrean Konfirmasi Transaksi Berulang)
  // ---------------------------------------------------------------------------

  Stream<List<PendingTransaction>> watchPendingTransactions() =>
      (select(pendingTransactions)
            ..where((p) => p.deletedAt.isNull())
            ..orderBy([
              (p) => OrderingTerm.asc(p.dueDate),
              (p) => OrderingTerm.desc(p.createdAt),
            ]))
          .watch();

  Future<List<PendingTransaction>> getPendingTransactions() =>
      (select(pendingTransactions)
            ..where((p) => p.deletedAt.isNull())
            ..orderBy([(p) => OrderingTerm.asc(p.dueDate)]))
          .get();

  Future<String> addPendingTransaction({
    String? recurringRuleId,
    required String title,
    required int amount,
    required TxType type,
    required String categoryId,
    String? walletId,
    String? toWalletId,
    required DateTime dueDate,
    String note = '',
  }) async {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'Must be positive');
    }
    final id = newId();
    await into(pendingTransactions).insert(
      PendingTransactionsCompanion.insert(
        id: Value(id),
        recurringRuleId: Value(recurringRuleId),
        title: title,
        amount: amount,
        type: type,
        categoryId: categoryId,
        walletId: Value(walletId ?? 'wallet-main'),
        toWalletId: Value(toWalletId),
        dueDate: dueDate,
        note: Value(note),
      ),
    );
    return id;
  }

  Future<void> updatePendingTransaction(
    String id, {
    int? amount,
    String? walletId,
    String? toWalletId,
    String? note,
  }) async {
    await (update(pendingTransactions)..where((p) => p.id.equals(id))).write(
      PendingTransactionsCompanion(
        amount: amount != null && amount > 0 ? Value(amount) : const Value.absent(),
        walletId: walletId != null ? Value(walletId) : const Value.absent(),
        toWalletId: toWalletId != null ? Value(toWalletId) : const Value.absent(),
        note: note != null ? Value(note) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Konfirmasi dan catat transaksi tertunda ke buku kas resmi secara atomik.
  /// Mengembalikan data transaksi yang dicatat, atau `null` jika sudah dihapus/dikonfirmasi.
  Future<TransactionEntry?> confirmPendingTransaction(
    String pendingId, {
    DateTime? txDate,
    int? amountOverride,
    String? walletIdOverride,
    String? toWalletIdOverride,
    String? noteOverride,
  }) async {
    return transaction<TransactionEntry?>(() async {
      final pending = await (select(pendingTransactions)
            ..where((p) => p.id.equals(pendingId) & p.deletedAt.isNull()))
          .getSingleOrNull();
      if (pending == null) return null;

      final effectiveAmount = amountOverride ?? pending.amount;
      if (effectiveAmount <= 0) return null;
      final effectiveWallet = walletIdOverride ?? pending.walletId ?? 'wallet-main';
      final effectiveToWallet = toWalletIdOverride ?? pending.toWalletId;
      final effectiveNote = noteOverride ??
          (pending.note.isNotEmpty ? pending.note : pending.title);
      final effectiveDate = txDate ??
          DateTime(
            pending.dueDate.year,
            pending.dueDate.month,
            pending.dueDate.day,
          );

      final txId = newId();
      final effectiveCategory =
          pending.type == TxType.transfer ? 'cat-tra-transfer' : pending.categoryId;

      await into(transactions).insert(
        TransactionsCompanion.insert(
          id: Value(txId),
          amount: effectiveAmount,
          type: pending.type,
          categoryId: effectiveCategory,
          date: effectiveDate,
          note: Value(effectiveNote),
          walletId: Value(effectiveWallet),
          toWalletId: Value(pending.type == TxType.transfer ? effectiveToWallet : null),
        ),
      );

      final now = DateTime.now();
      await (update(pendingTransactions)..where((p) => p.id.equals(pendingId))).write(
        PendingTransactionsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      return (select(transactions)..where((t) => t.id.equals(txId))).getSingleOrNull();
    });
  }

  Future<void> dismissPendingTransaction(String id) async {
    await (update(pendingTransactions)..where((p) => p.id.equals(id))).write(
      PendingTransactionsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> restorePendingTransaction(String id) async {
    await (update(pendingTransactions)..where((p) => p.id.equals(id))).write(
      PendingTransactionsCompanion(
        deletedAt: const Value(null),
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

  /// Memperbarui data utang-piutang yang sudah ada, sekaligus menyesuaikan paidAmount jika melebihi nominal baru.
  Future<void> updateDebt(
    String id, {
    required String person,
    required DebtDirection direction,
    required int amount,
    DateTime? dueDate,
    bool clearDueDate = false,
    String note = '',
  }) async {
    final existing = await (select(debts)..where((x) => x.id.equals(id))).getSingleOrNull();
    final clampedPaid = existing != null && existing.paidAmount > amount ? amount : null;
    await (update(debts)..where((x) => x.id.equals(id))).write(
      DebtsCompanion(
        person: Value(person),
        direction: Value(direction),
        amount: Value(amount),
        paidAmount: clampedPaid != null ? Value(clampedPaid) : const Value.absent(),
        dueDate: clearDueDate
            ? const Value(null)
            : (dueDate != null ? Value(dueDate) : const Value.absent()),
        note: Value(note),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<List<DebtPayment>> watchDebtPayments(String debtId) {
    return (select(debtPayments)
          ..where((p) => p.debtId.equals(debtId) & p.deletedAt.isNull())
          ..orderBy([
            (p) => OrderingTerm.desc(p.date),
            (p) => OrderingTerm.desc(p.createdAt),
          ]))
        .watch();
  }

  /// Catat pembayaran sebagian atau pelunasan (tidak melebihi sisa utang) sekaligus
  /// menyimpan riwayat cicilan pada tabel [debtPayments].
  Future<void> addDebtPayment(
    String id,
    int amount, {
    DateTime? date,
    String? walletId,
    String? transactionId,
    String note = '',
  }) async {
    if (amount <= 0) return;
    await transaction(() async {
      final d = await (select(debts)..where((x) => x.id.equals(id))).getSingle();
      final remaining = (d.amount - d.paidAmount).clamp(0, d.amount).toInt();
      if (remaining <= 0) return;
      final applied = amount.clamp(0, remaining).toInt();
      if (applied <= 0) return;
      final now = DateTime.now();

      await into(debtPayments).insert(
        DebtPaymentsCompanion.insert(
          debtId: id,
          amount: applied,
          date: date ?? now,
          walletId: Value(walletId),
          transactionId: Value(transactionId),
          note: Value(note),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await (update(debts)..where((x) => x.id.equals(id))).write(
        DebtsCompanion(
          paidAmount: Value(d.paidAmount + applied),
          updatedAt: Value(now),
        ),
      );
    });
  }

  /// Catat cicilan utang beserta transaksi dompet tertaut (opsional) secara atomik.
  Future<void> recordDebtPayment({
    required String debtId,
    required int amount,
    required bool createWalletTransaction,
    String? walletId,
    String transactionNote = '',
    String paymentNote = '',
    DateTime? date,
  }) async {
    if (amount <= 0) return;
    await transaction(() async {
      final d = await (select(debts)..where((x) => x.id.equals(debtId))).getSingle();
      final remaining = (d.amount - d.paidAmount).clamp(0, d.amount).toInt();
      if (remaining <= 0) return;
      final applied = amount.clamp(0, remaining).toInt();
      if (applied <= 0) return;

      final now = date ?? DateTime.now();
      String? linkedTxId;
      if (createWalletTransaction) {
        linkedTxId = newId();
        final lent = d.direction == DebtDirection.lent;
        await into(transactions).insert(
          TransactionsCompanion.insert(
            id: Value(linkedTxId),
            amount: applied,
            type: lent ? TxType.income : TxType.expense,
            categoryId: lent ? 'cat-inc-other' : 'cat-exp-other',
            date: DateTime(now.year, now.month, now.day),
            note: Value(transactionNote),
            walletId: Value(walletId ?? 'wallet-main'),
          ),
        );
      }

      await into(debtPayments).insert(
        DebtPaymentsCompanion.insert(
          debtId: debtId,
          amount: applied,
          date: now,
          walletId: Value(createWalletTransaction ? (walletId ?? 'wallet-main') : null),
          transactionId: Value(linkedTxId),
          note: Value(paymentNote),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await (update(debts)..where((x) => x.id.equals(debtId))).write(
        DebtsCompanion(
          paidAmount: Value(d.paidAmount + applied),
          updatedAt: Value(now),
        ),
      );
    });
  }

  /// Hapus riwayat cicilan tertentu secara lunak dan kurangi `paidAmount` utang terkait.
  Future<void> deleteDebtPayment(String paymentId) async {
    await transaction(() async {
      final payment = await (select(debtPayments)
            ..where((p) => p.id.equals(paymentId) & p.deletedAt.isNull()))
          .getSingleOrNull();
      if (payment == null) return;

      final now = DateTime.now();
      await (update(debtPayments)..where((p) => p.id.equals(paymentId))).write(
        DebtPaymentsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final debt = await (select(debts)..where((d) => d.id.equals(payment.debtId)))
          .getSingleOrNull();
      if (debt != null) {
        final nextPaid = (debt.paidAmount - payment.amount).clamp(0, debt.amount).toInt();
        await (update(debts)..where((d) => d.id.equals(debt.id))).write(
          DebtsCompanion(
            paidAmount: Value(nextPaid),
            updatedAt: Value(now),
          ),
        );
      }

      if (payment.transactionId != null) {
        await (update(transactions)..where((t) => t.id.equals(payment.transactionId!)))
            .write(
          TransactionsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  /// Pulihkan riwayat cicilan utang yang baru dihapus (untuk fitur Undo).
  Future<void> restoreDebtPayment(String paymentId) async {
    await transaction(() async {
      final payment = await (select(debtPayments)..where((p) => p.id.equals(paymentId)))
          .getSingleOrNull();
      if (payment == null || payment.deletedAt == null) return;

      final now = DateTime.now();
      await (update(debtPayments)..where((p) => p.id.equals(paymentId))).write(
        DebtPaymentsCompanion(
          deletedAt: const Value(null),
          updatedAt: Value(now),
        ),
      );

      final debt = await (select(debts)..where((d) => d.id.equals(payment.debtId)))
          .getSingleOrNull();
      if (debt != null) {
        final nextPaid = (debt.paidAmount + payment.amount).clamp(0, debt.amount).toInt();
        await (update(debts)..where((d) => d.id.equals(debt.id))).write(
          DebtsCompanion(
            paidAmount: Value(nextPaid),
            updatedAt: Value(now),
          ),
        );
      }

      if (payment.transactionId != null) {
        await (update(transactions)..where((t) => t.id.equals(payment.transactionId!)))
            .write(
          TransactionsCompanion(
            deletedAt: const Value(null),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  Future<void> deleteDebt(String id) async {
    await (update(debts)..where((x) => x.id.equals(id))).write(
      DebtsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Mengembalikan catatan utang yang di-soft-delete.
  Future<void> restoreDebt(String id) async {
    await (update(debts)..where((x) => x.id.equals(id))).write(
      DebtsCompanion(
        deletedAt: const Value(null),
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
