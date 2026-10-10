import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';

abstract interface class TransferRepository {
  Future<WalletTransaction> transfer({
    required String sourceCardId,
    required String destinationCardId,
    required int amount,
    required int commission,
  });
}
