import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n.dart';
import 'app_database.dart';
import 'prefs.dart';
import 'providers.dart';
import 'tables.dart' show TxType;

/// Tiga pilar utama dalam metode penganggaran emas 50/30/20.
enum BudgetBucket {
  needs,
  wants,
  savings;

  String label(BuildContext context) {
    return switch (this) {
      BudgetBucket.needs => context.tr('Needs (50%)'),
      BudgetBucket.wants => context.tr('Wants (30%)'),
      BudgetBucket.savings => context.tr('Savings & Goals (20%)'),
    };
  }

  String shortName(BuildContext context) {
    return switch (this) {
      BudgetBucket.needs => context.tr('Needs'),
      BudgetBucket.wants => context.tr('Wants'),
      BudgetBucket.savings => context.tr('Savings'),
    };
  }

  double get ratio => switch (this) {
        BudgetBucket.needs => 0.50,
        BudgetBucket.wants => 0.30,
        BudgetBucket.savings => 0.20,
      };

  int get percentage => (ratio * 100).round();

  IconData get icon => switch (this) {
        BudgetBucket.needs => Icons.home_work_outlined,
        BudgetBucket.wants => Icons.local_activity_outlined,
        BudgetBucket.savings => Icons.savings_outlined,
      };

  Color get color => switch (this) {
        BudgetBucket.needs => const Color(0xFF2E7D32), // Forest Green
        BudgetBucket.wants => const Color(0xFFD87D2A), // Warm Amber / Coral
        BudgetBucket.savings => const Color(0xFF00897B), // Ocean Teal
      };
}

/// Pemetaan pintar bawaan jika kategori belum pernah dipindahkan oleh pengguna.
BudgetBucket defaultBucketForCategory(String categoryId, String categoryName) {
  final id = categoryId.toLowerCase();
  final name = categoryName.toLowerCase();

  // Kebutuhan (Needs - 50%)
  if (id.contains('food') ||
      name.contains('food') ||
      name.contains('makan') ||
      name.contains('minum') ||
      id.contains('transport') ||
      name.contains('transport') ||
      id.contains('housing') ||
      name.contains('rent') ||
      name.contains('bill') ||
      name.contains('sewa') ||
      name.contains('tagihan') ||
      name.contains('listrik') ||
      name.contains('air') ||
      id.contains('study') ||
      name.contains('educat') ||
      name.contains('kuliah') ||
      name.contains('sekolah') ||
      name.contains('pendidikan') ||
      id.contains('health') ||
      name.contains('health') ||
      name.contains('sehat') ||
      name.contains('obat')) {
    return BudgetBucket.needs;
  }

  // Tabungan & Investasi (Savings - 20%)
  if (id.contains('saving') ||
      name.contains('saving') ||
      name.contains('tabung') ||
      id.contains('invest') ||
      name.contains('invest') ||
      name.contains('darurat') ||
      name.contains('goals') ||
      name.contains('target')) {
    return BudgetBucket.savings;
  }

  // Sisanya masuk ke Keinginan (Wants - 30%): Belanja, Hiburan, Top Up, Game, Hobi, Lainnya
  return BudgetBucket.wants;
}

class BudgetRuleState {
  const BudgetRuleState({
    required this.totalPools,
    required this.categoryBuckets,
  });

  /// Map periodKey (contoh '2026-10' atau 'W2026-10-26') -> total nominal anggaran
  final Map<String, int> totalPools;

  /// Map categoryId -> kelompok 50/30/20 kustom
  final Map<String, BudgetBucket> categoryBuckets;

  BudgetBucket getBucketFor(Category c) {
    return categoryBuckets[c.id] ?? defaultBucketForCategory(c.id, c.name);
  }

  int getTotalBudget(String periodKey) => totalPools[periodKey] ?? 0;

  BudgetRuleState copyWith({
    Map<String, int>? totalPools,
    Map<String, BudgetBucket>? categoryBuckets,
  }) {
    return BudgetRuleState(
      totalPools: totalPools ?? this.totalPools,
      categoryBuckets: categoryBuckets ?? this.categoryBuckets,
    );
  }
}

class BudgetRuleNotifier extends Notifier<BudgetRuleState> {
  static const _kTotalPools = 'pref_budget_total_pools';
  static const _kCategoryBuckets = 'pref_budget_category_buckets';

  @override
  BudgetRuleState build() {
    final prefs = ref.watch(sharedPreferencesProvider);

    // Muat data total budget pools
    final poolsRaw = prefs.getString(_kTotalPools);
    final pools = <String, int>{};
    if (poolsRaw != null && poolsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(poolsRaw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          if (entry.value is num) {
            pools[entry.key] = (entry.value as num).toInt();
          }
        }
      } catch (_) {}
    }

