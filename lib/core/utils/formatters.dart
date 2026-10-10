import 'package:intl/intl.dart';

abstract final class AppFormatters {
  static final NumberFormat _money = NumberFormat('#,##0', 'uz');
  static final DateFormat _date = DateFormat('dd.MM.yyyy, HH:mm');

  static String money(int value) => '${_money.format(value)} so‘m';
  static String date(DateTime value) => _date.format(value.toLocal());

  static String maskedCard(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return digits;
    return '${digits.substring(0, 4)} ** ** ${digits.substring(digits.length - 4)}';
  }
}
