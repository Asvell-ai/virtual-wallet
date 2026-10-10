import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';
import 'package:hamyon/features/history/domain/repositories/history_repository.dart';

class GetTransactions {
  const GetTransactions(this._repository);
  final HistoryRepository _repository;
  Future<List<WalletTransaction>> call() => _repository.getTransactions();
}
