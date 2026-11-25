/// Utilitas pemformatan mata uang global (default IDR / Rupiah), pemisah ribuan
/// pada input angka, label tanggal/waktu sesuai bahasa aktif, serta teks sapaan waktu.
library;

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'l10n.dart';

/// Metadata konfigurasi untuk tiap mata uang yang didukung aplikasi.
class AppCurrencyInfo {
  const AppCurrencyInfo({
    required this.code,
    required this.symbol,
    required this.numberLocale,
    required this.nameEn,
    required this.nameId,
    required this.quickSteps,
    required this.adminFees,
    required this.expenseAdminFees,
    required this.microThreshold,
  });

  final String code;
  final String symbol;
  final String numberLocale;
  final String nameEn;
  final String nameId;
  final List<int> quickSteps;
  final List<int> adminFees;
  final List<int> expenseAdminFees;
  final int microThreshold;

  String labelForLocale(String localeCode) =>
      localeCode == 'id' ? nameId : nameEn;

  String get inputPrefix => symbol.endsWith(' ') ? symbol : '$symbol ';
}

/// Registry mata uang aktif secara global (default `IDR`).
class AppCurrency {
  static String code = 'IDR';

  static const List<AppCurrencyInfo> supported = [
    AppCurrencyInfo(
      code: 'IDR',
      symbol: 'Rp ',
      numberLocale: 'id_ID',
      nameEn: 'Indonesian Rupiah',
      nameId: 'Rupiah Indonesia',
      quickSteps: [10000, 50000, 100000],
      adminFees: [1000, 2500, 6500],
      expenseAdminFees: [1000, 2500, 5000],
      microThreshold: 50000,
    ),
    AppCurrencyInfo(
      code: 'USD',
      symbol: '\$',
      numberLocale: 'en_US',
      nameEn: 'US Dollar',
      nameId: 'Dolar AS',
      quickSteps: [5, 20, 100],
      adminFees: [1, 2, 5],
      expenseAdminFees: [1, 2, 5],
      microThreshold: 10,
    ),
    AppCurrencyInfo(
      code: 'EUR',
      symbol: '€',
      numberLocale: 'de_DE',
      nameEn: 'Euro',
      nameId: 'Euro',
      quickSteps: [5, 20, 100],
      adminFees: [1, 2, 5],
      expenseAdminFees: [1, 2, 5],
      microThreshold: 10,
    ),
    AppCurrencyInfo(
      code: 'GBP',
      symbol: '£',
      numberLocale: 'en_GB',
      nameEn: 'British Pound',
      nameId: 'Pound Inggris',
      quickSteps: [5, 20, 100],
      adminFees: [1, 2, 5],
      expenseAdminFees: [1, 2, 5],
      microThreshold: 10,
    ),
    AppCurrencyInfo(
      code: 'SGD',
      symbol: 'S\$',
      numberLocale: 'en_SG',
      nameEn: 'Singapore Dollar',
      nameId: 'Dolar Singapura',
      quickSteps: [5, 20, 100],
      adminFees: [1, 2, 5],
      expenseAdminFees: [1, 2, 5],
      microThreshold: 15,
    ),
    AppCurrencyInfo(
      code: 'MYR',
      symbol: 'RM ',
      numberLocale: 'ms_MY',
      nameEn: 'Malaysian Ringgit',
      nameId: 'Ringgit Malaysia',
      quickSteps: [10, 50, 100],
      adminFees: [1, 2, 5],
      expenseAdminFees: [1, 2, 5],
      microThreshold: 25,
    ),
    AppCurrencyInfo(
      code: 'JPY',
      symbol: '¥',
      numberLocale: 'ja_JP',
      nameEn: 'Japanese Yen',
      nameId: 'Yen Jepang',
      quickSteps: [500, 1000, 5000],
      adminFees: [110, 220, 440],
      expenseAdminFees: [110, 220, 330],
      microThreshold: 1000,
    ),
  ];

  static final Map<String, AppCurrencyInfo> _byCode = {
    for (final c in supported) c.code: c,
  };

  static final Map<String, NumberFormat> _decimalFormats = {
    for (final c in supported)
      c.code: NumberFormat.decimalPattern(c.numberLocale),
  };

  static final NumberFormat _idrCurrency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String normalize(String? raw) {
    final upper = raw?.trim().toUpperCase();
    return (upper != null && _byCode.containsKey(upper)) ? upper : 'IDR';
  }

  static AppCurrencyInfo get current => _byCode[normalize(code)]!;

  static NumberFormat get decimalFormat => _decimalFormats[current.code]!;
}

/// Prefix teks simbol mata uang untuk field input (contoh: `'Rp '`, `'\$ '`).
String get currencyInputPrefix => AppCurrency.current.inputPrefix;

