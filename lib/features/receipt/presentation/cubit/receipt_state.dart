import 'package:equatable/equatable.dart';

enum ReceiptStatus { idle, working, saved, shared, failure }

class ReceiptState extends Equatable {
  const ReceiptState({
    this.status = ReceiptStatus.idle,
    this.filePath,
    this.message,
  });

  final ReceiptStatus status;
  final String? filePath;
  final String? message;

  ReceiptState copyWith({
    ReceiptStatus? status,
    String? filePath,
    String? message,
  }) =>
      ReceiptState(
        status: status ?? this.status,
        filePath: filePath ?? this.filePath,
        message: message ?? this.message,
      );

  @override
  List<Object?> get props => [status, filePath, message];
}
