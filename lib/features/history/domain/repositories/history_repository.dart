import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';

abstract interface class HistoryRepository {
  Future<List<WalletTransaction>> getTransactions();
}
