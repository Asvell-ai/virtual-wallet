import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamyon/core/error/failures.dart';
import 'package:hamyon/features/history/domain/usecases/get_transactions.dart';
import 'package:hamyon/features/history/presentation/cubit/history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this._getTransactions) : super(const HistoryState());
  final GetTransactions _getTransactions;

  Future<void> load() async {
    emit(state.copyWith(status: HistoryStatus.loading));
    try {
      emit(state.copyWith(
        status: HistoryStatus.ready,
        transactions: await _getTransactions(),
      ));
    } on Failure catch (error) {
      emit(state.copyWith(
        status: HistoryStatus.failure,
        message: error.message,
      ));
    }
  }

  void filterChanged(HistoryFilter filter) => emit(state.copyWith(filter: filter));
}
