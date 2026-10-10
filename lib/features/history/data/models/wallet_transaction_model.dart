import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';

class WalletTransactionModel extends WalletTransaction {
  const WalletTransactionModel({
    required super.id,
    required super.type,
    required super.sourceCardId,
    required super.amount,
    required super.commission,
    required super.createdAt,
    required super.status,
    required super.signature,
    super.destinationCardId,
    super.serviceName,
    super.account,
    super.integrityValid,
    super.failureReason,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) =>
      WalletTransactionModel(
        id: json['id']! as String,
        type: TransactionType.values.byName(json['type']! as String),
        sourceCardId: json['sourceCardId']! as String,
        destinationCardId: json['destinationCardId'] as String?,
        serviceName: json['serviceName'] as String?,
        account: json['account'] as String?,
        amount: json['amount']! as int,
        commission: json['commission']! as int,
        createdAt: DateTime.parse(json['createdAt']! as String),
        status: TransactionStatus.values.byName(json['status']! as String),
        signature: json['signature']! as String,
        failureReason: json['failureReason'] as String?,
      );

  factory WalletTransactionModel.fromEntity(WalletTransaction transaction) =>
      WalletTransactionModel(
        id: transaction.id,
        type: transaction.type,
        sourceCardId: transaction.sourceCardId,
        destinationCardId: transaction.destinationCardId,
        serviceName: transaction.serviceName,
        account: transaction.account,
        amount: transaction.amount,
        commission: transaction.commission,
        createdAt: transaction.createdAt,
        status: transaction.status,
        signature: transaction.signature,
        integrityValid: transaction.integrityValid,
        failureReason: transaction.failureReason,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'sourceCardId': sourceCardId,
        'destinationCardId': destinationCardId,
        'serviceName': serviceName,
        'account': account,
        'amount': amount,
        'commission': commission,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'status': status.name,
        'signature': signature,
        'failureReason': failureReason,
      };
}
