import 'package:flutter_test/flutter_test.dart';
import 'package:wall_o_pay/core/format.dart';
import 'package:wall_o_pay/core/l10n.dart';

void main() {
  group('Greeting time-of-day tests (Indonesian)', () {
    setUp(() {
      AppLocale.code = 'id';
    });

    test('Midnight and early hours (00:00 - 04:59) return Selamat malam', () {
      expect(greeting(0), 'Selamat malam'); // 12:00 AM - 12:59 AM (user screenshot case)
      expect(greeting(1), 'Selamat malam');
      expect(greeting(2), 'Selamat malam');
      expect(greeting(3), 'Selamat malam');
      expect(greeting(4), 'Selamat malam');
    });

    test('Morning hours (05:00 - 10:59) return Selamat pagi', () {
      expect(greeting(5), 'Selamat pagi');
      expect(greeting(8), 'Selamat pagi');
      expect(greeting(10), 'Selamat pagi');
    });

    test('Midday hours (11:00 - 14:59) return Selamat siang', () {
      expect(greeting(11), 'Selamat siang');
      expect(greeting(12), 'Selamat siang');
      expect(greeting(14), 'Selamat siang');
    });

    test('Afternoon hours (15:00 - 17:59) return Selamat sore', () {
      expect(greeting(15), 'Selamat sore');
      expect(greeting(16), 'Selamat sore');
      expect(greeting(17), 'Selamat sore');
    });

    test('Evening hours (18:00 - 23:59) return Selamat malam', () {
      expect(greeting(18), 'Selamat malam');
      expect(greeting(20), 'Selamat malam');
      expect(greeting(23), 'Selamat malam');
    });
  });

  group('Greeting time-of-day tests (English)', () {
    setUp(() {
      AppLocale.code = 'en';
    });

    test('Midnight and early hours (00:00 - 04:59) return Good evening', () {
      expect(greeting(0), 'Good evening');
      expect(greeting(3), 'Good evening');
    });

    test('Morning hours (05:00 - 11:59) return Good morning', () {
      expect(greeting(5), 'Good morning');
      expect(greeting(9), 'Good morning');
      expect(greeting(11), 'Good morning');
    });

    test('Afternoon hours (12:00 - 16:59) return Good afternoon', () {
      expect(greeting(12), 'Good afternoon');
      expect(greeting(14), 'Good afternoon');
      expect(greeting(16), 'Good afternoon');
    });

    test('Evening hours (17:00 - 23:59) return Good evening', () {
      expect(greeting(17), 'Good evening');
      expect(greeting(21), 'Good evening');
      expect(greeting(23), 'Good evening');
    });
  });
}

