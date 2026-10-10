import 'package:equatable/equatable.dart';
import 'package:hamyon/core/utils/money_policy.dart';
import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';
import 'package:hamyon/features/payments/domain/entities/payment_service.dart';

enum PaymentStatus { initial, editing, submitting, success, failure }

class PaymentState extends Equatable {
  const PaymentState({
    this.status = PaymentStatus.initial,
    this.sourceCardId = '',
    this.service = PaymentService.mobile,
    this.accountInput = '',
    this.amountInput = '',
    this.pinInput = '',
    this.message,
    this.transaction,
    this.requiresLock = false,
  });

  final PaymentStatus status;
  final String sourceCardId;
  final PaymentService service;
  final String accountInput;
  final String amountInput;
  final String pinInput;
  final String? message;
  final WalletTransaction? transaction;
  final bool requiresLock;

  int get amount => MoneyPolicy.parseAmount(amountInput);

  PaymentState copyWith({
    PaymentStatus? status,
    String? sourceCardId,
    PaymentService? service,
    String? accountInput,
    String? amountInput,
    String? pinInput,
    String? message,
    bool clearMessage = false,
    WalletTransaction? transaction,
    bool? requiresLock,
    bool resetForm = false,
  }) =>
      PaymentState(
        status: status ?? this.status,
        sourceCardId: resetForm ? '' : sourceCardId ?? this.sourceCardId,
        service: service ?? this.service,
        accountInput: resetForm ? '' : accountInput ?? this.accountInput,
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
        service,
        accountInput,
        amountInput,
        pinInput,
        message,
        transaction,
        requiresLock,
      ];
}
