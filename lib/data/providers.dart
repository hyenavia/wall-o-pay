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
    final prefs = ref.read(appPrefsProvider);
    state = Period.containing(
      prefs.periodType,
      state,
      firstDayOfWeek: prefs.firstDayOfWeek,
    ).shift(n).start;
  }
}

final selectedAnchorProvider =
    NotifierProvider<SelectedAnchor, DateTime>(SelectedAnchor.new);

/// Periode yang sedang dilihat (satu bulan atau satu minggu).
final selectedPeriodProvider = Provider<Period>((ref) {
  final type = ref.watch(appPrefsProvider.select((p) => p.periodType));
  final firstDay = ref.watch(appPrefsProvider.select((p) => p.firstDayOfWeek));
  final anchor = ref.watch(selectedAnchorProvider);
  return Period.containing(type, anchor, firstDayOfWeek: firstDay);
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

/// Transaksi periode sebelumnya (untuk perbandingan periode di tab Insight).
final previousPeriodTransactionsProvider = StreamProvider<List<TransactionEntry>>((ref) {
  final period = ref.watch(selectedPeriodProvider).shift(-1);
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

/// Daftar dompet/rekening aktif.
final walletsProvider = StreamProvider<List<Wallet>>((ref) {
  return ref.watch(databaseProvider).watchWallets();
});

/// Map id dompet -> Wallet.
final walletMapProvider = Provider<Map<String, Wallet>>((ref) {
  return ref.watch(walletsProvider).maybeWhen(
        data: (list) => {for (final w in list) w.id: w},
        orElse: () => const <String, Wallet>{},
      );
});

/// Seluruh transaksi aktif (sepanjang waktu) untuk menghitung saldo dompet secara akurat.
final allTransactionsProvider = StreamProvider<List<TransactionEntry>>((ref) {
  return ref.watch(databaseProvider).watchAllTransactions();
});

/// Map id dompet -> saldo saat ini (initialBalance + income - expense + transfer_in - transfer_out).
final walletBalancesProvider = Provider<Map<String, int>>((ref) {
  final wallets = ref.watch(walletsProvider).value ?? const [];
  final txs = ref.watch(allTransactionsProvider).value ?? const [];

  final balances = <String, int>{
    for (final w in wallets) w.id: w.initialBalance,
  };

  for (final t in txs) {
    final walletId = t.walletId ?? 'wallet-main';
    if (t.type == TxType.income) {
      balances[walletId] = (balances[walletId] ?? 0) + t.amount;
    } else if (t.type == TxType.expense) {
      balances[walletId] = (balances[walletId] ?? 0) - t.amount;
    } else if (t.type == TxType.transfer) {
      balances[walletId] = (balances[walletId] ?? 0) - t.amount;
      if (t.toWalletId != null) {
        balances[t.toWalletId!] = (balances[t.toWalletId!] ?? 0) + t.amount;
      }
    }
  }

  return balances;
});

/// Total saldo dari seluruh dompet/rekening yang dimiliki.
final totalCurrentBalanceProvider = Provider<int>((ref) {
  final balances = ref.watch(walletBalancesProvider);
  return balances.values.fold<int>(0, (sum, val) => sum + val);
});