/// Label chip tambah cepat nominal sesuai mata uang dan bahasa aktif.
List<({int amount, String label})> currencyQuickChips() {
  final info = AppCurrency.current;
  final isId = AppLocale.code == 'id';
  return [
    for (final step in info.quickSteps)
      (
        amount: step,
        label: info.code == 'IDR'
            ? '+${step ~/ 1000}${isId ? 'rb' : 'K'}'
            : '+${info.symbol}${AppCurrency.decimalFormat.format(step)}',
      ),
  ];
}

/// Mengubah nilai integer menjadi teks mata uang aktif (default Rupiah: `15000` -> `"Rp 15.000"`).
String rupiah(int value) {
  final info = AppCurrency.current;
  if (info.code == 'IDR') {
    return AppCurrency._idrCurrency.format(value);
  }
  final sign = value < 0 ? '-' : '';
  return '$sign${info.symbol}${AppCurrency.decimalFormat.format(value.abs())}';
}

/// Format nominal ringkas untuk ruang sempit seperti chip dompet
/// (contoh: IDR `1500000` -> `"Rp 1,5jt"`, USD `1500` -> `"\$1.5K"`).
String compactRupiah(int value) {
  final info = AppCurrency.current;
  final abs = value.abs();
  final sign = value < 0 ? '-' : '';
  final isId = AppLocale.code == 'id';
  final useCommaDecimal = isId || info.code == 'EUR';

  String fmt(double n) {
    final rounded = (n * 10).round() / 10;
    final str = rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toStringAsFixed(1);
    return useCommaDecimal ? str.replaceAll('.', ',') : str;
  }

  if (abs >= 1000000000) {
    final suffix = info.code == 'IDR' && isId ? 'M' : 'B';
    return '$sign${info.symbol}${fmt(abs / 1000000000)}$suffix';
  }
  if (abs >= 1000000) {
    final suffix = info.code == 'IDR' && isId ? 'jt' : 'M';
    return '$sign${info.symbol}${fmt(abs / 1000000)}$suffix';
  }
  final kThreshold = info.code == 'IDR' ? 10000 : 1000;
  if (abs >= kThreshold) {
    final suffix = info.code == 'IDR' && isId ? 'rb' : 'K';
    return '$sign${info.symbol}${fmt(abs / 1000)}$suffix';
  }
  return rupiah(value);
}

/// Format tanggal lengkap dengan nama hari singkat (contoh: `"Kam, 5 Nov 2026"`).
String dateLabel(DateTime d) =>
    DateFormat('EEE, d MMM yyyy', AppLocale.code).format(d);

/// Format tanggal ringkas tanpa nama hari (contoh: `"5 Nov 2026"`).
String shortDate(DateTime d) =>
    DateFormat('d MMM yyyy', AppLocale.code).format(d);

/// Format tanggal beserta jam dan menit (contoh: `"5 Nov 2026, 14:30"`).
String dateTimeLabel(DateTime d) =>
    DateFormat('d MMM yyyy, HH:mm', AppLocale.code).format(d);

/// Format jam dan menit saja (contoh: `"14:30"`).
String timeLabel(DateTime d) => DateFormat('HH:mm', AppLocale.code).format(d);

/// "Today, 12 Apr 2025", "Yesterday, 11 Apr 2025", atau "Fri, 10 Apr 2025".
String dayHeader(DateTime d) {
  final now = DateTime.now();
  final today = DateTime.utc(now.year, now.month, now.day);
  final day = DateTime.utc(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return trG('Today, {date}', {'date': shortDate(d)});
  if (diff == 1) return trG('Yesterday, {date}', {'date': shortDate(d)});
  return dateLabel(d);
}

/// Menghasilkan sapaan sesuai jam lokal (Pagi, Siang, Sore, atau Malam) dalam bahasa aktif.
String greeting([int? hour]) {
  final h = hour ?? DateTime.now().hour;
  if (AppLocale.code == 'id') {
    if (h >= 5 && h < 11) return 'Selamat pagi';
    if (h >= 11 && h < 15) return 'Selamat siang';
    if (h >= 15 && h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }
  if (h >= 5 && h < 12) return 'Good morning';
  if (h >= 12 && h < 17) return 'Good afternoon';
  return 'Good evening';
}

/// 1500000 -> "1.500.000" / "1,500,000" (kosong jika 0).
String formatThousands(int value) =>
    value > 0 ? AppCurrency.decimalFormat.format(value) : '';

/// "1.500.000" / "1,500,000" -> 1500000.
int parseAmount(String text) =>
    int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

/// Memberi pemisah ribuan otomatis saat mengetik nominal sesuai format mata uang aktif.
class ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final text = AppCurrency.decimalFormat.format(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Gabungan formatter untuk field nominal (maks. 13 digit).
List<TextInputFormatter> amountFormatters() => [
  LengthLimitingTextInputFormatter(17),
  ThousandsInputFormatter(),
];
