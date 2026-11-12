import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

      expect(stringsEn.tr('Weekly Summary'), 'Weekly Summary');
      expect(stringsId.tr('Weekly Summary'), 'Ringkasan Minggu Ini');

      expect(stringsEn.tr('Monthly Summary'), 'Monthly Summary');
      expect(stringsId.tr('Monthly Summary'), 'Ringkasan Bulan Ini');

      expect(stringsEn.tr('Insight'), 'Insight');
      expect(stringsId.tr('Insight'), 'Analisis');

      expect(stringsEn.tr('Financial Insights'), 'Financial Insights');
      expect(stringsId.tr('Financial Insights'), 'Analisis Finansial');

      expect(stringsEn.tr("This Week's Budget"), "This Week's Budget");
      expect(stringsId.tr("This Week's Budget"), 'Anggaran Minggu Ini');

      expect(stringsEn.tr("This Month's Budget"), "This Month's Budget");
      expect(stringsId.tr("This Month's Budget"), 'Anggaran Bulan Ini');

      expect(stringsId.tr('Food & Drinks'), 'Makanan & Minuman');
      expect(stringsId.tr('Main Account'), 'Rekening Utama');
      expect(stringsId.tr('Digital Bank'), 'Bank Digital');
      expect(stringsId.tr('Cash'), 'Tunai');
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

    testWidgets('Tapping status badge in Botanical opens Daily Financial Pulse Guide', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
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
      expect(find.text('How your quota is calculated'), findsOneWidget);
      expect(find.text('Phase 1: Safe Financial Health'), findsOneWidget);
      expect(find.text('Phase 2: Spending Velocity Warning'), findsOneWidget);
      expect(find.text('Phase 3: Budget Limit Reached'), findsOneWidget);
      expect(find.text('Condition: Daily spending < safe quota & budget healthy.'), findsOneWidget);
      expect(find.text('I Understand'), findsOneWidget);
    });

    testWidgets('Tapping status badge in Botanical (ID) displays Indonesian guide without mix', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('id'),
          supportedLocales: const [Locale('en'), Locale('id')],
          theme: buildTheme(),
          localizationsDelegates: const [
            AppStrings.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
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

      await tester.tap(find.text('Aman'));
      await tester.pumpAndSettle();

      expect(find.text('Panduan Ritme Keuangan Harian'), findsOneWidget);
      expect(find.text('Cara perhitungan kuota harianmu'), findsOneWidget);
      expect(find.text('Fase 1: Kondisi Finansial Aman'), findsOneWidget);
      expect(find.text('Fase 2: Laju Pengeluaran Meningkat'), findsOneWidget);
      expect(find.text('Fase 3: Batas Anggaran Tercapai'), findsOneWidget);
      expect(find.text('Kondisi: Belanja harian < kuota aman & anggaran terjaga.'), findsOneWidget);
      expect(find.text('Mengerti'), findsOneWidget);
    });

    test('calculateDailyPulse avoids false Limit when spending from wallet balance without period income or budget', () {
      final res = calculateDailyPulse(
        income: 0,
        expense: 30000,
        totalWalletBalance: 3000000,
        totalBudget: 0,
        budgetSpent: 0,
        todayExpense: 30000,
        daysLeft: 15,
        upcomingBills: 0,
        txCount: 1,
      );

      expect(res.tier, DailyHealthTier.safe);
      expect(res.fundingBasis, PulseFundingBasis.walletBalance);
      expect(res.dailyAllowance, 200000);
    });

    test('calculateDailyPulse deducts upcoming recurring bills from remaining budget before dividing by daysLeft', () {
      final res = calculateDailyPulse(
        income: 0,
        expense: 500000,
        totalWalletBalance: 5000000,
        totalBudget: 3000000,
        budgetSpent: 500000,
        todayExpense: 50000,
        daysLeft: 10,
        upcomingBills: 500000,
        txCount: 4,
      );

      expect(res.tier, DailyHealthTier.safe);
      expect(res.fundingBasis, PulseFundingBasis.periodBudget);
      expect(res.basisAmount, 2500000);
      expect(res.availablePool, 2000000);
      expect(res.dailyAllowance, 200000);
    });

    test('calculateDailyPulse triggers Limit when budget exhausted and Caution when upcoming bills consume remaining budget', () {
      final exhausted = calculateDailyPulse(
        income: 5000000,
        expense: 3000000,
        totalWalletBalance: 2000000,
        totalBudget: 3000000,
        budgetSpent: 3000000,
        todayExpense: 10000,
        daysLeft: 10,
        upcomingBills: 0,
        txCount: 12,
      );
      expect(exhausted.tier, DailyHealthTier.limit);

      final billsEatAll = calculateDailyPulse(
        income: 0,
        expense: 200000,
        totalWalletBalance: 2000000,
        totalBudget: 1000000,
        budgetSpent: 200000,
        todayExpense: 10000,
        daysLeft: 10,
        upcomingBills: 900000,
        txCount: 2,
      );
      expect(billsEatAll.tier, DailyHealthTier.caution);
      expect(billsEatAll.dailyAllowance, 0);
    });
  });
}

