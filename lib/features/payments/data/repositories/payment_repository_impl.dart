import 'package:hamyon/core/error/failures.dart';
import 'package:hamyon/core/security/secure_vault.dart';
import 'package:hamyon/features/cards/data/models/wallet_card_model.dart';
import 'package:hamyon/features/history/data/models/wallet_transaction_model.dart';
import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';
import 'package:hamyon/features/payments/domain/entities/payment_service.dart';
import 'package:hamyon/features/payments/domain/repositories/payment_repository.dart';
import 'package:uuid/uuid.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl(this._vault, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  final SecureVault _vault;
  final Uuid _uuid;

  @override
  Future<WalletTransaction> pay({
    required String sourceCardId,
    required PaymentService service,
    required String account,
    required int amount,
  }) async {
    final result = await _vault.mutate((database) async {
      final cardRows = List<Map<String, dynamic>>.from(database['cards']! as List);
      final sourceIndex =
          cardRows.indexWhere((row) => row['id'] == sourceCardId);
      if (sourceIndex < 0) {
        throw const NotFoundFailure('Tanlangan karta topilmadi');
      }
      if (amount <= 0) throw const ValidationFailure('Summa noto‘g‘ri');
      final source = WalletCardModel.fromJson(cardRows[sourceIndex]);
      final hasBalance = source.balance >= amount;
      final unsigned = WalletTransaction(
        id: _uuid.v4(),
        type: TransactionType.payment,
        sourceCardId: sourceCardId,
        serviceName: service.title,
        account: account,
        amount: amount,
        commission: 0,
        createdAt: DateTime.now().toUtc(),
        status: hasBalance
            ? TransactionStatus.completed
            : TransactionStatus.failed,
        signature: '',
        failureReason: hasBalance ? null : 'Mablag‘ yetarli emas',
      );
      final transaction = WalletTransactionModel.fromEntity(
        unsigned.copyWith(signature: await _vault.sign(unsigned.signingPayload)),
      );
      if (hasBalance) {
        final newBalance = source.balance - amount;
        if (newBalance < 0) {
          throw const IntegrityFailure('Manfiy balansga urinish aniqlandi');
        }
        cardRows[sourceIndex] = WalletCardModel.fromEntity(
          source.copyWith(balance: newBalance),
        ).toJson();
        database['cards'] = cardRows;
      }
      final transactionRows = List<Map<String, dynamic>>.from(
        database['transactions']! as List,
      )..add(transaction.toJson());
      database['transactions'] = transactionRows;
      return (transaction: transaction, hasBalance: hasBalance);
    });
    if (!result.hasBalance) throw const InsufficientBalanceFailure();
    return result.transaction;
  }
}
