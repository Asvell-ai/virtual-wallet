abstract final class MoneyPolicy {
  static const int commissionPermille = 5; // 0.5%

  static int commissionFor(int amount) {
    if (amount <= 0) return 0;
    // Foydalanuvchi zarariga yashirin kasr qolmasligi uchun 1 so‘mgacha tepaga.
    return (amount * commissionPermille + 999) ~/ 1000;
  }

  static int parseAmount(String value) {
    final normalized = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(normalized) ?? 0;
  }
}
