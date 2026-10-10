enum WalletThemeMode { system, light, dark }

abstract interface class SettingsRepository {
  Future<WalletThemeMode> getThemeMode();
  Future<void> saveThemeMode(WalletThemeMode themeMode);
}
