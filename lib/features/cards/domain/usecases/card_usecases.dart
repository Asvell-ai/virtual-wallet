import 'package:hamyon/core/error/failures.dart';
import 'package:hamyon/features/cards/domain/entities/wallet_card.dart';
import 'package:hamyon/features/cards/domain/repositories/cards_repository.dart';

class GetCards {
  const GetCards(this._repository);
  final CardsRepository _repository;
  Future<List<WalletCard>> call() => _repository.getCards();
}

class AddCard {
  const AddCard(this._repository);
  final CardsRepository _repository;

  Future<WalletCard> call({
    required String name,
    required String number,
    required int initialBalance,
    required String expiry,
    CardType type = CardType.uzcard,
  }) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    final expiryParts = expiry.split('/');
    if (name.trim().length < 2) {
      throw const ValidationFailure('Karta nomini kiriting');
    }
    if (digits.length != 16) {
      throw const ValidationFailure('Karta raqami 16 ta raqam bo‘lishi kerak');
    }
    if (initialBalance < 0) {
      throw const ValidationFailure('Boshlang‘ich balans manfiy bo‘la olmaydi');
    }
    if (expiryParts.length != 2 ||
        expiryParts.first.length != 2 ||
        expiryParts.last.length != 2) {
      throw const ValidationFailure(
        'Amal qilish muddatini MM/YY formatida kiriting',
      );
    }
    final month = int.tryParse(expiryParts.first);
    final year = int.tryParse(expiryParts.last);
    if (month == null || year == null || month < 1 || month > 12) {
      throw const ValidationFailure('Amal qilish muddati noto‘g‘ri');
    }
    final now = DateTime.now();
    final currentYear = now.year % 100;
    if (year < currentYear || (year == currentYear && month < now.month)) {
      throw const ValidationFailure('Kartaning amal qilish muddati tugagan');
    }
    return _repository.addCard(
      name: name,
      number: digits,
      initialBalance: initialBalance,
      expiryMonth: month,
      expiryYear: year,
      type: type,
    );
  }
}
