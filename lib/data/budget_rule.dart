import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n.dart';
import 'app_database.dart';
import 'prefs.dart';
import 'providers.dart';
import 'tables.dart' show TxType;

/// Tiga pilar utama dalam metode penganggaran emas 50/30/20 (atau kustom nominal).
enum BudgetBucket {
  needs,
  wants,
  savings;

  String label(BuildContext context, [int? customPercentage]) {
    final pct = customPercentage ?? percentage;
    return switch (this) {
      BudgetBucket.needs => '${context.tr('Needs')} ($pct%)',
      BudgetBucket.wants => '${context.tr('Wants')} ($pct%)',
      BudgetBucket.savings => '${context.tr('Savings & Goals')} ($pct%)',
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
    required this.customAllocations,
  });

  /// Map periodKey -> total nominal anggaran
  final Map<String, int> totalPools;

  /// Map categoryId -> kelompok kustom
  final Map<String, BudgetBucket> categoryBuckets;

  /// Map periodKey -> alokasi nominal kustom (needs, wants, savings)
  final Map<String, Map<String, int>> customAllocations;

  BudgetBucket getBucketFor(Category c) {
    return categoryBuckets[c.id] ?? defaultBucketForCategory(c.id, c.name);
  }

  int getTotalBudget(String periodKey) => totalPools[periodKey] ?? 0;

  Map<String, int>? getCustomAllocation(String periodKey) => customAllocations[periodKey];

  BudgetRuleState copyWith({
    Map<String, int>? totalPools,
    Map<String, BudgetBucket>? categoryBuckets,
    Map<String, Map<String, int>>? customAllocations,
  }) {
    return BudgetRuleState(
      totalPools: totalPools ?? this.totalPools,
      categoryBuckets: categoryBuckets ?? this.categoryBuckets,
      customAllocations: customAllocations ?? this.customAllocations,
    );
  }
}

class BudgetRuleNotifier extends Notifier<BudgetRuleState> {
  static const _kTotalPools = 'pref_budget_total_pools';
  static const _kCategoryBuckets = 'pref_budget_category_buckets';
  static const _kCustomAllocations = 'pref_budget_custom_allocations';

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

    // Muat data alokasi nominal kustom
    final customRaw = prefs.getString(_kCustomAllocations);
    final customAlloc = <String, Map<String, int>>{};
    if (customRaw != null && customRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(customRaw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          if (entry.value is Map) {
            final inner = <String, int>{};
            for (final sub in (entry.value as Map).entries) {
              if (sub.value is num) {
                inner[sub.key.toString()] = (sub.value as num).toInt();
              }
            }
            customAlloc[entry.key] = inner;
          }
        }
      } catch (_) {}
    }

    return BudgetRuleState(
      totalPools: pools,
      categoryBuckets: buckets,
      customAllocations: customAlloc,
    );
  }

  Future<void> setTotalBudget(String periodKey, int amount) async {
    final updated = Map<String, int>.from(state.totalPools);
    final updatedCustom = Map<String, Map<String, int>>.from(state.customAllocations);

    if (amount <= 0) {
      updated.remove(periodKey);
      updatedCustom.remove(periodKey);
    } else {
      updated[periodKey] = amount;
      // Jika sebelumnya ada alokasi kustom yang totalnya berbeda, reset ke standar proporsional
      updatedCustom.remove(periodKey);
    }
    state = state.copyWith(totalPools: updated, customAllocations: updatedCustom);

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kTotalPools, jsonEncode(updated));
    await prefs.setString(_kCustomAllocations, jsonEncode(updatedCustom));
  }

  Future<void> setCustomAllocations(
    String periodKey, {
    required int total,
    required int needs,
    required int wants,
    required int savings,
  }) async {
    final updated = Map<String, int>.from(state.totalPools);
    final updatedCustom = Map<String, Map<String, int>>.from(state.customAllocations);

    updated[periodKey] = total;
    updatedCustom[periodKey] = {
      'needs': needs,
      'wants': wants,
      'savings': savings,
    };

    state = state.copyWith(totalPools: updated, customAllocations: updatedCustom);

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kTotalPools, jsonEncode(updated));
    await prefs.setString(_kCustomAllocations, jsonEncode(updatedCustom));
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

/// Nominal total pool anggaran untuk periode yang sedang dipilih.
final currentTotalBudgetPoolProvider = Provider<int>((ref) {
  final period = ref.watch(selectedPeriodProvider);
  final rule = ref.watch(budgetRuleProvider);
  return rule.getTotalBudget(period.key);
});

/// Data kalkulasi lengkap 50/30/20 (atau alokasi nominal kustom) untuk periode aktif.
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
    required this.isCustom,
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

  final bool isCustom;

  double get overallRatio => totalBudget == 0 ? 0.0 : totalSpent / totalBudget;
  double get needsRatio => needsBudget == 0 ? 0.0 : needsSpent / needsBudget;
  double get wantsRatio => wantsBudget == 0 ? 0.0 : wantsSpent / wantsBudget;
  double get savingsRatio => savingsBudget == 0 ? 0.0 : savingsSpent / savingsBudget;

  int get needsPercentage =>
      totalBudget > 0 ? (needsBudget / totalBudget * 100).round() : 50;
  int get wantsPercentage =>
      totalBudget > 0 ? (wantsBudget / totalBudget * 100).round() : 30;
  int get savingsPercentage =>
      totalBudget > 0 ? (savingsBudget / totalBudget * 100).round() : 20;
}

final budget503020BreakdownProvider = Provider<Budget503020Breakdown>((ref) {
  final period = ref.watch(selectedPeriodProvider);
  final rule = ref.watch(budgetRuleProvider);
  final catsAsync = ref.watch(categoriesProvider);
  final spent = ref.watch(spentByCategoryProvider);

  final totalPool = rule.getTotalBudget(period.key);
  final custom = rule.getCustomAllocation(period.key);

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

  // Hitung alokasi (apakah kustom atau standar 50/30/20)
  int needsBudget;
  int wantsBudget;
  int savingsBudget;
  final bool isCustom = custom != null;

  if (custom != null) {
    needsBudget = custom['needs'] ?? (totalPool * 0.50).round();
    wantsBudget = custom['wants'] ?? (totalPool * 0.30).round();
    savingsBudget = custom['savings'] ?? (totalPool * 0.20).round();
  } else {
    needsBudget = (totalPool * 0.50).round();
    wantsBudget = (totalPool * 0.30).round();
    savingsBudget = totalPool > 0 ? (totalPool - needsBudget - wantsBudget) : 0;
  }

  final effectiveTotal = needsBudget + wantsBudget + savingsBudget;
  final totalSpent = needsSpent + wantsSpent + savingsSpent;

  return Budget503020Breakdown(
    totalBudget: effectiveTotal > 0 ? effectiveTotal : totalPool,
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
    isCustom: isCustom,
  );
});
