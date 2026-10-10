import 'dart:convert';

import 'package:hamyon/features/cards/domain/entities/wallet_card.dart';
import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';

abstract final class QrPayload {
  static String card(WalletCard card) => jsonEncode(<String, dynamic>{
    'kind': 'hamyon_card',
    'version': 1,
    'name': card.name,
    'number': card.number,
    'network': card.type.name,
  });

  static String receipt(WalletTransaction transaction) =>
      jsonEncode(<String, dynamic>{
        'kind': 'hamyon_receipt',
        'version': 1,
        'transactionId': transaction.id,
        'type': transaction.type.name,
        'amount': transaction.amount,
        'commission': transaction.commission,
        'status': transaction.status.name,
        'createdAt': transaction.createdAt.toUtc().toIso8601String(),
      });
}
