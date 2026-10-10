import 'package:hamyon/features/cards/domain/entities/wallet_card.dart';

class WalletCardModel extends WalletCard {
  const WalletCardModel({
    required super.id,
    required super.name,
    required super.number,
    required super.type,
    required super.balance,
    required super.colorValue,
    required super.createdAt,
  });

  factory WalletCardModel.fromJson(Map<String, dynamic> json) => WalletCardModel(
        id: json['id']! as String,
        name: json['name']! as String,
        number: json['number']! as String,
        type: CardType.values.byName(json['type'] as String? ?? 'uzcard'),
        balance: json['balance']! as int,
        colorValue: json['colorValue']! as int,
        createdAt: DateTime.parse(json['createdAt']! as String),
      );

  factory WalletCardModel.fromEntity(WalletCard card) => WalletCardModel(
        id: card.id,
        name: card.name,
        number: card.number,
        type: card.type,
        balance: card.balance,
        colorValue: card.colorValue,
        createdAt: card.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'number': number,
        'type': type.name,
        'balance': balance,
        'colorValue': colorValue,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };
}
