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
  bool _automaticBiometricAttempted = false;

  bool get isBiometricOperationInProgress => _biometricOperationInProgress;

  Future<void> initialize() async {
    bool? hasVault;
    try {
      hasVault = await _repository.hasVault();
      var biometricAvailable = false;
      var biometricEnabled = false;
      try {
        final biometricChecks = await Future.wait<bool>([
          _repository.isBiometricAvailable(),
          _repository.isBiometricEnabled(),
        ]);
        biometricAvailable = biometricChecks[0];
        biometricEnabled = biometricAvailable && biometricChecks[1];
      } catch (_) {
        // Biometric plugin/storage failure must not block PIN authentication.
      }
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
          status: hasVault ? AuthStatus.locked : AuthStatus.setupRequired,
          failedAttempts: await _repository.failedAttempts(),
          biometricAvailable: biometricAvailable,
          biometricEnabled: biometricEnabled,
        ),
      );
      if (hasVault && biometricEnabled) {
        await unlockWithBiometrics(automatic: true);
      }
    } catch (_) {
      emit(
        AuthState(
          status: switch (hasVault) {
            true => AuthStatus.locked,
            false => AuthStatus.setupRequired,
            null => AuthStatus.failure,
          },
          message:
              'Xavfsizlik sozlamalarini o‘qib bo‘lmadi. Qayta urinib ko‘ring.',
        ),
      );
    }
  }

  void addDigit(String digit) {
    if (state.status == AuthStatus.blocked ||
        state.isSubmitting ||
        state.pinInput.length >= 4) {
      return;
    }
    final pinInput = '${state.pinInput}$digit';
    emit(state.copyWith(pinInput: pinInput, clearMessage: true));
    if (pinInput.length == 4) unawaited(submit());
  }

  void removeDigit() {
    if (state.pinInput.isEmpty || state.isSubmitting) return;
    emit(
      state.copyWith(
        pinInput: state.pinInput.substring(0, state.pinInput.length - 1),
        clearMessage: true,
      ),
    );
  }

  Future<void> submit() async {
    if (state.isSubmitting) return;
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
    emit(state.copyWith(isSubmitting: true, clearMessage: true));
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
          isSubmitting: false,
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
          isSubmitting: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: setup ? AuthStatus.setupRequired : AuthStatus.locked,
          message: 'Hamyonni ochib bo‘lmadi. Qayta urinib ko‘ring.',
          pinInput: '',
          isSubmitting: false,
        ),
      );
    }
  }

  Future<void> unlockWithBiometrics({bool automatic = false}) async {
    if (state.status != AuthStatus.locked ||
        !state.biometricEnabled ||
        state.isSubmitting ||
        (automatic && _automaticBiometricAttempted)) {
      return;
    }
    if (automatic) _automaticBiometricAttempted = true;
    emit(state.copyWith(isSubmitting: true, clearMessage: true));
    _biometricOperationInProgress = true;
    try {
      final unlocked = await _repository.unlockWithBiometrics();
      if (!unlocked) {
        emit(state.copyWith(isSubmitting: false));
        return;
      }
      emit(
        state.copyWith(
          status: AuthStatus.unlocked,
          isSubmitting: false,
          clearMessage: true,
        ),
      );
      registerActivity();
    } on BlockedFailure catch (error) {
      _startBlockTimer(error.until);
    } on Failure catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.locked,
          biometricEnabled: await _repository.isBiometricEnabled(),
          message: error.message,
          isSubmitting: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.locked,
          message: 'Biometrik tekshiruvni bajarib bo‘lmadi',
          isSubmitting: false,
        ),
      );
    } finally {
      _biometricOperationInProgress = false;
    }
  }

  Future<bool> biometricSettingChanged({
    required bool enabled,
    String? pin,
  }) async {
    if (state.isBiometricSettingInProgress) return false;
    _biometricOperationInProgress = true;
    emit(
      state.copyWith(isBiometricSettingInProgress: true, clearMessage: true),
    );
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
          isBiometricSettingInProgress: false,
        ),
      );
      return true;
    } on Failure catch (error) {
      emit(
        state.copyWith(
          message: error.message,
          isBiometricSettingInProgress: false,
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          message: 'Biometrik sozlamani o‘zgartirib bo‘lmadi',
          isBiometricSettingInProgress: false,
        ),
      );
      return false;
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
    _automaticBiometricAttempted = false;
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
    _automaticBiometricAttempted = false;
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
        _automaticBiometricAttempted = false;
        emit(
          state.copyWith(
            status: AuthStatus.locked,
            remainingSeconds: 0,
            clearBlockedUntil: true,
            isSubmitting: false,
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
          isSubmitting: false,
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
