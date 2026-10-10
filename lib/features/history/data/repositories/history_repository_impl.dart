import 'package:hamyon/core/security/secure_vault.dart';
import 'package:hamyon/features/history/data/models/wallet_transaction_model.dart';
import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';
import 'package:hamyon/features/history/domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  const HistoryRepositoryImpl(this._vault);
  final SecureVault _vault;

  @override
  Future<List<WalletTransaction>> getTransactions() async {
    final database = await _vault.read();
    final rows = List<Map<String, dynamic>>.from(
      database['transactions']! as List,
    );
    final result = <WalletTransaction>[];
    for (final row in rows) {
      final transaction = WalletTransactionModel.fromJson(row);
      final valid = await _vault.verifySignature(
        transaction.signingPayload,
        transaction.signature,
      );
      result.add(
        valid
            ? transaction
            : transaction.copyWith(
                integrityValid: false,
                status: TransactionStatus.tampered,
              ),
      );
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }
}
