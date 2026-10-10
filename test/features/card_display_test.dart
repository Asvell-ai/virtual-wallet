import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamyon/core/utils/formatters.dart';
import 'package:hamyon/features/cards/data/models/wallet_card_model.dart';
import 'package:hamyon/features/cards/domain/entities/wallet_card.dart';
import 'package:hamyon/features/cards/presentation/formatters/card_expiry_input_formatter.dart';
import 'package:hamyon/features/cards/presentation/widgets/wallet_card_tile.dart';

void main() {
  test('karta maskasi 16 pozitsiyani saqlaydi', () {
    expect(AppFormatters.maskedCard('8600123456789012'), '8600 **** **** 9012');
    expect(AppFormatters.cardNumber('8600123456789012'), '8600 1234 5678 9012');
  });

  test('amal qilish muddatini MM/YY formatiga keltiradi', () {
    final result = CardExpiryInputFormatter().formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '122999'),
    );
    expect(result.text, '12/29');
  });

  test('eski karta JSONi expiry maydonlarisiz ham ochiladi', () {
    final card = WalletCardModel.fromJson({
      'id': 'card-1',
      'name': 'TEST USER',
      'number': '8600123456789012',
      'type': 'uzcard',
      'balance': 100000,
      'colorValue': 0xFF0A1D45,
      'createdAt': DateTime.utc(2026).toIso8601String(),
    });

    expect(card.expiryLabel, '12/29');
  });

  testWidgets('UZCARD preview kichik ekranda to‘liq joylashadi', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 340,
              child: WalletCardTile(
                card: WalletCard(
                  id: 'card-1',
                  name: 'ASADULLOH SAYFIDDINOV',
                  number: '8600123456789012',
                  type: CardType.uzcard,
                  balance: 100000,
                  colorValue: 0xFF0A1D45,
                  createdAt: DateTime.utc(2026),
                  expiryMonth: 12,
                  expiryYear: 29,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('8600 **** **** 9012'), findsOneWidget);
    expect(find.text('** / **'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
