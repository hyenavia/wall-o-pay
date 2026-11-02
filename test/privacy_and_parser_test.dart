import 'package:flutter_test/flutter_test.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/data/lock.dart';
import 'package:wall_o_pay/data/tables.dart';
import 'package:wall_o_pay/data/transaction_parser.dart';

void main() {
  group('TransactionParser Tests', () {
    test('extractAmount correctly extracts Rupiah values', () {
      expect(TransactionParser.extractAmount('Transfer sebesar Rp 50.000 berhasil'), 50000);
      expect(TransactionParser.extractAmount('Pembayaran IDR 125.500,00 ke Kopi Kenangan'), 125500);
      expect(TransactionParser.extractAmount('Total: Rp1.250.000'), 1250000);
      expect(TransactionParser.extractAmount('Tidak ada nominal'), isNull);
    });

    test('detectSourceApp identifies known banks and e-wallets', () {
      expect(TransactionParser.detectSourceApp('Transaksi GoPay berhasil'), 'GoPay');
      expect(TransactionParser.detectSourceApp('Transfer Livin by Mandiri'), "Livin' Mandiri");
      expect(TransactionParser.detectSourceApp('Kirim uang via DANA'), 'DANA');
      expect(TransactionParser.detectSourceApp('QRIS BCA selesai'), 'BCA');
      expect(TransactionParser.detectSourceApp('Unknown random text'), 'Bank / E-Wallet');
    });

    test('detectType identifies income vs expense correctly', () {
      expect(TransactionParser.detectType('Transfer masuk dari Budi Rp 100.000'), TxType.income);
      expect(TransactionParser.detectType('Pembayaran QRIS Rp 25.000 berhasil'), TxType.expense);
    });

    test('suggestCategory categorizes common merchant spending', () {
      expect(TransactionParser.suggestCategory('Bayar kopi di Starbucks', TxType.expense)?.$2, 'Food & Drinks');
      expect(TransactionParser.suggestCategory('Perjalanan naik Grab Car', TxType.expense)?.$2, 'Transport');
      expect(TransactionParser.suggestCategory('Tagihan listrik PLN', TxType.expense)?.$2, 'Rent & Bills');
      expect(TransactionParser.suggestCategory('Beli baju di Shopee', TxType.expense)?.$2, 'Shopping');
    });
  });

  group('Privacy Shield & AppLockState Tests', () {
    test('AppLockState has correct defaults and preserves privacyShield value', () {
      const state = AppLockState();
      expect(state.enabled, isFalse);
      expect(state.delayMin, 1);
      expect(state.privacyShield, isFalse);

      const shieldedState = AppLockState(enabled: true, delayMin: 5, privacyShield: true);
      expect(shieldedState.enabled, isTrue);
      expect(shieldedState.delayMin, 5);
      expect(shieldedState.privacyShield, isTrue);
    });

    test('Privacy Shield bilingual localization in EN and ID', () {
      final stringsEn = AppStrings('en');
      final stringsId = AppStrings('id');

      expect(stringsEn.tr('Privacy Shield'), 'Privacy Shield');
      expect(stringsId.tr('Privacy Shield'), 'Perisai Privasi');

      const desc = 'Hide app preview in Recent Apps switcher and block screenshots.';
      expect(stringsEn.tr(desc), desc);
      expect(stringsId.tr(desc), 'Sembunyikan pratinjau di Recent Apps dan cegah tangkapan layar.');
    });
  });
}
