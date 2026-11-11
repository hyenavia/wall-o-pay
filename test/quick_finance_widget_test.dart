import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/data/quick_widget_service.dart';
import 'package:wall_o_pay/data/tables.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Quick Finance Widget & Service Tests', () {
    final List<MethodCall> methodCalls = [];

    setUp(() {
      methodCalls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example.wall_o_pay/widget'),
        (MethodCall call) async {
          methodCalls.add(call);
          if (call.method == 'updateWidgetData') {
            return true;
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example.wall_o_pay/widget'),
        null,
      );
    });

    test('syncWidgetDataDirect sends balance and privacy flag via MethodChannel', () async {
      await syncWidgetDataDirect(
        totalBalance: 15000000,
        hideBalance: false,
      );

      expect(methodCalls.length, 1);
      expect(methodCalls.first.method, 'updateWidgetData');
      expect(methodCalls.first.arguments, {
        'balance': 15000000,
        'hideBalance': false,
      });

      // Test with privacy sensor enabled
      await syncWidgetDataDirect(
        totalBalance: 2500000,
        hideBalance: true,
      );

      expect(methodCalls.length, 2);
      expect(methodCalls.last.arguments, {
        'balance': 2500000,
        'hideBalance': true,
      });
    });

    test('Localization verifies Quick Finance strings in English and Indonesian', () {
      final en = AppStrings('en');
      final id = AppStrings('id');

      expect(en.tr('Quick Finance'), 'Quick Finance');
      expect(id.tr('Quick Finance'), 'Keuangan Cepat');

      expect(en.tr('Quick Finance Widget'), 'Quick Finance Widget');
      expect(id.tr('Quick Finance Widget'), 'Widget Keuangan Cepat');

      expect(en.tr('Record Transaction'), 'Record Transaction');
      expect(id.tr('Record Transaction'), 'Catat Transaksi');

      expect(en.tr('Save Transaction'), 'Save Transaction');
      expect(id.tr('Save Transaction'), 'Simpan Transaksi');
    });

    test('TxType enum contains all three Quick Finance transaction types', () {
      expect(TxType.values.contains(TxType.income), isTrue);
      expect(TxType.values.contains(TxType.expense), isTrue);
      expect(TxType.values.contains(TxType.transfer), isTrue);
    });
  });
}
