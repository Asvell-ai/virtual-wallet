import 'package:hamyon/core/error/failures.dart';
import 'package:hamyon/core/security/secure_vault.dart';
import 'package:hamyon/features/cards/data/models/wallet_card_model.dart';
import 'package:hamyon/features/cards/domain/entities/wallet_card.dart';
import 'package:hamyon/features/cards/domain/repositories/cards_repository.dart';
import 'package:uuid/uuid.dart';

class CardsRepositoryImpl implements CardsRepository {
  CardsRepositoryImpl(this._vault, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  static const _colors = [
    0xFF0A1D45,
    0xFF124E78,
    0xFF173B57,
    0xFF16213E,
    0xFF183D3D,
  ];

  final SecureVault _vault;
  final Uuid _uuid;

  @override
  Future<List<WalletCard>> getCards() async {
    final database = await _vault.read();
    final rows = List<Map<String, dynamic>>.from(database['cards']! as List);
    final cards = rows.map(WalletCardModel.fromJson).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return cards;
  }

  @override
  Future<WalletCard> addCard({
    required String name,
    required String number,
    required int initialBalance,
    int? expiryMonth,
    int? expiryYear,
    CardType type = CardType.uzcard,
  }) async {
    final now = DateTime.now();
    final card = WalletCardModel(
      id: _uuid.v4(),
      name: name.trim(),
      number: number.replaceAll(RegExp(r'\D'), ''),
      type: type,
      balance: initialBalance,
      colorValue:
          _colors[DateTime.now().microsecondsSinceEpoch % _colors.length],
      createdAt: DateTime.now().toUtc(),
      expiryMonth: expiryMonth ?? now.month,
      expiryYear: expiryYear ?? (now.year + 5) % 100,
    );
    await _vault.mutate((database) {
      final rows = List<Map<String, dynamic>>.from(database['cards']! as List);
      if (rows.any((row) => row['number'] == card.number)) {
        throw const ValidationFailure('Bu karta raqami allaqachon mavjud');
      }
      rows.add(card.toJson());
      database['cards'] = rows;
    });
    return card;
  }
}
