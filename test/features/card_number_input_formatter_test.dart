import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamyon/features/cards/presentation/formatters/card_number_input_formatter.dart';

void main() {
  test('UZCARD raqamini 4 tadan guruhlaydi va 16 raqamda to‘xtaydi', () {
    final formatter = CardNumberInputFormatter();
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '86001234567890129999'),
    );

    expect(result.text, '8600 1234 5678 9012');
    expect(result.text.replaceAll(' ', ''), hasLength(16));
  });

  test('raqam bo‘lmagan belgilarni olib tashlaydi', () {
    final formatter = CardNumberInputFormatter();
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '8600-abcd-1234'),
    );

    expect(result.text, '8600 1234');
  });
}
