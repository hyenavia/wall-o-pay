import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/data/app_database.dart';
import 'package:wall_o_pay/data/providers.dart';
import 'package:wall_o_pay/data/quick_widget_service.dart';
import 'package:wall_o_pay/data/tables.dart';

class _TestSyncConsumer extends ConsumerWidget {
  const _TestSyncConsumer({required this.onReady});
  final void Function(WidgetRef ref) onReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onReady(ref);
    return const SizedBox.shrink();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Quick Finance Widget & Service Tests', () {
    final List<MethodCall> methodCalls = [];
    var mockDirtyFlag = false;

    setUp(() {
      methodCalls.clear();
      mockDirtyFlag = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example.wall_o_pay/widget'),
        (MethodCall call) async {
          methodCalls.add(call);
          if (call.method == 'updateWidgetData') {
            return true;
          }
          if (call.method == 'consumeNativeDbDirty') {
            final res = mockDirtyFlag;
            mockDirtyFlag = false;
            return res;
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

    test('syncWidgetDataDirect sends balance, locale, and masks balance when hidden', () async {
      await syncWidgetDataDirect(
        totalBalance: 15000000,
        hideBalance: false,
        locale: 'id',
      );

      expect(methodCalls.length, 1);
      expect(methodCalls.first.method, 'updateWidgetData');
      expect(methodCalls.first.arguments, {
        'balance': 15000000,
        'hideBalance': false,
        'locale': 'id',
      });

      // When hideBalance is true, balance passed across channel must be masked (0)
      await syncWidgetDataDirect(
        totalBalance: 2500000,
        hideBalance: true,
        locale: 'en',
      );

      expect(methodCalls.length, 2);
      expect(methodCalls.last.arguments, {
        'balance': 0,
        'hideBalance': true,
        'locale': 'en',
      });
    });

    testWidgets('checkNativeWidgetDbDirty notifies Drift tableUpdates when native write occurred', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      var tableUpdateTriggered = false;
      final sub = db.tableUpdates().listen((updates) {
        if (updates.any((u) => u.table == 'transactions')) {
          tableUpdateTriggered = true;
        }
      });
      addTearDown(sub.cancel);

      WidgetRef? capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: _TestSyncConsumer(onReady: (ref) => capturedRef = ref),
        ),
      );

      // Initially clean
      mockDirtyFlag = false;
      final firstCheck = await checkNativeWidgetDbDirty(capturedRef!);
      expect(firstCheck, isFalse);
      await tester.pump();
      expect(tableUpdateTriggered, isFalse);

      // Native widget wrote a transaction
      mockDirtyFlag = true;
      final secondCheck = await checkNativeWidgetDbDirty(capturedRef!);
      expect(secondCheck, isTrue);
      await tester.pump();
      expect(tableUpdateTriggered, isTrue);
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
