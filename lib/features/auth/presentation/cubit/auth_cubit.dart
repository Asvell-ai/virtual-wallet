import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamyon/core/error/failures.dart';
import 'package:hamyon/features/auth/domain/repositories/auth_repository.dart';
import 'package:hamyon/features/auth/domain/usecases/auth_usecases.dart';
import 'package:hamyon/features/auth/presentation/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required AuthRepository repository,
    required CreatePin createPin,
    required UnlockWallet unlockWallet,
  }) : _repository = repository,
       _createPin = createPin,
       _unlockWallet = unlockWallet,
       super(const AuthState());

  static const inactivityDuration = Duration(minutes: 2);

  final AuthRepository _repository;
  final CreatePin _createPin;
  final UnlockWallet _unlockWallet;
  Timer? _inactivityTimer;
  Timer? _blockTimer;
  bool _biometricOperationInProgress = false;

  bool get isBiometricOperationInProgress => _biometricOperationInProgress;

  Future<void> initialize() async {
    final biometricAvailable = await _repository.isBiometricAvailable();
    final biometricEnabled =
        biometricAvailable && await _repository.isBiometricEnabled();
    final blocked = await _repository.blockedUntil();
    if (blocked != null) {
      _startBlockTimer(
        blocked,
        biometricAvailable: biometricAvailable,
        biometricEnabled: biometricEnabled,
      );
      return;
    }
    emit(
      AuthState(
        status: await _repository.hasVault()
            ? AuthStatus.locked
            : AuthStatus.setupRequired,
        failedAttempts: await _repository.failedAttempts(),
        biometricAvailable: biometricAvailable,
        biometricEnabled: biometricEnabled,
      ),
    );
  }

  void addDigit(String digit) {
    if (state.status == AuthStatus.blocked || state.pinInput.length >= 4) {
      return;
    }
    emit(
      state.copyWith(pinInput: '${state.pinInput}$digit', clearMessage: true),
    );
  }

  void removeDigit() {
    if (state.pinInput.isEmpty) return;
    emit(
      state.copyWith(
        pinInput: state.pinInput.substring(0, state.pinInput.length - 1),
        clearMessage: true,
      ),
    );
  }

  Future<void> submit() async {
    if (state.pinInput.length != 4) {
      emit(state.copyWith(message: '4 ta raqam kiriting'));
      return;
    }
    if (state.status == AuthStatus.setupRequired) {
      if (!state.isConfirmingSetup) {
        emit(
          state.copyWith(
            setupFirstPin: state.pinInput,
            pinInput: '',
            clearMessage: true,
          ),
        );
        return;
      }
      if (state.setupFirstPin != state.pinInput) {
        emit(
          state.copyWith(
            pinInput: '',
            setupFirstPin: '',
            message: 'PIN-kodlar mos kelmadi. Qayta kiriting.',
          ),
        );
        return;
      }
    }

    final setup = state.status == AuthStatus.setupRequired;
    emit(state.copyWith(status: AuthStatus.loading, clearMessage: true));
    try {
      if (setup) {
        await _createPin(state.pinInput);
      } else {
        await _unlockWallet(state.pinInput);
      }
      emit(
        state.copyWith(
          status: AuthStatus.unlocked,
          pinInput: '',
          setupFirstPin: '',
          clearMessage: true,
        ),
      );
      registerActivity();
    } on BlockedFailure catch (error) {
      _startBlockTimer(error.until);
    } on Failure catch (error) {
      emit(
        state.copyWith(
          status: setup ? AuthStatus.setupRequired : AuthStatus.locked,
          failedAttempts: await _repository.failedAttempts(),
          message: error.message,
          pinInput: '',
        ),
      );
    }
  }

  Future<void> unlockWithBiometrics() async {
    if (state.status != AuthStatus.locked || !state.biometricEnabled) return;
    emit(state.copyWith(status: AuthStatus.loading, clearMessage: true));
    _biometricOperationInProgress = true;
    try {
      final unlocked = await _repository.unlockWithBiometrics();
      if (!unlocked) {
        emit(state.copyWith(status: AuthStatus.locked));
        return;
      }
      emit(state.copyWith(status: AuthStatus.unlocked, clearMessage: true));
      registerActivity();
    } on BlockedFailure catch (error) {
      _startBlockTimer(error.until);
    } on Failure catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.locked,
          biometricEnabled: await _repository.isBiometricEnabled(),
          message: error.message,
        ),
      );
    } finally {
      _biometricOperationInProgress = false;
    }
  }

  Future<void> biometricSettingChanged({
    required bool enabled,
    String? pin,
  }) async {
    _biometricOperationInProgress = enabled;
    try {
      if (enabled) {
        if (pin == null || pin.length != 4) {
          throw const ValidationFailure('4 xonali PIN-kodni kiriting');
        }
        await _repository.enableBiometrics(pin);
      } else {
        await _repository.disableBiometrics();
      }
      emit(
        state.copyWith(
          biometricEnabled: enabled,
          message: enabled
              ? 'Biometrik kirish yoqildi'
              : 'Biometrik kirish o‘chirildi',
        ),
      );
    } on Failure catch (error) {
      emit(state.copyWith(message: error.message));
    } finally {
      _biometricOperationInProgress = false;
    }
  }

  void registerActivity() {
    if (state.status != AuthStatus.unlocked) return;
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityDuration, lock);
  }

  void lock() {
    if (state.status != AuthStatus.unlocked) return;
    _inactivityTimer?.cancel();
    _repository.lock();
    emit(
      state.copyWith(
        status: AuthStatus.locked,
        pinInput: '',
        clearMessage: true,
      ),
    );
  }

  Future<void> enforceGuardLock() async {
    _inactivityTimer?.cancel();
    _repository.lock();
    final until = await _repository.blockedUntil();
    if (until != null) {
      _startBlockTimer(until);
    } else {
      emit(state.copyWith(status: AuthStatus.locked, clearMessage: true));
    }
  }

  void _startBlockTimer(
    DateTime until, {
    bool? biometricAvailable,
    bool? biometricEnabled,
  }) {
    _inactivityTimer?.cancel();
    _blockTimer?.cancel();
    void tick() {
      final seconds = until.difference(DateTime.now()).inSeconds + 1;
      if (seconds <= 0) {
        _blockTimer?.cancel();
        emit(
          state.copyWith(
            status: AuthStatus.locked,
            remainingSeconds: 0,
            clearBlockedUntil: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: AuthStatus.blocked,
          blockedUntil: until,
          remainingSeconds: seconds,
          biometricAvailable: biometricAvailable,
          biometricEnabled: biometricEnabled,
          pinInput: '',
        ),
      );
    }

    tick();
    _blockTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  @override
  Future<void> close() {
    _inactivityTimer?.cancel();
    _blockTimer?.cancel();
    return super.close();
  }
}
