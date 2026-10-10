import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hamyon/features/cards/domain/entities/wallet_card.dart';
import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';
import 'package:hamyon/features/qr/domain/qr_payload.dart';

void main() {
  test('karta QR payload versiyalangan JSON yaratadi', () {
    final payload =
        jsonDecode(
              QrPayload.card(
                WalletCard(
                  id: 'card-1',
                  name: 'Asadulloh',
                  number: '8600123412341234',
                  type: CardType.uzcard,
                  balance: 100000,
                  colorValue: 0xFF000000,
                  createdAt: DateTime.utc(2026),
                ),
              ),
            )
            as Map<String, dynamic>;

    expect(payload['kind'], 'hamyon_card');
    expect(payload['version'], 1);
    expect(payload['number'], '8600123412341234');
  });

  test('chek QR payload muhim tranzaksiya maydonlarini saqlaydi', () {
    final payload =
        jsonDecode(
              QrPayload.receipt(
                WalletTransaction(
                  id: 'tx-1',
                  type: TransactionType.payment,
                  sourceCardId: 'card-1',
                  amount: 50000,
                  commission: 250,
                  createdAt: DateTime.utc(2026, 10, 10),
                  status: TransactionStatus.completed,
                  signature: 'signature',
                ),
              ),
            )
            as Map<String, dynamic>;

    expect(payload['kind'], 'hamyon_receipt');
    expect(payload['transactionId'], 'tx-1');
    expect(payload['amount'], 50000);
    expect(payload['status'], 'completed');
  });
}
