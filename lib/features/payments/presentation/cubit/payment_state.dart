import 'package:equatable/equatable.dart';
import 'package:hamyon/core/utils/money_policy.dart';
import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';
import 'package:hamyon/features/payments/domain/entities/payment_service.dart';

enum PaymentStatus { initial, editing, submitting, success, failure }

class PaymentState extends Equatable {
  const PaymentState({
    this.status = PaymentStatus.initial,
    this.sourceCardId = '',
    this.sourceBalance = 0,
    this.service = PaymentService.mobile,
    this.accountInput = '',
    this.amountInput = '',
    this.pinInput = '',
    this.message,
    this.transaction,
    this.requiresLock = false,
    this.isConfirmingPayment = false,
  });

  final PaymentStatus status;
  final String sourceCardId;
  final int sourceBalance;
  final PaymentService service;
  final String accountInput;
  final String amountInput;
  final String pinInput;
  final String? message;
  final WalletTransaction? transaction;
  final bool requiresLock;
  final bool isConfirmingPayment;

  int get amount => MoneyPolicy.parseAmount(amountInput);

  bool get isAccountValid {
    if (service == PaymentService.mobile) {
      final digits = accountInput.replaceAll(RegExp(r'\D'), '');
      return digits.length == 9 || (digits.length == 12 && digits.startsWith('998'));
    }
    return accountInput.trim().length >= 5;
  }

  bool get canRequestConfirmation =>
      sourceCardId.isNotEmpty &&
      isAccountValid &&
      amount > 0 &&
      amount <= sourceBalance;

  PaymentState copyWith({
    PaymentStatus? status,
    String? sourceCardId,
    int? sourceBalance,
    PaymentService? service,
    String? accountInput,
    String? amountInput,
    String? pinInput,
    String? message,
    bool clearMessage = false,
    WalletTransaction? transaction,
    bool? requiresLock,
    bool? isConfirmingPayment,
    bool resetForm = false,
  }) => PaymentState(
    status: status ?? this.status,
    sourceCardId: resetForm ? '' : sourceCardId ?? this.sourceCardId,
    sourceBalance: resetForm ? 0 : sourceBalance ?? this.sourceBalance,
    service: service ?? this.service,
    accountInput: resetForm ? '' : accountInput ?? this.accountInput,
    amountInput: resetForm ? '' : amountInput ?? this.amountInput,
    pinInput: resetForm ? '' : pinInput ?? this.pinInput,
    message: clearMessage ? null : message ?? this.message,
    transaction: transaction ?? this.transaction,
    requiresLock: requiresLock ?? this.requiresLock,
    isConfirmingPayment: isConfirmingPayment ?? this.isConfirmingPayment,
  );

  @override
  List<Object?> get props => [
    status,
    sourceCardId,
    sourceBalance,
    service,
    accountInput,
    amountInput,
    pinInput,
    message,
    transaction,
    requiresLock,
    isConfirmingPayment,
  ];
}
