import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamyon/features/cards/domain/entities/wallet_card.dart';
import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';
import 'package:hamyon/features/receipt/domain/services/receipt_service.dart';
import 'package:hamyon/features/receipt/presentation/cubit/receipt_state.dart';

class ReceiptCubit extends Cubit<ReceiptState> {
  ReceiptCubit(this._service) : super(const ReceiptState());
  final ReceiptService _service;

  Future<void> save({
    required WalletTransaction transaction,
    required List<WalletCard> cards,
  }) async {
    emit(state.copyWith(status: ReceiptStatus.working, clearMessage: true));
    try {
      final savedLocation = await _service.savePdf(
        transaction: transaction,
        cards: cards,
      );
      if (savedLocation == null) {
        emit(
          state.copyWith(
            status: ReceiptStatus.idle,
            message: 'PDF saqlash bekor qilindi',
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: ReceiptStatus.saved,
          filePath: savedLocation,
          message: 'PDF muvaffaqiyatli saqlandi',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ReceiptStatus.failure,
          message: 'PDF xatosi: $error',
        ),
      );
    }
  }

  Future<void> share({
    required WalletTransaction transaction,
    required List<WalletCard> cards,
  }) async {
    emit(state.copyWith(status: ReceiptStatus.working, clearMessage: true));
    try {
      final file = await _service.sharePdf(
        transaction: transaction,
        cards: cards,
      );
      emit(
        state.copyWith(
          status: ReceiptStatus.shared,
          filePath: file.path,
          message: 'Ulashish oynasi ochildi',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ReceiptStatus.failure,
          message: 'PDF xatosi: $error',
        ),
      );
    }
  }
}
