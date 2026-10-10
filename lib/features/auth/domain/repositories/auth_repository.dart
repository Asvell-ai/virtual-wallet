abstract interface class AuthRepository {
  Future<bool> hasVault();
  Future<void> createPin(String pin);
  Future<void> unlock(String pin);
  Future<void> verifyPin(String pin);
  Future<DateTime?> blockedUntil();
  Future<int> failedAttempts();
  Future<bool> isBiometricAvailable();
  Future<bool> isBiometricEnabled();
  Future<void> enableBiometrics(String pin);
  Future<void> disableBiometrics();
  Future<bool> unlockWithBiometrics();
  void lock();
}
