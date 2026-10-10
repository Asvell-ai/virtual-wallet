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
    CardType type = CardType.uzcard,
  }) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (name.trim().length < 2) {
      throw const ValidationFailure('Karta nomini kiriting');
    }
    if (digits.length != 16) {
      throw const ValidationFailure('Karta raqami 16 ta raqam bo‘lishi kerak');
    }
    if (initialBalance < 0) {
      throw const ValidationFailure('Boshlang‘ich balans manfiy bo‘la olmaydi');
    }
    return _repository.addCard(
      name: name,
      number: digits,
      initialBalance: initialBalance,
      type: type,
    );
  }
}
