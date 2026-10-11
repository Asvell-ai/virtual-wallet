import 'package:flutter/services.dart';

class PhoneNumberInputFormatter extends TextInputFormatter {
  const PhoneNumberInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (oldValue.text.length > newValue.text.length &&
        oldValue.selection.end > 0 &&
        oldValue.selection.end <= oldValue.text.length &&
        oldValue.text[oldValue.selection.end - 1] == ' ') {
      final deleteIndex = oldValue.selection.end - 2;
      if (deleteIndex >= 0) {
        text = oldValue.text.substring(0, deleteIndex) +
            oldValue.text.substring(oldValue.selection.end);
      }
    }

    var rawDigits = text.replaceAll(RegExp(r'\D'), '');
    if (rawDigits.startsWith('998') && rawDigits.length > 9) {
      rawDigits = rawDigits.substring(3);
    }
    if (rawDigits.length > 9) {
      rawDigits = rawDigits.substring(0, 9);
    }

    final buffer = StringBuffer();
    for (var i = 0; i < rawDigits.length; i++) {
      if (i == 2 || i == 5 || i == 7) {
        buffer.write(' ');
      }
      buffer.write(rawDigits[i]);
    }
    final formatted = buffer.toString();

    var digitsBeforeCursor = 0;
    final cursorEnd = newValue.selection.end.clamp(0, text.length);
    for (var i = 0; i < cursorEnd; i++) {
      if (RegExp(r'\d').hasMatch(text[i])) {
        digitsBeforeCursor++;
      }
    }

    if (text.replaceAll(RegExp(r'\D'), '').startsWith('998') &&
        text.replaceAll(RegExp(r'\D'), '').length > 9) {
      digitsBeforeCursor = (digitsBeforeCursor - 3).clamp(0, rawDigits.length);
    } else {
      digitsBeforeCursor = digitsBeforeCursor.clamp(0, rawDigits.length);
    }

    var cursorOffset = 0;
    var countedDigits = 0;
    while (cursorOffset < formatted.length && countedDigits < digitsBeforeCursor) {
      if (RegExp(r'\d').hasMatch(formatted[cursorOffset])) {
        countedDigits++;
      }
      cursorOffset++;
    }

    if (newValue.selection.end >= newValue.text.length) {
      cursorOffset = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }
}