    // Muat data kategori kelompok
    final bucketsRaw = prefs.getString(_kCategoryBuckets);
    final buckets = <String, BudgetBucket>{};
    if (bucketsRaw != null && bucketsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(bucketsRaw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final bucket = BudgetBucket.values.firstWhere(
            (b) => b.name == entry.value,
            orElse: () => BudgetBucket.wants,
          );
          buckets[entry.key] = bucket;
        }
      } catch (_) {}
    }

    return BudgetRuleState(totalPools: pools, categoryBuckets: buckets);
  }

  Future<void> setTotalBudget(String periodKey, int amount) async {
    final updated = Map<String, int>.from(state.totalPools);
    if (amount <= 0) {
      updated.remove(periodKey);
    } else {
      updated[periodKey] = amount;
    }
    state = state.copyWith(totalPools: updated);

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kTotalPools, jsonEncode(updated));
  }

  Future<void> setCategoryBucket(String categoryId, BudgetBucket bucket) async {
    final updated = Map<String, BudgetBucket>.from(state.categoryBuckets);
    updated[categoryId] = bucket;
    state = state.copyWith(categoryBuckets: updated);

    final prefs = ref.read(sharedPreferencesProvider);
    final encodable = updated.map((k, v) => MapEntry(k, v.name));
    await prefs.setString(_kCategoryBuckets, jsonEncode(encodable));
  }
}

final budgetRuleProvider =
    NotifierProvider<BudgetRuleNotifier, BudgetRuleState>(BudgetRuleNotifier.new);

/// Nominal total pool anggaran 50/30/20 untuk periode yang sedang dipilih.
final currentTotalBudgetPoolProvider = Provider<int>((ref) {
  final period = ref.watch(selectedPeriodProvider);
  final rule = ref.watch(budgetRuleProvider);
  return rule.getTotalBudget(period.key);
});

/// Data kalkulasi lengkap 50/30/20 untuk periode aktif.
class Budget503020Breakdown {
  const Budget503020Breakdown({
    required this.totalBudget,
    required this.needsBudget,
    required this.wantsBudget,
    required this.savingsBudget,
    required this.needsSpent,
    required this.wantsSpent,
    required this.savingsSpent,
    required this.totalSpent,
    required this.needsCategories,
    required this.wantsCategories,
    required this.savingsCategories,
  });

  final int totalBudget;

  final int needsBudget;
  final int wantsBudget;
  final int savingsBudget;

  final int needsSpent;
  final int wantsSpent;
  final int savingsSpent;
  final int totalSpent;

  final List<Category> needsCategories;
  final List<Category> wantsCategories;
  final List<Category> savingsCategories;

  double get overallRatio => totalBudget == 0 ? 0.0 : totalSpent / totalBudget;
  double get needsRatio => needsBudget == 0 ? 0.0 : needsSpent / needsBudget;
  double get wantsRatio => wantsBudget == 0 ? 0.0 : wantsSpent / wantsBudget;
  double get savingsRatio => savingsBudget == 0 ? 0.0 : savingsSpent / savingsBudget;
}

final budget503020BreakdownProvider = Provider<Budget503020Breakdown>((ref) {
  final period = ref.watch(selectedPeriodProvider);
  final rule = ref.watch(budgetRuleProvider);
  final catsAsync = ref.watch(categoriesProvider);
  final spent = ref.watch(spentByCategoryProvider);

  final totalPool = rule.getTotalBudget(period.key);

  final needsCats = <Category>[];
  final wantsCats = <Category>[];
  final savingsCats = <Category>[];

  var needsSpent = 0;
  var wantsSpent = 0;
  var savingsSpent = 0;

  final allCats = catsAsync.maybeWhen(
    data: (list) => list.where((c) => c.type == TxType.expense).toList(),
    orElse: () => const <Category>[],
  );

  for (final c in allCats) {
    final bucket = rule.getBucketFor(c);
    final catSpent = spent[c.id] ?? 0;
    switch (bucket) {
      case BudgetBucket.needs:
        needsCats.add(c);
        needsSpent += catSpent;
        break;
      case BudgetBucket.wants:
        wantsCats.add(c);
        wantsSpent += catSpent;
        break;
      case BudgetBucket.savings:
        savingsCats.add(c);
        savingsSpent += catSpent;
        break;
    }
  }

  // Hitung alokasi 50 / 30 / 20
  final needsBudget = (totalPool * 0.50).round();
  final wantsBudget = (totalPool * 0.30).round();
  final savingsBudget = totalPool > 0 ? (totalPool - needsBudget - wantsBudget) : 0;

  final totalSpent = needsSpent + wantsSpent + savingsSpent;

  return Budget503020Breakdown(
    totalBudget: totalPool,
    needsBudget: needsBudget,
    wantsBudget: wantsBudget,
    savingsBudget: savingsBudget,
    needsSpent: needsSpent,
    wantsSpent: wantsSpent,
    savingsSpent: savingsSpent,
    totalSpent: totalSpent,
    needsCategories: needsCats,
    wantsCategories: wantsCats,
    savingsCategories: savingsCats,
  );
});

