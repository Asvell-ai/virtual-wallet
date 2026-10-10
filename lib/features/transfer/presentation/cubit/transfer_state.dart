import 'package:equatable/equatable.dart';
import 'package:hamyon/core/utils/money_policy.dart';
import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';

enum TransferStatus { initial, editing, submitting, success, failure }

class TransferState extends Equatable {
  const TransferState({
    this.status = TransferStatus.initial,
    this.sourceCardId = '',
    this.sourceBalance = 0,
    this.destinationCardId = '',
    this.amountInput = '',
    this.pinInput = '',
    this.message,
    this.transaction,
    this.requiresLock = false,
    this.isConfirmingTransfer = false,
  });

  final TransferStatus status;
  final String sourceCardId;
  final int sourceBalance;
  final String destinationCardId;
  final String amountInput;
  final String pinInput;
  final String? message;
  final WalletTransaction? transaction;
  final bool requiresLock;
  final bool isConfirmingTransfer;

  int get amount => MoneyPolicy.parseAmount(amountInput);
  int get commission => MoneyPolicy.commissionFor(amount);
  int get total => amount + commission;

  bool get isBalanceInsufficient =>
      sourceCardId.isNotEmpty &&
      sourceBalance > 0 &&
      amount > 0 &&
      total > sourceBalance;

  bool get canRequestConfirmation =>
      sourceCardId.isNotEmpty &&
      destinationCardId.isNotEmpty &&
      sourceCardId != destinationCardId &&
      amount > 0 &&
      (sourceBalance <= 0 || total <= sourceBalance);

  TransferState copyWith({
    TransferStatus? status,
    String? sourceCardId,
    int? sourceBalance,
    String? destinationCardId,
    String? amountInput,
    String? pinInput,
    String? message,
    bool clearMessage = false,
    WalletTransaction? transaction,
    bool? requiresLock,
    bool? isConfirmingTransfer,
    bool resetForm = false,
  }) => TransferState(
    status: status ?? this.status,
    sourceCardId: resetForm ? '' : sourceCardId ?? this.sourceCardId,
    sourceBalance: resetForm ? 0 : sourceBalance ?? this.sourceBalance,
    destinationCardId: resetForm
        ? ''
        : destinationCardId ?? this.destinationCardId,
    amountInput: resetForm ? '' : amountInput ?? this.amountInput,
    pinInput: resetForm ? '' : pinInput ?? this.pinInput,
    message: clearMessage ? null : message ?? this.message,
    transaction: transaction ?? this.transaction,
    requiresLock: requiresLock ?? this.requiresLock,
    isConfirmingTransfer: isConfirmingTransfer ?? this.isConfirmingTransfer,
  );

  @override
  List<Object?> get props => [
    status,
    sourceCardId,
    sourceBalance,
    destinationCardId,
    amountInput,
    pinInput,
    message,
    transaction,
    requiresLock,
    isConfirmingTransfer,
  ];
}
