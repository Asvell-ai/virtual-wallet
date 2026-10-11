import 'dart:convert';

import 'package:equatable/equatable.dart';

enum TransactionType { transfer, payment }

enum TransactionStatus { completed, failed, tampered }

class WalletTransaction extends Equatable {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.sourceCardId,
    required this.amount,
    required this.commission,
    required this.createdAt,
    required this.status,
    required this.signature,
    this.destinationCardId,
    this.serviceName,
    this.account,
    this.integrityValid = true,
    this.failureReason,
  });

  final String id;
  final TransactionType type;
  final String sourceCardId;
  final String? destinationCardId;
  final String? serviceName;
  final String? account;
  final int amount;
  final int commission;
  final DateTime createdAt;
  final TransactionStatus status;
  final String signature;
  final bool integrityValid;
  final String? failureReason;

  String get signingPayload => jsonEncode(<String, dynamic>{
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
    'failureReason': failureReason,
  });

  WalletTransaction copyWith({
    String? signature,
    bool? integrityValid,
    TransactionStatus? status,
  }) => WalletTransaction(
    id: id,
    type: type,
    sourceCardId: sourceCardId,
    destinationCardId: destinationCardId,
    serviceName: serviceName,
    account: account,
    amount: amount,
    commission: commission,
    createdAt: createdAt,
    status: status ?? this.status,
    signature: signature ?? this.signature,
    integrityValid: integrityValid ?? this.integrityValid,
    failureReason: failureReason,
  );

  @override
  List<Object?> get props => [
    id,
    type,
    sourceCardId,
    destinationCardId,
    serviceName,
    account,
    amount,
    commission,
    createdAt,
    status,
    signature,
    integrityValid,
    failureReason,
  ];
}
