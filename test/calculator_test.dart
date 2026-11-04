import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wall_o_pay/core/calculator_sheet.dart';
import 'package:wall_o_pay/core/l10n.dart';

void main() {
  group('CalculatorSheet Logic & Keypad Tests', () {
    testWidgets('renders calculator keypad with digits, 000, and operators', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int? result;

      await tester.pumpWidget(
        MaterialApp(
          supportedLocales: AppLocale.supported,
          localizationsDelegates: const [AppStrings.delegate],
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showCalculatorSheet(context, initialValue: 15000);
                },
                child: const Text('Open Calc'),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open Calc'));
      await tester.pumpAndSettle();

      // Check keypad presence
      expect(find.text('000'), findsOneWidget);
      expect(find.text('+'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
      expect(find.text('×'), findsOneWidget);
      expect(find.text('÷'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);

      // Current value should display 15.000
      expect(find.textContaining('15.000'), findsWidgets);

      // Press '+' then '5' then '000'
      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('000'));
      await tester.pumpAndSettle();

      // Formula should contain 15.000 + 5.000
      expect(find.textContaining('15.000 + 5.000'), findsOneWidget);

      // Press Use Amount
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      // Result should be 20000
      expect(result, 20000);
    });

    testWidgets('calculator triple zero button works as expected', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int? result;

      await tester.pumpWidget(
        MaterialApp(
          supportedLocales: AppLocale.supported,
          localizationsDelegates: const [AppStrings.delegate],
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showCalculatorSheet(context);
                },
                child: const Text('Open Calc'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Calc'));
      await tester.pumpAndSettle();

      // Press 2 then 5 then 000
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('000'));
      await tester.pumpAndSettle();

      // Press Use Amount
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(result, 25000);
    });
  });
}
