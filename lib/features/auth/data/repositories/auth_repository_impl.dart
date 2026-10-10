import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hamyon/core/error/failures.dart';
import 'package:hamyon/core/security/secure_vault.dart';
import 'package:hamyon/features/auth/domain/repositories/auth_repository.dart';
import 'package:local_auth/local_auth.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._vault,
    this._secureStorage, {
    LocalAuthentication? localAuthentication,
  }) : _localAuthentication = localAuthentication ?? LocalAuthentication();

  static const _attemptsKey = 'hamyon.failed_attempts';
  static const _blockedUntilKey = 'hamyon.blocked_until';
  static const _biometricPinKey = 'hamyon.biometric_pin';

  final SecureVault _vault;
  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuthentication;

  @override
  Future<bool> hasVault() => _vault.exists();

  @override
  Future<void> createPin(String pin) async {
    await _vault.createNew(pin);
    await _clearGuard();
  }

  @override
  Future<void> unlock(String pin) async {
    await _checkBlocked();
    if (!await _vault.unlock(pin)) {
      await _registerFailure();
      throw const AuthenticationFailure();
    }
    await _clearGuard();
  }

  @override
  Future<void> verifyPin(String pin) async {
    await _checkBlocked();
    if (!await _vault.verifyPin(pin)) {
      await _registerFailure();
      throw const AuthenticationFailure();
    }
    await _clearGuard();
  }

  @override
  Future<DateTime?> blockedUntil() async {
    final raw = await _secureStorage.read(key: _blockedUntilKey);
    final value = raw == null ? null : DateTime.tryParse(raw);
    if (value != null && !value.isAfter(DateTime.now())) {
      await _clearGuard();
      return null;
    }
    return value;
  }

  @override
  Future<int> failedAttempts() async =>
      int.tryParse(await _secureStorage.read(key: _attemptsKey) ?? '') ?? 0;

  @override
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuthentication.canCheckBiometrics &&
          (await _localAuthentication.getAvailableBiometrics()).isNotEmpty;
    } on LocalAuthException {
      return false;
    }
  }

  @override
  Future<bool> isBiometricEnabled() async =>
      await _secureStorage.containsKey(key: _biometricPinKey);

  @override
  Future<void> enableBiometrics(String pin) async {
    if (!await isBiometricAvailable()) {
      throw const AuthenticationFailure(
        'Qurilmada barmoq izi yoki Face ID sozlanmagan',
      );
    }
    await verifyPin(pin);
    final authenticated = await _authenticateBiometrically(
      reason: 'Biometrik kirishni yoqish uchun tasdiqlang',
    );
    if (!authenticated) {
      throw const AuthenticationFailure('Biometrik tasdiqlash bekor qilindi');
    }
    await _secureStorage.write(key: _biometricPinKey, value: pin);
  }

  @override
  Future<void> disableBiometrics() =>
      _secureStorage.delete(key: _biometricPinKey);

  @override
  Future<bool> unlockWithBiometrics() async {
    await _checkBlocked();
    final pin = await _secureStorage.read(key: _biometricPinKey);
    if (pin == null) return false;
    final authenticated = await _authenticateBiometrically(
      reason: 'Hamyonni ochish uchun shaxsingizni tasdiqlang',
    );
    if (!authenticated) return false;
    if (!await _vault.unlock(pin)) {
      await disableBiometrics();
      throw const AuthenticationFailure(
        'Biometrik kirish ma’lumoti eskirgan. PIN bilan kiring.',
      );
    }
    await _clearGuard();
    return true;
  }

  @override
  void lock() => _vault.lock();

  Future<bool> _authenticateBiometrically({required String reason}) async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (error) {
      if (error.code == LocalAuthExceptionCode.userCanceled ||
          error.code == LocalAuthExceptionCode.systemCanceled) {
        return false;
      }
      throw const AuthenticationFailure(
        'Biometrik tekshiruvni bajarib bo‘lmadi',
      );
    }
  }

  Future<void> _checkBlocked() async {
    final until = await blockedUntil();
    if (until != null) throw BlockedFailure(until);
  }

  Future<void> _registerFailure() async {
    final attempts = await failedAttempts() + 1;
    if (attempts >= 3) {
      final until = DateTime.now().add(const Duration(seconds: 30));
      await _secureStorage.write(
        key: _blockedUntilKey,
        value: until.toIso8601String(),
      );
      await _secureStorage.write(key: _attemptsKey, value: '0');
      throw BlockedFailure(until);
    }
    await _secureStorage.write(key: _attemptsKey, value: '$attempts');
  }

  Future<void> _clearGuard() async {
    await _secureStorage.delete(key: _attemptsKey);
    await _secureStorage.delete(key: _blockedUntilKey);
  }
}
