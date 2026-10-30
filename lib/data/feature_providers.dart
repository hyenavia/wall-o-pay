import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/period.dart';
import 'app_database.dart';
import 'feature_prefs.dart';
import 'providers.dart';

// ---------- Akun ----------

final accountsProvider = walletsProvider;
final allAccountsProvider = walletsProvider;
final accountMapProvider = walletMapProvider;
final accountBalancesProvider = Provider<Map<String, int>>((ref) {
  return ref.watch(walletBalancesProvider);
});
final totalBalanceProvider = totalCurrentBalanceProvider;

// ---------- Berulang, utang, template ----------

final recurringRulesProvider = StreamProvider<List<RecurringRule>>((ref) {
  return ref.watch(databaseProvider).watchRecurringRules();
});

final debtsProvider = StreamProvider<List<Debt>>((ref) {
  return ref.watch(databaseProvider).watchDebts();
});

final templatesProvider = StreamProvider<List<TxTemplate>>((ref) {
  return ref.watch(databaseProvider).watchTemplates();
});

// ---------- Filter rentang tanggal ----------

/// Transaksi pada rentang tanggal kustom ([range.end] inklusif).
final rangeTransactionsProvider =
    StreamProvider.family<List<TransactionEntry>, DateTimeRange>((ref, range) {
  final start = DateTime(range.start.year, range.start.month, range.start.day);
  final end = DateTime(range.end.year, range.end.month, range.end.day + 1);
  return ref.watch(databaseProvider).watchTransactionsBetween(start, end);
});

// ---------- Periode sebelumnya (perbandingan dan rollover) ----------

final prevPeriodProvider = Provider<Period>((ref) {
  return ref.watch(selectedPeriodProvider).shift(-1);
});

final prevTransactionsProvider = StreamProvider<List<TransactionEntry>>((ref) {
  final p = ref.watch(prevPeriodProvider);
  return ref.watch(databaseProvider).watchTransactionsBetween(p.start, p.end);
});

final prevBudgetsProvider = StreamProvider<List<Budget>>((ref) {
  final p = ref.watch(prevPeriodProvider);
  return ref.watch(databaseProvider).watchBudgets(p.key);
});

/// Sisa anggaran periode lalu yang dibawa ke periode ini (jika rollover aktif).
final carryOverProvider = Provider<Map<String, int>>((ref) {
  if (!ref.watch(featurePrefsProvider.select((p) => p.rollover))) {
    return const <String, int>{};
  }
  final budgets = ref.watch(prevBudgetsProvider).maybeWhen(
        data: (l) => l,
        orElse: () => const <Budget>[],
      );
  final txs = ref.watch(prevTransactionsProvider).maybeWhen(
        data: (l) => l,
        orElse: () => const <TransactionEntry>[],
      );
  final spent = <String, int>{};
  for (final t in txs) {
    if (t.type.name == 'expense') {
      spent[t.categoryId] = (spent[t.categoryId] ?? 0) + t.amount;
    }
  }
  final result = <String, int>{};
  for (final b in budgets) {
    final left = b.amount - (spent[b.categoryId] ?? 0);
    if (left > 0) result[b.categoryId] = left;
  }
  return result;
});

/// Anggaran efektif = anggaran periode ini + sisa dari periode lalu.
final effectiveBudgetProvider = Provider<Map<String, int>>((ref) {
  final base = ref.watch(budgetByCategoryProvider);
  final carry = ref.watch(carryOverProvider);
  return {for (final e in base.entries) e.key: e.value + (carry[e.key] ?? 0)};
});
