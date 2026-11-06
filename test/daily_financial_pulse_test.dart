import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/core/theme.dart';
import 'package:wall_o_pay/features/home/daily_financial_pulse_card.dart';

void main() {
  group('Daily Financial Pulse Tests', () {
    test('Daily Health Tier accurately classifies Safe, Caution, and Limit states', () {
      // 1. Safe state: within budget and safe allowance
      const safeCard = DailyFinancialPulseCard(
        dailyAllowance: 100000,
        todayExpense: 35000,
        daysLeft: 15,
        balance: 1500000,
        totalBudget: 3000000,
        budgetSpent: 1000000,
        txCount: 10,
      );
      expect(safeCard.tier, DailyHealthTier.safe);

      // 2. Caution state (over daily allowance)
      const cautionCardOverDaily = DailyFinancialPulseCard(
        dailyAllowance: 100000,
        todayExpense: 150000,
        daysLeft: 15,
        balance: 1500000,
        totalBudget: 3000000,
        budgetSpent: 1000000,
        txCount: 10,
      );
      expect(cautionCardOverDaily.tier, DailyHealthTier.caution);

      // 3. Caution state (near budget limit >= 85%)
      const cautionCardNearBudget = DailyFinancialPulseCard(
        dailyAllowance: 100000,
        todayExpense: 20000,
        daysLeft: 15,
        balance: 1500000,
        totalBudget: 1000000,
        budgetSpent: 880000,
        txCount: 10,
      );
      expect(cautionCardNearBudget.tier, DailyHealthTier.caution);

      // 4. Limit state (negative balance with transactions)
      const limitCardNegativeBalance = DailyFinancialPulseCard(
        dailyAllowance: 0,
        todayExpense: 50000,
        daysLeft: 10,
        balance: -200000,
        totalBudget: 1000000,
        budgetSpent: 1200000,
        txCount: 12,
      );
      expect(limitCardNegativeBalance.tier, DailyHealthTier.limit);

      // 5. Limit state (total budget exhausted)
      const limitCardBudgetExhausted = DailyFinancialPulseCard(
        dailyAllowance: 50000,
        todayExpense: 10000,
        daysLeft: 10,
        balance: 200000,
        totalBudget: 1000000,
        budgetSpent: 1000000,
        txCount: 8,
      );
      expect(limitCardBudgetExhausted.tier, DailyHealthTier.limit);
    });

    test('Bilingual strings for Daily Financial Pulse exist in EN and ID', () {
      final stringsEn = AppStrings('en');
      final stringsId = AppStrings('id');

      expect(stringsEn.tr('Safe'), 'Safe');
      expect(stringsId.tr('Safe'), 'Aman');

      expect(stringsEn.tr('Caution'), 'Caution');
      expect(stringsId.tr('Caution'), 'Waspada');

      expect(stringsEn.tr('Limit'), 'Limit');
      expect(stringsId.tr('Limit'), 'Batas');

      expect(stringsEn.tr('Finances on Track'), 'Finances on Track');
      expect(stringsId.tr('Finances on Track'), 'Kondisi Finansial Terkendali');

      expect(stringsEn.tr('Safe daily quota'), 'Safe daily quota');
      expect(stringsId.tr('Safe daily quota'), 'Kuota aman harian');

      expect(stringsEn.tr('Spent today'), 'Spent today');
      expect(stringsId.tr('Spent today'), 'Belanja hari ini');
    });

    testWidgets('Renders DailyFinancialPulseCard with status badge and progress', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [AppStrings.delegate],
          home: const Scaffold(
            body: DailyFinancialPulseCard(
              dailyAllowance: 100000,
              todayExpense: 40000,
              daysLeft: 10,
              balance: 1000000,
              totalBudget: 2000000,
              budgetSpent: 500000,
              txCount: 5,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Safe'), findsOneWidget);
      expect(find.text('Finances on Track'), findsOneWidget);
      expect(find.text('Safe daily quota'), findsOneWidget);
      expect(find.text('Spent today'), findsOneWidget);
      expect(find.text('40% of quota'), findsOneWidget);
    });

    testWidgets('Renders DailyFinancialPulseCard with Cyberpunk telemetry', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme('cyberpunk'),
          localizationsDelegates: const [AppStrings.delegate],
          home: const Scaffold(
            body: DailyFinancialPulseCard(
              dailyAllowance: 100000,
              todayExpense: 40000,
              daysLeft: 10,
              balance: 1000000,
              totalBudget: 2000000,
              budgetSpent: 500000,
              txCount: 5,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('GRID STABLE'), findsOneWidget);
      expect(find.text('Cyber Telemetry Nominal'), findsOneWidget);
      expect(find.text('Daily Bandwidth'), findsOneWidget);
      expect(find.text('Burned today'), findsOneWidget);
      expect(find.text('40% bandwidth consumed'), findsOneWidget);

      // Tap on the status badge to verify phase info sheet opens
      await tester.tap(find.text('GRID STABLE'));
      await tester.pumpAndSettle();

      expect(find.text('GRID TELEMETRY PROTOCOL'), findsOneWidget);
      expect(find.text('Phase 01 // Subroutines Nominal'), findsOneWidget);
      expect(find.text('Phase 02 // Velocity Warning'), findsOneWidget);
      expect(find.text('Phase 03 // Critical Capacity'), findsOneWidget);
      expect(find.text('ACKNOWLEDGE // DISMISS'), findsOneWidget);
    });

    testWidgets('Tapping status badge in Botanical opens Daily Financial Pulse Guide', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme('botanical'),
          localizationsDelegates: const [AppStrings.delegate],
          home: const Scaffold(
            body: DailyFinancialPulseCard(
              dailyAllowance: 100000,
              todayExpense: 40000,
              daysLeft: 10,
              balance: 1000000,
              totalBudget: 2000000,
              budgetSpent: 500000,
              txCount: 5,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Safe'));
      await tester.pumpAndSettle();

      expect(find.text('Daily Financial Pulse Guide'), findsOneWidget);
      expect(find.text('I Understand'), findsOneWidget);
    });
  });
}

