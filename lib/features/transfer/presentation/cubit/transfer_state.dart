import 'package:equatable/equatable.dart';
import 'package:hamyon/core/utils/money_policy.dart';
import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';

enum TransferStatus { initial, editing, submitting, success, failure }

class TransferState extends Equatable {
  const TransferState({
    this.status = TransferStatus.initial,
    this.sourceCardId = '',
    this.destinationCardId = '',
    this.amountInput = '',
    this.pinInput = '',
    this.message,
    this.transaction,
    this.requiresLock = false,
  });

  final TransferStatus status;
  final String sourceCardId;
  final String destinationCardId;
  final String amountInput;
  final String pinInput;
  final String? message;
  final WalletTransaction? transaction;
  final bool requiresLock;

  int get amount => MoneyPolicy.parseAmount(amountInput);
  int get commission => MoneyPolicy.commissionFor(amount);
  int get total => amount + commission;

  TransferState copyWith({
    TransferStatus? status,
    String? sourceCardId,
    String? destinationCardId,
    String? amountInput,
    String? pinInput,
    String? message,
    bool clearMessage = false,
    WalletTransaction? transaction,
    bool? requiresLock,
    bool resetForm = false,
  }) =>
      TransferState(
        status: status ?? this.status,
        sourceCardId: resetForm ? '' : sourceCardId ?? this.sourceCardId,
        destinationCardId:
            resetForm ? '' : destinationCardId ?? this.destinationCardId,
        amountInput: resetForm ? '' : amountInput ?? this.amountInput,
        pinInput: resetForm ? '' : pinInput ?? this.pinInput,
        message: clearMessage ? null : message ?? this.message,
        transaction: transaction ?? this.transaction,
        requiresLock: requiresLock ?? this.requiresLock,
      );

  @override
  List<Object?> get props => [
        status,
        sourceCardId,
        destinationCardId,
        amountInput,
        pinInput,
        message,
        transaction,
        requiresLock,
      ];
}
