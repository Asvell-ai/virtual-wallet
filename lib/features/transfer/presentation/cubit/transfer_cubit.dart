import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamyon/core/error/failures.dart';
import 'package:hamyon/features/transfer/domain/usecases/transfer_funds.dart';
import 'package:hamyon/features/transfer/presentation/cubit/transfer_state.dart';

class TransferCubit extends Cubit<TransferState> {
  TransferCubit(this._transferFunds) : super(const TransferState());
  final TransferFunds _transferFunds;

  void clearSensitiveData() => emit(const TransferState());

  void sourceChanged(String? value) => emit(state.copyWith(
        status: TransferStatus.editing,
        sourceCardId: value ?? '',
        clearMessage: true,
      ));
  void destinationChanged(String? value) => emit(state.copyWith(
        status: TransferStatus.editing,
        destinationCardId: value ?? '',
        clearMessage: true,
      ));
  void amountChanged(String value) => emit(state.copyWith(
        status: TransferStatus.editing,
        amountInput: value,
        clearMessage: true,
      ));
  void pinChanged(String value) => emit(state.copyWith(
        status: TransferStatus.editing,
        pinInput: value,
        clearMessage: true,
      ));

  Future<void> submit() async {
    emit(state.copyWith(
      status: TransferStatus.submitting,
      clearMessage: true,
      requiresLock: false,
    ));
    try {
      final transaction = await _transferFunds(
        sourceCardId: state.sourceCardId,
        destinationCardId: state.destinationCardId,
        amount: state.amount,
        pin: state.pinInput,
      );
      emit(state.copyWith(
        status: TransferStatus.success,
        transaction: transaction,
        message: 'O‘tkazma muvaffaqiyatli bajarildi',
        resetForm: true,
      ));
    } on BlockedFailure catch (error) {
      emit(state.copyWith(
        status: TransferStatus.failure,
        message: error.message,
        pinInput: '',
        requiresLock: true,
      ));
    } on Failure catch (error) {
      emit(state.copyWith(
        status: TransferStatus.failure,
        message: error.message,
        pinInput: '',
      ));
    }
  }
}
