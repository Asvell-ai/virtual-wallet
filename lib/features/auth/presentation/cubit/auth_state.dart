import 'package:equatable/equatable.dart';

enum AuthStatus {
  initial,
  setupRequired,
  locked,
  loading,
  unlocked,
  blocked,
  failure,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.pinInput = '',
    this.setupFirstPin = '',
    this.failedAttempts = 0,
    this.blockedUntil,
    this.remainingSeconds = 0,
    this.message,
  });

  final AuthStatus status;
  final String pinInput;
  final String setupFirstPin;
  final int failedAttempts;
  final DateTime? blockedUntil;
  final int remainingSeconds;
  final String? message;

  bool get isConfirmingSetup => setupFirstPin.isNotEmpty;

  AuthState copyWith({
    AuthStatus? status,
    String? pinInput,
    String? setupFirstPin,
    int? failedAttempts,
    DateTime? blockedUntil,
    bool clearBlockedUntil = false,
    int? remainingSeconds,
    String? message,
    bool clearMessage = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        pinInput: pinInput ?? this.pinInput,
        setupFirstPin: setupFirstPin ?? this.setupFirstPin,
        failedAttempts: failedAttempts ?? this.failedAttempts,
        blockedUntil:
            clearBlockedUntil ? null : blockedUntil ?? this.blockedUntil,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        message: clearMessage ? null : message ?? this.message,
      );

  @override
  List<Object?> get props => [
        status,
        pinInput,
        setupFirstPin,
        failedAttempts,
        blockedUntil,
        remainingSeconds,
        message,
      ];
}
