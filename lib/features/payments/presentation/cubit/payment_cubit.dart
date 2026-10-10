import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamyon/core/error/failures.dart';
import 'package:hamyon/features/payments/domain/entities/payment_service.dart';
import 'package:hamyon/features/payments/domain/usecases/make_payment.dart';
import 'package:hamyon/features/payments/presentation/cubit/payment_state.dart';

class PaymentCubit extends Cubit<PaymentState> {
  PaymentCubit(this._makePayment) : super(const PaymentState());
  final MakePayment _makePayment;

  void clearSensitiveData() => emit(const PaymentState());

  void sourceChanged(String? value) => emit(state.copyWith(
        status: PaymentStatus.editing,
        sourceCardId: value ?? '',
        clearMessage: true,
      ));
  void serviceChanged(PaymentService service) => emit(state.copyWith(
        status: PaymentStatus.editing,
        service: service,
        clearMessage: true,
      ));
  void accountChanged(String value) => emit(state.copyWith(
        status: PaymentStatus.editing,
        accountInput: value,
        clearMessage: true,
      ));
  void amountChanged(String value) => emit(state.copyWith(
        status: PaymentStatus.editing,
        amountInput: value,
        clearMessage: true,
      ));
  void pinChanged(String value) => emit(state.copyWith(
        status: PaymentStatus.editing,
        pinInput: value,
        clearMessage: true,
      ));

  Future<void> submit() async {
    emit(state.copyWith(
      status: PaymentStatus.submitting,
      clearMessage: true,
      requiresLock: false,
    ));
    try {
      final transaction = await _makePayment(
        sourceCardId: state.sourceCardId,
        service: state.service,
        account: state.accountInput,
        amount: state.amount,
        pin: state.pinInput,
      );
      emit(state.copyWith(
        status: PaymentStatus.success,
        transaction: transaction,
        message: 'To‘lov muvaffaqiyatli bajarildi',
        resetForm: true,
      ));
    } on BlockedFailure catch (error) {
      emit(state.copyWith(
        status: PaymentStatus.failure,
        message: error.message,
        pinInput: '',
        requiresLock: true,
      ));
    } on Failure catch (error) {
      emit(state.copyWith(
        status: PaymentStatus.failure,
        message: error.message,
        pinInput: '',
      ));
    }
  }
}
