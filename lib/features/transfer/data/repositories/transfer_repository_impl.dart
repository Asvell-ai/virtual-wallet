import 'package:hamyon/core/error/failures.dart';
import 'package:hamyon/core/security/secure_vault.dart';
import 'package:hamyon/features/cards/data/models/wallet_card_model.dart';
import 'package:hamyon/features/history/data/models/wallet_transaction_model.dart';
import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';
import 'package:hamyon/features/transfer/domain/repositories/transfer_repository.dart';
import 'package:uuid/uuid.dart';

class TransferRepositoryImpl implements TransferRepository {
  TransferRepositoryImpl(this._vault, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  final SecureVault _vault;
  final Uuid _uuid;

  @override
  Future<WalletTransaction> transfer({
    required String sourceCardId,
    required String destinationCardId,
    required int amount,
    required int commission,
  }) async {
    final result = await _vault.mutate((database) async {
      final cardRows = List<Map<String, dynamic>>.from(database['cards']! as List);
      final sourceIndex =
          cardRows.indexWhere((row) => row['id'] == sourceCardId);
      final destinationIndex =
          cardRows.indexWhere((row) => row['id'] == destinationCardId);
      if (sourceIndex < 0 || destinationIndex < 0) {
        throw const NotFoundFailure('Tanlangan karta topilmadi');
      }
      if (sourceCardId == destinationCardId) {
        throw const ValidationFailure('Kartalar har xil bo‘lishi kerak');
      }
      if (amount <= 0 || commission < 0) {
        throw const ValidationFailure('Summa noto‘g‘ri');
      }

      final source = WalletCardModel.fromJson(cardRows[sourceIndex]);
      final destination = WalletCardModel.fromJson(cardRows[destinationIndex]);
      final requiredBalance = amount + commission;
      final hasBalance = source.balance >= requiredBalance;
      final unsigned = WalletTransaction(
        id: _uuid.v4(),
        type: TransactionType.transfer,
        sourceCardId: sourceCardId,
        destinationCardId: destinationCardId,
        amount: amount,
        commission: commission,
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
        final newSourceBalance = source.balance - requiredBalance;
        final newDestinationBalance = destination.balance + amount;
        if (newSourceBalance < 0) {
          throw const IntegrityFailure('Manfiy balansga urinish aniqlandi');
        }
        cardRows[sourceIndex] = WalletCardModel.fromEntity(
          source.copyWith(balance: newSourceBalance),
        ).toJson();
        cardRows[destinationIndex] = WalletCardModel.fromEntity(
          destination.copyWith(balance: newDestinationBalance),
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
