import 'package:equatable/equatable.dart';

enum AuthStatus { initial, setupRequired, locked, unlocked, blocked, failure }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.pinInput = '',
    this.setupFirstPin = '',
    this.failedAttempts = 0,
    this.blockedUntil,
    this.remainingSeconds = 0,
    this.message,
    this.biometricAvailable = false,
    this.biometricEnabled = false,
    this.isBiometricSettingInProgress = false,
    this.isSubmitting = false,
  });

  final AuthStatus status;
  final String pinInput;
  final String setupFirstPin;
  final int failedAttempts;
  final DateTime? blockedUntil;
  final int remainingSeconds;
  final String? message;
  final bool biometricAvailable;
  final bool biometricEnabled;
  final bool isBiometricSettingInProgress;
  final bool isSubmitting;

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
    bool? biometricAvailable,
    bool? biometricEnabled,
    bool? isBiometricSettingInProgress,
    bool? isSubmitting,
  }) => AuthState(
    status: status ?? this.status,
    pinInput: pinInput ?? this.pinInput,
    setupFirstPin: setupFirstPin ?? this.setupFirstPin,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    blockedUntil: clearBlockedUntil ? null : blockedUntil ?? this.blockedUntil,
    remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    message: clearMessage ? null : message ?? this.message,
    biometricAvailable: biometricAvailable ?? this.biometricAvailable,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    isBiometricSettingInProgress:
        isBiometricSettingInProgress ?? this.isBiometricSettingInProgress,
    isSubmitting: isSubmitting ?? this.isSubmitting,
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
    biometricAvailable,
    biometricEnabled,
    isBiometricSettingInProgress,
    isSubmitting,
  ];
}
