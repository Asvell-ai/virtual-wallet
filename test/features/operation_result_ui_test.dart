import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';
import 'package:hamyon/features/history/presentation/widgets/transaction_tile.dart';
import 'package:hamyon/features/receipt/domain/services/receipt_service.dart';
import 'package:hamyon/features/receipt/presentation/navigation/receipt_navigation.dart';

void main() {
  final failedTransfer = WalletTransaction(
    id: 'tx-failed',
    type: TransactionType.transfer,
    sourceCardId: 'card-1',
    destinationCardId: 'card-2',
    amount: 1000000,
    commission: 5000,
    createdAt: DateTime.utc(2026, 10, 10, 14, 14),
    status: TransactionStatus.failed,
    signature: 'signature',
  );

  testWidgets('rad etilgan operatsiya statusi qizil rangda chiqadi', (
    tester,
  ) async {
    const errorColor = Color(0xFFB3261E);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            error: errorColor,
          ),
        ),
        home: Scaffold(
          body: TransactionTile(
            transaction: failedTransfer,
            cardId: 'card-2',
            onTap: () {},
          ),
        ),
      ),
    );

    final status = tester.widget<Text>(find.text('Rad etildi'));
    expect(status.style?.color, errorColor);
  });

  testWidgets('chekdan orqaga qaytish operatsiya formasini qayta ochmaydi', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (homeContext) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push<void>(
                homeContext,
                MaterialPageRoute<void>(
                  builder: (operationContext) => Scaffold(
                    body: TextButton(
                      onPressed: () => openCompletedOperationReceipt(
                        context: operationContext,
                        transaction: failedTransfer.copyWith(
                          status: TransactionStatus.completed,
                        ),
                        cards: const [],
                        receiptService: const ReceiptService(),
                      ),
                      child: const Text('Operatsiyani yakunlash'),
                    ),
                  ),
                ),
              ),
              child: const Text('Home'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Operatsiyani yakunlash'));
    await tester.pumpAndSettle();

    expect(find.text('Tranzaksiya cheki'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Operatsiyani yakunlash'), findsNothing);
  });
}
