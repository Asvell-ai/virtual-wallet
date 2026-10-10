import 'package:equatable/equatable.dart';
import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';

enum HistoryStatus { initial, loading, ready, failure }
enum HistoryFilter { all, transfers, payments, completed, failed }

class HistoryState extends Equatable {
  const HistoryState({
    this.status = HistoryStatus.initial,
    this.transactions = const [],
    this.filter = HistoryFilter.all,
    this.message,
  });

  final HistoryStatus status;
  final List<WalletTransaction> transactions;
  final HistoryFilter filter;
  final String? message;

  List<WalletTransaction> get filtered => transactions.where((transaction) {
        return switch (filter) {
          HistoryFilter.all => true,
          HistoryFilter.transfers => transaction.type == TransactionType.transfer,
          HistoryFilter.payments => transaction.type == TransactionType.payment,
          HistoryFilter.completed =>
            transaction.status == TransactionStatus.completed,
          HistoryFilter.failed =>
            transaction.status == TransactionStatus.failed ||
                transaction.status == TransactionStatus.tampered,
        };
      }).toList();

  HistoryState copyWith({
    HistoryStatus? status,
    List<WalletTransaction>? transactions,
    HistoryFilter? filter,
    String? message,
  }) =>
      HistoryState(
        status: status ?? this.status,
        transactions: transactions ?? this.transactions,
        filter: filter ?? this.filter,
        message: message,
      );

  @override
  List<Object?> get props => [status, transactions, filter, message];
}
