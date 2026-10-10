import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamyon/core/error/failures.dart';
import 'package:hamyon/core/utils/money_policy.dart';
import 'package:hamyon/features/cards/domain/usecases/card_usecases.dart';
import 'package:hamyon/features/cards/presentation/cubit/cards_state.dart';

class CardsCubit extends Cubit<CardsState> {
  CardsCubit({required GetCards getCards, required AddCard addCard})
    : _getCards = getCards,
      _addCard = addCard,
      super(const CardsState());

  final GetCards _getCards;
  final AddCard _addCard;

  Future<void> load() async {
    emit(state.copyWith(status: CardsStatus.loading, clearMessage: true));
    try {
      emit(state.copyWith(status: CardsStatus.ready, cards: await _getCards()));
    } on Failure catch (error) {
      emit(state.copyWith(status: CardsStatus.failure, message: error.message));
    }
  }

  void nameChanged(String value) => emit(state.copyWith(nameInput: value));
  void numberChanged(String value) => emit(state.copyWith(numberInput: value));
  void balanceChanged(String value) =>
      emit(state.copyWith(balanceInput: value));
  void expiryChanged(String value) => emit(state.copyWith(expiryInput: value));
  void selectedCardChanged(int index) =>
      emit(state.copyWith(selectedCardIndex: index));

  void toggleSensitiveDetails(String cardId) => emit(
    state.revealedCardId == cardId
        ? state.copyWith(clearRevealedCard: true)
        : state.copyWith(revealedCardId: cardId),
  );

  void hideSensitiveDetails(String cardId) {
    if (state.revealedCardId == cardId) {
      emit(state.copyWith(clearRevealedCard: true));
    }
  }

  void clearSensitiveData() =>
      emit(state.copyWith(clearForm: true, clearRevealedCard: true));

  Future<bool> submit() async {
    emit(state.copyWith(status: CardsStatus.submitting, clearMessage: true));
    try {
      await _addCard(
        name: state.nameInput,
        number: state.numberInput,
        initialBalance: MoneyPolicy.parseAmount(state.balanceInput),
        expiry: state.expiryInput,
        type: state.cardType,
      );
      final cards = await _getCards();
      emit(
        state.copyWith(
          status: CardsStatus.success,
          cards: cards,
          clearForm: true,
          message: 'Karta muvaffaqiyatli qo‘shildi',
        ),
      );
      return true;
    } on Failure catch (error) {
      emit(state.copyWith(status: CardsStatus.failure, message: error.message));
      return false;
    }
  }
}
