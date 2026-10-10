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
  });

  final String id;
  final String name;
  final String number;
  final CardType type;
  final int balance;
  final int colorValue;
  final DateTime createdAt;

  WalletCard copyWith({int? balance}) => WalletCard(
        id: id,
        name: name,
        number: number,
        type: type,
        balance: balance ?? this.balance,
        colorValue: colorValue,
        createdAt: createdAt,
      );

  @override
  List<Object> get props =>
      [id, name, number, type, balance, colorValue, createdAt];
}
