import 'package:hamyon/core/error/failures.dart';
import 'package:hamyon/features/auth/domain/usecases/auth_usecases.dart';
import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';
import 'package:hamyon/features/payments/domain/entities/payment_service.dart';
import 'package:hamyon/features/payments/domain/repositories/payment_repository.dart';

class MakePayment {
  const MakePayment(this._repository, this._verifyPin);

  final PaymentRepository _repository;
  final VerifyPin _verifyPin;

  Future<WalletTransaction> call({
    required String sourceCardId,
    required PaymentService service,
    required String account,
    required int amount,
    required String pin,
  }) async {
    if (sourceCardId.isEmpty) {
      throw const ValidationFailure('To‘lov kartasini tanlang');
    }
    if (service == PaymentService.mobile) {
      final digits = account.replaceAll(RegExp(r'\D'), '');
      if (digits.length != 9 && !(digits.length == 12 && digits.startsWith('998'))) {
        throw const ValidationFailure('Telefon raqamini to‘liq kiriting');
      }
    } else if (account.trim().length < 5) {
      throw const ValidationFailure('Hisob raqamini to‘liq kiriting');
    }
    if (amount <= 0) throw const ValidationFailure('Musbat summa kiriting');
    if (pin.length != 4) {
      throw const ValidationFailure('4 xonali PIN-kodni kiriting');
    }
    await _verifyPin(pin);
    return _repository.pay(
      sourceCardId: sourceCardId,
      service: service,
      account: account.trim(),
      amount: amount,
    );
  }
}
