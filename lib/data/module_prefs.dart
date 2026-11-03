import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs.dart';

/// Preferensi modul aplikasi yang dapat diaktifkan atau dinonaktifkan oleh pengguna.
class ModulePrefs {
  const ModulePrefs({
    this.goals = true,
    this.debts = true,
    this.recurring = true,
    this.transfer = true,
    this.budget = true,
  });

  final bool goals;
  final bool debts;
  final bool recurring;
  final bool transfer;
  final bool budget;

  bool isEnabled(String key) {
    switch (key) {
      case 'goals':
        return goals;
      case 'debts':
        return debts;
      case 'recurring':
        return recurring;
      case 'transfer':
        return transfer;
      case 'budget':
        return budget;
      default:
        return true;
    }
  }

  int get activeCount {
    var count = 0;
    if (goals) count++;
    if (debts) count++;
    if (recurring) count++;
    if (transfer) count++;
    if (budget) count++;
    return count;
  }

  ModulePrefs copyWith({
    bool? goals,
    bool? debts,
    bool? recurring,
    bool? transfer,
    bool? budget,
  }) {
    return ModulePrefs(
      goals: goals ?? this.goals,
      debts: debts ?? this.debts,
      recurring: recurring ?? this.recurring,
      transfer: transfer ?? this.transfer,
      budget: budget ?? this.budget,
    );
  }
}

class ModulePrefsController extends Notifier<ModulePrefs> {
  static const _kGoals = 'pref_module_goals';
  static const _kDebts = 'pref_module_debts';
  static const _kRecurring = 'pref_module_recurring';
  static const _kTransfer = 'pref_module_transfer';
  static const _kBudget = 'pref_module_budget';

  @override
  ModulePrefs build() {
    final p = ref.read(sharedPreferencesProvider);
    return ModulePrefs(
      goals: p.getBool(_kGoals) ?? true,
      debts: p.getBool(_kDebts) ?? true,
      recurring: p.getBool(_kRecurring) ?? true,
      transfer: p.getBool(_kTransfer) ?? true,
      budget: p.getBool(_kBudget) ?? true,
    );
  }

  Future<void> setModule(String key, bool enabled) async {
    final p = ref.read(sharedPreferencesProvider);
    switch (key) {
      case 'goals':
        state = state.copyWith(goals: enabled);
        await p.setBool(_kGoals, enabled);
        break;
      case 'debts':
        state = state.copyWith(debts: enabled);
        await p.setBool(_kDebts, enabled);
        break;
      case 'recurring':
        state = state.copyWith(recurring: enabled);
        await p.setBool(_kRecurring, enabled);
        break;
      case 'transfer':
        state = state.copyWith(transfer: enabled);
        await p.setBool(_kTransfer, enabled);
        break;
      case 'budget':
        state = state.copyWith(budget: enabled);
        await p.setBool(_kBudget, enabled);
        break;
    }
  }

  Future<void> setAll({
    required bool goals,
    required bool debts,
    required bool recurring,
    required bool transfer,
    required bool budget,
  }) async {
    state = ModulePrefs(
      goals: goals,
      debts: debts,
      recurring: recurring,
      transfer: transfer,
      budget: budget,
    );
    final p = ref.read(sharedPreferencesProvider);
    await p.setBool(_kGoals, goals);
    await p.setBool(_kDebts, debts);
    await p.setBool(_kRecurring, recurring);
    await p.setBool(_kTransfer, transfer);
    await p.setBool(_kBudget, budget);
  }
}

final modulePrefsProvider =
    NotifierProvider<ModulePrefsController, ModulePrefs>(ModulePrefsController.new);

