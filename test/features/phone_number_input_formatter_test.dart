import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamyon/features/payments/presentation/formatters/phone_number_input_formatter.dart';

void main() {
  const formatter = PhoneNumberInputFormatter();

  test('9 ta raqamni to‘g‘ri guruhlaydi (XX XXX XX XX)', () {
    const value = TextEditingValue(
      text: '901234567',
      selection: TextSelection.collapsed(offset: 9),
    );
    final result = formatter.formatEditUpdate(TextEditingValue.empty, value);

    expect(result.text, '90 123 45 67');
  });

  test('9 tadan ortiq raqam kiritilganda ortiqchasini qabul qilmaydi', () {
    const value = TextEditingValue(
      text: '9012345678999',
      selection: TextSelection.collapsed(offset: 13),
    );
    final result = formatter.formatEditUpdate(TextEditingValue.empty, value);

    expect(result.text, '90 123 45 67');
    expect(result.text.replaceAll(' ', ''), hasLength(9));
  });

  test('agar +998 yoki 998 bilan nusxalangan bo‘lsa, faqat 9 xonali qismini oladi', () {
    const value = TextEditingValue(
      text: '+998901234567',
      selection: TextSelection.collapsed(offset: 13),
    );
    final result = formatter.formatEditUpdate(TextEditingValue.empty, value);

    expect(result.text, '90 123 45 67');
  });

  test('harflar va belgilarni tozalaydi', () {
    const value = TextEditingValue(
      text: '90abc123-45',
      selection: TextSelection.collapsed(offset: 11),
    );
    final result = formatter.formatEditUpdate(TextEditingValue.empty, value);

    expect(result.text, '90 123 45');
  });

  test('bo‘sh qiymatda bo‘sh qaytaradi', () {
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue.empty,
    );
    expect(result.text, '');
  });
}
