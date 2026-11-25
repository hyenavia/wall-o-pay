import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_o_pay/core/format.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/data/prefs.dart';
import 'package:wall_o_pay/data/transaction_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('id');
  });

  tearDown(() {
    AppCurrency.code = 'IDR';
    AppLocale.code = 'en';
  });

  group('AppCurrency formatting & parsing', () {
    test('defaults to IDR with dot thousands separator', () {
      AppCurrency.code = 'IDR';
      AppLocale.code = 'id';
      expect(rupiah(150000), 'Rp 150.000');
      expect(compactRupiah(1500000), 'Rp 1,5jt');
      expect(formatThousands(1500000), '1.500.000');
      expect(currencyInputPrefix, 'Rp ');
    });

    test('supports global currencies (USD, EUR, MYR, JPY)', () {
      AppCurrency.code = 'USD';
      AppLocale.code = 'en';
      expect(rupiah(2500), '\$2,500');
      expect(compactRupiah(1500), '\$1.5K');
      expect(formatThousands(2500), '2,500');
      expect(parseAmount('2,500'), 2500);
      expect(currencyInputPrefix, '\$ ');

      AppCurrency.code = 'EUR';
      expect(rupiah(1200), '€1.200');
      expect(currencyInputPrefix, '€ ');

      AppCurrency.code = 'MYR';
      expect(rupiah(1200), 'RM 1,200');
      expect(currencyInputPrefix, 'RM ');

      AppCurrency.code = 'JPY';
      expect(rupiah(5000), '¥5,000');
      expect(currencyInputPrefix, '¥ ');
    });

    test('normalizes unknown currency codes safely back to IDR', () {
      expect(AppCurrency.normalize(null), 'IDR');
      expect(AppCurrency.normalize(''), 'IDR');
      expect(AppCurrency.normalize('XYZ'), 'IDR');
      expect(AppCurrency.normalize('usd'), 'USD');
    });
  });

  group('AppPrefsController currency persistence', () {
    test('saves, exports, and imports currencyCode', () async {
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
      );
      addTearDown(container.dispose);

      expect(container.read(appPrefsProvider).currencyCode, 'IDR');
      await container.read(appPrefsProvider.notifier).setCurrency('USD');
      expect(container.read(appPrefsProvider).currencyCode, 'USD');
      expect(AppCurrency.code, 'USD');

      final exported = container.read(appPrefsProvider.notifier).exportPreferences();
      expect(exported['currencyCode'], 'USD');

      await container.read(appPrefsProvider.notifier).importPreferences({
        ...exported,
        'currencyCode': 'SGD',
      });
      expect(container.read(appPrefsProvider).currencyCode, 'SGD');
      expect(AppCurrency.code, 'SGD');
    });
  });

  group('TransactionParser global currency extraction', () {
    test('extracts IDR and global currency amounts cleanly', () {
      expect(TransactionParser.extractAmount('Transfer Rp 50.000 berhasil'), 50000);
      expect(TransactionParser.extractAmount('Paid \$42.50 at Cafe'), 42);
      expect(TransactionParser.extractAmount('Invoice USD 1,250.00 paid'), 1250);
      expect(TransactionParser.extractAmount('Spent RM 85 at Mart'), 85);
      expect(TransactionParser.extractAmount('Order €120,00 confirmed'), 120);
      expect(TransactionParser.extractAmount('Ticket ¥3,500'), 3500);
    });
  });
}
