import 'package:flutter/material.dart';
import 'package:hamyon/features/cards/domain/entities/wallet_card.dart';
import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';
import 'package:hamyon/features/receipt/domain/services/receipt_service.dart';
import 'package:hamyon/features/receipt/presentation/pages/receipt_page.dart';

Future<void> openCompletedOperationReceipt({
  required BuildContext context,
  required WalletTransaction transaction,
  required List<WalletCard> cards,
  required ReceiptService receiptService,
}) => Navigator.of(context).pushAndRemoveUntil<void>(
  MaterialPageRoute<void>(
    builder: (_) => ReceiptPage(
      transaction: transaction,
      cards: cards,
      receiptService: receiptService,
    ),
  ),
  (route) => route.isFirst,
);
