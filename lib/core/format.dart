import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'l10n.dart';

// Mata uang selalu Rupiah dengan pemisah ribuan titik (format Indonesia),
// sedangkan teks tanggal mengikuti bahasa yang dipilih.
final NumberFormat _rupiah =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
final NumberFormat _thousands = NumberFormat.decimalPattern('id_ID');

String rupiah(int value) => _rupiah.format(value);

String dateLabel(DateTime d) =>
    DateFormat('EEE, d MMM yyyy', AppLocale.code).format(d);

String shortDate(DateTime d) =>
    DateFormat('d MMM yyyy', AppLocale.code).format(d);

String dateTimeLabel(DateTime d) =>
    DateFormat('d MMM yyyy, HH:mm', AppLocale.code).format(d);

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

String greeting() {
  final h = DateTime.now().hour;
  if (AppLocale.code == 'id') {
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

/// 1500000 -> "1.500.000" (kosong jika 0).
String formatThousands(int value) => value > 0 ? _thousands.format(value) : '';

/// "1.500.000" -> 1500000.
int parseAmount(String text) =>
    int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

/// Memberi pemisah ribuan otomatis saat mengetik nominal.
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
    final text = _thousands.format(int.parse(digits));
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
