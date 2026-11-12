/// Provider Riverpod tambahan untuk fitur lanjutan: alias akun/dompet, transaksi berulang,
/// utang-piutang, template, pencarian SQL langsung, dan perhitungan rollover anggaran.
library;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/period.dart';
import 'app_database.dart';
import 'feature_prefs.dart';
import 'providers.dart';
import 'tables.dart' show NeedWant, TxType;

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

final debtPaymentsProvider =
    StreamProvider.family<List<DebtPayment>, String>((ref, debtId) {
  return ref.watch(databaseProvider).watchDebtPayments(debtId);
});

final pendingTransactionsProvider = StreamProvider<List<PendingTransaction>>((ref) {
  return ref.watch(databaseProvider).watchPendingTransactions();
});

final templatesProvider = StreamProvider<List<TxTemplate>>((ref) {
  return ref.watch(databaseProvider).watchTemplates();
});

// ---------- Filter rentang tanggal & pencarian ----------

/// Transaksi pada rentang tanggal kustom ([range.end] inklusif).
final rangeTransactionsProvider =
    StreamProvider.family<List<TransactionEntry>, DateTimeRange>((ref, range) {
  final start = DateTime(range.start.year, range.start.month, range.start.day);
  final end = DateTime(range.end.year, range.end.month, range.end.day + 1);
  return ref.watch(databaseProvider).watchTransactionsBetween(start, end);
});

/// Parameter pencarian transaksi di database.
class TxSearchParams {
  const TxSearchParams({
    required this.query,
    this.type,
    this.range,
    this.walletId,
    this.categoryId,
    this.needWant,
    this.matchedCategoryIds = const [],
  });

  final String query;
  final TxType? type;
  final DateTimeRange? range;
  final String? walletId;
  final String? categoryId;
  final NeedWant? needWant;
  final List<String> matchedCategoryIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TxSearchParams &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          type == other.type &&
          range == other.range &&
          walletId == other.walletId &&
          categoryId == other.categoryId &&
          needWant == other.needWant &&
          listEquals(matchedCategoryIds, other.matchedCategoryIds);

  @override
  int get hashCode => Object.hash(
        query,
        type,
        range,
        walletId,
        categoryId,
        needWant,
        Object.hashAll(matchedCategoryIds),
      );
}

/// Pencarian transaksi berbasis query SQL langsung di database SQLite.
final searchTransactionsProvider =
    StreamProvider.family<List<TransactionEntry>, TxSearchParams>((ref, params) {
  final start = params.range != null
      ? DateTime(params.range!.start.year, params.range!.start.month, params.range!.start.day)
      : null;
  final end = params.range != null
      ? DateTime(params.range!.end.year, params.range!.end.month, params.range!.end.day + 1)
      : null;

  return ref.watch(databaseProvider).watchSearchTransactions(
        query: params.query,
        type: params.type,
        start: start,
        end: end,
        walletId: params.walletId,
        categoryId: params.categoryId,
        needWant: params.needWant,
        matchedCategoryIds: params.matchedCategoryIds,
      );
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

/// Total nominal sisa anggaran periode lalu yang dibawa ke periode ini.
final totalCarryOverProvider = Provider<int>((ref) {
  final carry = ref.watch(carryOverProvider);
  return carry.values.fold<int>(0, (sum, val) => sum + val);
});

/// Anggaran efektif = anggaran periode ini + sisa dari periode lalu.
final effectiveBudgetProvider = Provider<Map<String, int>>((ref) {
  final base = ref.watch(budgetByCategoryProvider);
  final carry = ref.watch(carryOverProvider);
  final allKeys = {...base.keys, ...carry.keys};
  return {
    for (final k in allKeys) k: (base[k] ?? 0) + (carry[k] ?? 0),
  };
});
