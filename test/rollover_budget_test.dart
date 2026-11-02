import 'package:flutter_test/flutter_test.dart';
import 'package:wall_o_pay/core/l10n.dart';

void main() {
  group('Rollover Budget Tests', () {
    test('Rollover bilingual localization strings in EN and ID', () {
      final stringsEn = AppStrings('en');
      final stringsId = AppStrings('id');

      expect(
        stringsEn.tr('Rollover active: +{amount} from last period', {'amount': 'Rp 200.000'}),
        'Rollover active: +Rp 200.000 from last period',
      );
      expect(
        stringsId.tr('Rollover active: +{amount} from last period', {'amount': 'Rp 200.000'}),
        'Rollover aktif: +Rp 200.000 dari periode lalu',
      );

      expect(
        stringsEn.tr('includes {amount} rollover', {'amount': 'Rp 50.000'}),
        'includes Rp 50.000 rollover',
      );
      expect(
        stringsId.tr('includes {amount} rollover', {'amount': 'Rp 50.000'}),
        'termasuk Rp 50.000 sisa lalu',
      );
    });

    test('Carryover math correctly calculates unspent positive amounts', () {
      final prevBudgets = {'cat-food': 500000, 'cat-trans': 200000, 'cat-bills': 300000};
      final prevSpent = {'cat-food': 350000, 'cat-trans': 250000, 'cat-bills': 300000};

      final carryOver = <String, int>{};
      for (final entry in prevBudgets.entries) {
        final spent = prevSpent[entry.key] ?? 0;
        final left = entry.value - spent;
        if (left > 0) carryOver[entry.key] = left;
      }

      expect(carryOver['cat-food'], 150000); // 500k - 350k = 150k
      expect(carryOver.containsKey('cat-trans'), isFalse); // overspent (200k - 250k <= 0)
      expect(carryOver.containsKey('cat-bills'), isFalse); // exact (300k - 300k = 0)

      final baseBudget = {'cat-food': 400000, 'cat-trans': 200000};
      final allKeys = {...baseBudget.keys, ...carryOver.keys};
      final effectiveBudget = {
        for (final k in allKeys) k: (baseBudget[k] ?? 0) + (carryOver[k] ?? 0),
      };

      expect(effectiveBudget['cat-food'], 550000); // 400k + 150k
      expect(effectiveBudget['cat-trans'], 200000);
    });
  });
}

