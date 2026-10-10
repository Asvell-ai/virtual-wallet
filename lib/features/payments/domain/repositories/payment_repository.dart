import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';
import 'package:hamyon/features/payments/domain/entities/payment_service.dart';

abstract interface class PaymentRepository {
  Future<WalletTransaction> pay({
    required String sourceCardId,
    required PaymentService service,
    required String account,
    required int amount,
  });
}
