import 'package:flutter_test/flutter_test.dart';
import 'package:hamyon/core/utils/money_policy.dart';

void main() {
  group('MoneyPolicy', () {
    test('0.5 foiz komissiyani butun so‘mga yuqoriga yaxlitlaydi', () {
      expect(MoneyPolicy.commissionFor(100000), 500);
      expect(MoneyPolicy.commissionFor(100), 1);
      expect(MoneyPolicy.commissionFor(1), 1);
      expect(MoneyPolicy.commissionFor(0), 0);
    });

    test('formatlangan qiymatdan summani ajratadi', () {
      expect(MoneyPolicy.parseAmount('1 250 000 so‘m'), 1250000);
      expect(MoneyPolicy.parseAmount(''), 0);
    });
  });
}
