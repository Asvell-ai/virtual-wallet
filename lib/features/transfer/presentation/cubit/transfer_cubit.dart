import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamyon/core/error/failures.dart';
import 'package:hamyon/features/transfer/domain/usecases/transfer_funds.dart';
import 'package:hamyon/features/transfer/presentation/cubit/transfer_state.dart';

class TransferCubit extends Cubit<TransferState> {
  TransferCubit(this._transferFunds) : super(const TransferState());
  final TransferFunds _transferFunds;

  void clearSensitiveData() => emit(const TransferState());

  void startWithSource(String cardId, {int balance = 0}) =>
      emit(TransferState(sourceCardId: cardId, sourceBalance: balance));

  void sourceChanged(String? value, {int balance = 0}) => emit(
    state.copyWith(
      status: TransferStatus.editing,
      sourceCardId: value ?? '',
      sourceBalance: balance,
      destinationCardId: value == state.destinationCardId
          ? ''
          : state.destinationCardId,
      clearMessage: true,
    ),
  );
  void destinationChanged(String? value) => emit(
    state.copyWith(
      status: TransferStatus.editing,
      destinationCardId: value ?? '',
      clearMessage: true,
    ),
  );
  void amountChanged(String value) => emit(
    state.copyWith(
      status: TransferStatus.editing,
      amountInput: value,
      clearMessage: true,
    ),
  );
  void pinChanged(String value) => emit(
    state.copyWith(
      status: TransferStatus.editing,
      pinInput: value,
      clearMessage: true,
    ),
  );

  void beginConfirmation() => emit(
    state.copyWith(
      status: TransferStatus.editing,
      pinInput: '',
      clearMessage: true,
      isConfirmingTransfer: true,
    ),
  );

  void cancelConfirmation() {
    if (state.status == TransferStatus.submitting) return;
    emit(
      state.copyWith(
        status: TransferStatus.editing,
        pinInput: '',
        clearMessage: true,
        isConfirmingTransfer: false,
      ),
    );
  }

  Future<bool> addPinDigit(String digit) async {
    if (state.status == TransferStatus.submitting ||
        state.pinInput.length >= 4 ||
        int.tryParse(digit) == null) {
      return false;
    }
    final pin = '${state.pinInput}$digit';
    pinChanged(pin);
    return pin.length == 4 ? submit() : false;
  }

  void removePinDigit() {
    if (state.status == TransferStatus.submitting || state.pinInput.isEmpty) {
      return;
    }
    pinChanged(state.pinInput.substring(0, state.pinInput.length - 1));
  }

  Future<bool> submit() async {
    emit(
      state.copyWith(
        status: TransferStatus.submitting,
        clearMessage: true,
        requiresLock: false,
      ),
    );
    try {
      final transaction = await _transferFunds(
        sourceCardId: state.sourceCardId,
        destinationCardId: state.destinationCardId,
        amount: state.amount,
        pin: state.pinInput,
      );
      emit(
        state.copyWith(
          status: TransferStatus.success,
          transaction: transaction,
          message: 'O‘tkazma muvaffaqiyatli bajarildi',
          resetForm: true,
          isConfirmingTransfer: false,
        ),
      );
      return true;
    } on BlockedFailure catch (error) {
      emit(
        state.copyWith(
          status: TransferStatus.failure,
          message: error.message,
          pinInput: '',
          requiresLock: true,
        ),
      );
      return false;
    } on Failure catch (error) {
      emit(
        state.copyWith(
          status: TransferStatus.failure,
          message: error.message,
          pinInput: '',
        ),
      );
      return false;
    }
  }
}
