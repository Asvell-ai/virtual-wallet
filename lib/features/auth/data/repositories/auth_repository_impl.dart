import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hamyon/core/error/failures.dart';
import 'package:hamyon/core/security/secure_vault.dart';
import 'package:hamyon/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._vault, this._secureStorage);

  static const _attemptsKey = 'hamyon.failed_attempts';
  static const _blockedUntilKey = 'hamyon.blocked_until';

  final SecureVault _vault;
  final FlutterSecureStorage _secureStorage;

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
  void lock() => _vault.lock();

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
