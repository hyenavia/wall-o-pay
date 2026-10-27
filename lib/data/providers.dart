import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/period.dart';
import 'app_database.dart';
import 'prefs.dart';
import 'tables.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Tanggal acuan periode yang sedang dilihat. Kembali ke hari ini saat
/// pengguna mengganti mode bulanan/mingguan.
class SelectedAnchor extends Notifier<DateTime> {
  @override
  DateTime build() {
    ref.watch(appPrefsProvider.select((p) => p.periodType));
    return DateTime.now();
  }

  void step(int n) {
    final type = ref.read(appPrefsProvider).periodType;
    state = Period.containing(type, state).shift(n).start;
  }
}

final selectedAnchorProvider =
    NotifierProvider<SelectedAnchor, DateTime>(SelectedAnchor.new);

/// Periode yang sedang dilihat (satu bulan atau satu minggu).
final selectedPeriodProvider = Provider<Period>((ref) {
  final type = ref.watch(appPrefsProvider.select((p) => p.periodType));
  final anchor = ref.watch(selectedAnchorProvider);
  return Period.containing(type, anchor);
});

/// Tab aktif di navigasi bawah (0 Home, 1 Transactions, 2 Budget, 3 Goals).
class TabIndex extends Notifier<int> {
  @override
  int build() => 0;

  void set(int index) => state = index;
}

final tabIndexProvider = NotifierProvider<TabIndex, int>(TabIndex.new);

/// Kategori aktif (untuk pilihan di form dan daftar kategori).
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(databaseProvider).watchCategories();
});

final allCategoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(databaseProvider).watchAllCategories();
});

final transactionsProvider = StreamProvider<List<TransactionEntry>>((ref) {
  final period = ref.watch(selectedPeriodProvider);
  return ref
      .watch(databaseProvider)
      .watchTransactionsBetween(period.start, period.end);
});

/// Transaksi 6 periode terakhir (berakhir di periode terpilih), untuk grafik tren.
final trendTransactionsProvider = StreamProvider<List<TransactionEntry>>((ref) {
  final period = ref.watch(selectedPeriodProvider);
  return ref
      .watch(databaseProvider)
      .watchTransactionsBetween(period.shift(-5).start, period.end);
});

final budgetsProvider = StreamProvider<List<Budget>>((ref) {
  final period = ref.watch(selectedPeriodProvider);
  return ref.watch(databaseProvider).watchBudgets(period.key);
});

final savingsGoalsProvider = StreamProvider<List<SavingsGoal>>((ref) {
  return ref.watch(databaseProvider).watchSavingsGoals();
});

/// id kategori -> kategori (termasuk yang sudah dihapus, untuk nama dan ikon).
final categoryMapProvider = Provider<Map<String, Category>>((ref) {
  return ref.watch(allCategoriesProvider).maybeWhen(
        data: (list) => {for (final c in list) c.id: c},
        orElse: () => const <String, Category>{},
      );
});

/// id kategori -> nominal anggaran periode ini (hanya kategori yang masih aktif).
final budgetByCategoryProvider = Provider<Map<String, int>>((ref) {
  final cats = ref.watch(categoryMapProvider);
  return ref.watch(budgetsProvider).maybeWhen(
        data: (list) => {
          for (final b in list)
            if (cats[b.categoryId] != null && cats[b.categoryId]!.deletedAt == null)
              b.categoryId: b.amount,
        },
        orElse: () => const <String, int>{},
      );
});

/// id kategori -> total pengeluaran periode ini.
final spentByCategoryProvider = Provider<Map<String, int>>((ref) {
  return ref.watch(transactionsProvider).maybeWhen(
        data: (list) {
          final result = <String, int>{};
          for (final t in list) {
            if (t.type == TxType.expense) {
              result[t.categoryId] = (result[t.categoryId] ?? 0) + t.amount;
            }
          }
          return result;
        },
        orElse: () => const <String, int>{},
      );
});

/// Daftar transaksi otomatis dari notifikasi yang menunggu konfirmasi pengguna.
final pendingTransactionsProvider = StreamProvider<List<PendingTransaction>>((ref) {
  return ref.watch(databaseProvider).watchPendingTransactions();
});

