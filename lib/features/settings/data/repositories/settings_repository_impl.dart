import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hamyon/core/security/secure_vault.dart';
import 'package:hamyon/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._vault, [this._secureStorage]);

  static const _themeModeKey = 'hamyon.theme_mode';

  final SecureVault _vault;
  final FlutterSecureStorage? _secureStorage;

  @override
  Future<WalletThemeMode> getThemeMode() async {
    final cachedValue = await _secureStorage?.read(key: _themeModeKey);
    final cachedMode = _parseThemeMode(cachedValue);
    if (cachedMode != null) return cachedMode;
    if (!_vault.isUnlocked) return WalletThemeMode.system;

    final database = await _vault.read();
    final value = (database['settings'] as Map?)?['themeMode'];
    final mode = _parseThemeMode(value) ?? WalletThemeMode.system;
    await _secureStorage?.write(key: _themeModeKey, value: mode.name);
    return mode;
  }

  @override
  Future<void> saveThemeMode(WalletThemeMode themeMode) async {
    await _secureStorage?.write(key: _themeModeKey, value: themeMode.name);
    await _vault.mutate<void>((database) {
      final settings = Map<String, dynamic>.from(
        database['settings'] as Map? ?? const <String, dynamic>{},
      );
      settings['themeMode'] = themeMode.name;
      database['settings'] = settings;
    });
  }

  WalletThemeMode? _parseThemeMode(Object? value) =>
      WalletThemeMode.values.where((mode) => mode.name == value).firstOrNull;
}
