import 'package:hamyon/core/error/failures.dart';
import 'package:hamyon/core/utils/money_policy.dart';
import 'package:hamyon/features/auth/domain/usecases/auth_usecases.dart';
import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';
import 'package:hamyon/features/transfer/domain/repositories/transfer_repository.dart';

class TransferFunds {
  const TransferFunds(this._repository, this._verifyPin);

  final TransferRepository _repository;
  final VerifyPin _verifyPin;

  Future<WalletTransaction> call({
    required String sourceCardId,
    required String destinationCardId,
    required int amount,
    required String pin,
  }) async {
    if (sourceCardId.isEmpty || destinationCardId.isEmpty) {
      throw const ValidationFailure('Ikkala kartani ham tanlang');
    }
    if (sourceCardId == destinationCardId) {
      throw const ValidationFailure('Bir kartaning o‘ziga o‘tkazib bo‘lmaydi');
    }
    if (amount <= 0) {
      throw const ValidationFailure('Musbat summa kiriting');
    }
    if (pin.length != 4) {
      throw const ValidationFailure('4 xonali PIN-kodni kiriting');
    }
    await _verifyPin(pin);
    return _repository.transfer(
      sourceCardId: sourceCardId,
      destinationCardId: destinationCardId,
      amount: amount,
      commission: MoneyPolicy.commissionFor(amount),
    );
  }
}
