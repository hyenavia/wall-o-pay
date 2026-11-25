import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';
import 'package:wall_o_pay/core/icons.dart';
import 'package:wall_o_pay/core/theme.dart';
import 'package:wall_o_pay/core/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Phosphor Duotone icon registry', () {
    test('every categoryIcons key has a non-null Phosphor Duotone mapping', () {
      for (final entry in categoryIcons.entries) {
        expect(
          phosphorForKey(entry.key),
          isNotNull,
          reason: 'Missing Phosphor Duotone mapping for category key "${entry.key}"',
        );
        expect(
          phosphorForIcon(entry.value),
          isNotNull,
          reason: 'Missing Phosphor Duotone mapping for IconData of "${entry.key}"',
        );
      }
    });

    test('wallet account keys resolve cleanly', () {
      for (final key in ['digital', 'bank', 'ewallet', 'cash', 'wallet']) {
        expect(phosphorForKey(key), isNotNull);
      }
    });
  });

  group('Phosphor Duotone widget adaptation', () {
    for (final entry in <String, ThemeData>{
      'Vice City Sunset (Dark)': buildDarkTheme(),
      'Vice City Daylight (Light)': buildLightTheme(),
    }.entries) {
      testWidgets('CategoryBadge and AppChip render PhosphorDuotoneIcon without Image in ${entry.key}', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: entry.value,
            home: Scaffold(
              body: Column(
                children: [
                  const CategoryBadge(
                    icon: Icons.restaurant,
                    categoryKey: 'restaurant',
                    color: Colors.teal,
                  ),
                  AppChip(
                    label: 'Coffee',
                    categoryKey: 'coffee',
                    icon: Icons.local_cafe,
                    selected: true,
                    onSelected: () {},
                  ),
                  AppChip(
                    label: 'Transfer',
                    duotoneIcon: PhosphorIconsDuotone.arrowsLeftRight,
                    selected: false,
                    onSelected: () {},
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(PhosphorDuotoneIcon), findsNWidgets(3));
        expect(find.byType(Image), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
