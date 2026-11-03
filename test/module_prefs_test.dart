import 'package:flutter_test/flutter_test.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/data/module_prefs.dart';

void main() {
  group('Module Preferences Tests', () {
    test('Default modules are all enabled', () {
      const prefs = ModulePrefs();
      expect(prefs.goals, isTrue);
      expect(prefs.debts, isTrue);
      expect(prefs.recurring, isTrue);
      expect(prefs.transfer, isTrue);
      expect(prefs.budget, isTrue);
      expect(prefs.activeCount, 5);
      expect(prefs.isEnabled('goals'), isTrue);
      expect(prefs.isEnabled('debts'), isTrue);
      expect(prefs.isEnabled('recurring'), isTrue);
      expect(prefs.isEnabled('transfer'), isTrue);
      expect(prefs.isEnabled('budget'), isTrue);
    });

    test('copyWith updates individual module flags accurately', () {
      const prefs = ModulePrefs();
      final updated = prefs.copyWith(
        goals: false,
        debts: false,
      );

      expect(updated.goals, isFalse);
      expect(updated.debts, isFalse);
      expect(updated.recurring, isTrue);
      expect(updated.transfer, isTrue);
      expect(updated.budget, isTrue);
      expect(updated.activeCount, 3);
    });

    test('Bilingual module strings exist in EN and ID', () {
      final stringsEn = AppStrings('en');
      final stringsId = AppStrings('id');

      expect(stringsEn.tr('Choose your features'), 'Choose your features');
      expect(stringsId.tr('Choose your features'), 'Pilih fitur yang kamu butuhkan');

      expect(stringsEn.tr('Active Modules & Features'), 'Active Modules & Features');
      expect(stringsId.tr('Active Modules & Features'), 'Modul & Fitur Aktif');

      expect(stringsEn.tr('Savings Goals'), 'Savings Goals');
      expect(stringsId.tr('Savings Goals'), 'Target Tabungan & Impian');

      expect(stringsEn.tr('Debts & Split Bills'), 'Debts & Split Bills');
      expect(stringsId.tr('Debts & Split Bills'), 'Utang & Patungan');

      expect(stringsEn.tr('Recurring Schedules'), 'Recurring Schedules');
      expect(stringsId.tr('Recurring Schedules'), 'Jadwal & Tagihan Rutin');

      expect(stringsEn.tr('Category Budgets'), 'Category Budgets');
      expect(stringsId.tr('Category Budgets'), 'Anggaran Kategori');

      expect(stringsEn.tr('All Features'), 'All Features');
      expect(stringsId.tr('All Features'), 'Semua Fitur');

      expect(stringsEn.tr('Minimalist'), 'Minimalist');
      expect(stringsId.tr('Minimalist'), 'Minimalis');
    });
  });
}

