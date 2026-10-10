import 'package:equatable/equatable.dart';

enum CardType { uzcard }

extension CardTypeX on CardType {
  String get label => switch (this) {
    CardType.uzcard => 'UZCARD',
  };
}

class WalletCard extends Equatable {
  const WalletCard({
    required this.id,
    required this.name,
    required this.number,
    required this.type,
    required this.balance,
    required this.colorValue,
    required this.createdAt,
    this.expiryMonth = 12,
    this.expiryYear = 29,
  });

  final String id;
  final String name;
  final String number;
  final CardType type;
  final int balance;
  final int colorValue;
  final DateTime createdAt;
  final int expiryMonth;
  final int expiryYear;

  WalletCard copyWith({int? balance}) => WalletCard(
    id: id,
    name: name,
    number: number,
    type: type,
    balance: balance ?? this.balance,
    colorValue: colorValue,
    createdAt: createdAt,
    expiryMonth: expiryMonth,
    expiryYear: expiryYear,
  );

  String get expiryLabel =>
      '${expiryMonth.toString().padLeft(2, '0')}/${expiryYear.toString().padLeft(2, '0')}';

  @override
  List<Object> get props => [
    id,
    name,
    number,
    type,
    balance,
    colorValue,
    createdAt,
    expiryMonth,
    expiryYear,
  ];
}
