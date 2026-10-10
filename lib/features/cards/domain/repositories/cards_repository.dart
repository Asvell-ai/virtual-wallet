import 'package:hamyon/features/cards/domain/entities/wallet_card.dart';

abstract interface class CardsRepository {
  Future<List<WalletCard>> getCards();
  Future<WalletCard> addCard({
    required String name,
    required String number,
    required int initialBalance,
    CardType type = CardType.uzcard,
  });
}
