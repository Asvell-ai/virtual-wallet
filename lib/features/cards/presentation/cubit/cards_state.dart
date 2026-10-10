import 'package:equatable/equatable.dart';
import 'package:hamyon/features/cards/domain/entities/wallet_card.dart';

enum CardsStatus { initial, loading, ready, submitting, success, failure }

class CardsState extends Equatable {
  const CardsState({
    this.status = CardsStatus.initial,
    this.cards = const [],
    this.nameInput = '',
    this.numberInput = '',
    this.balanceInput = '',
    this.expiryInput = '',
    this.cardType = CardType.uzcard,
    this.selectedCardIndex = 0,
    this.revealedCardId,
    this.message,
  });

  final CardsStatus status;
  final List<WalletCard> cards;
  final String nameInput;
  final String numberInput;
  final String balanceInput;
  final String expiryInput;
  final CardType cardType;
  final int selectedCardIndex;
  final String? revealedCardId;
  final String? message;

  int get totalBalance => cards.fold(0, (total, card) => total + card.balance);

  CardsState copyWith({
    CardsStatus? status,
    List<WalletCard>? cards,
    String? nameInput,
    String? numberInput,
    String? balanceInput,
    String? expiryInput,
    CardType? cardType,
    int? selectedCardIndex,
    String? revealedCardId,
    String? message,
    bool clearMessage = false,
    bool clearForm = false,
    bool clearRevealedCard = false,
  }) => CardsState(
    status: status ?? this.status,
    cards: cards ?? this.cards,
    nameInput: clearForm ? '' : nameInput ?? this.nameInput,
    numberInput: clearForm ? '' : numberInput ?? this.numberInput,
    balanceInput: clearForm ? '' : balanceInput ?? this.balanceInput,
    expiryInput: clearForm ? '' : expiryInput ?? this.expiryInput,
    cardType: cardType ?? this.cardType,
    selectedCardIndex: selectedCardIndex ?? this.selectedCardIndex,
    revealedCardId: clearRevealedCard
        ? null
        : revealedCardId ?? this.revealedCardId,
    message: clearMessage ? null : message ?? this.message,
  );

  @override
  List<Object?> get props => [
    status,
    cards,
    nameInput,
    numberInput,
    balanceInput,
    expiryInput,
    cardType,
    selectedCardIndex,
    revealedCardId,
    message,
  ];
}
