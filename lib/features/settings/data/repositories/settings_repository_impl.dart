import 'package:hamyon/core/security/secure_vault.dart';
import 'package:hamyon/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._vault);

  final SecureVault _vault;

  @override
  Future<WalletThemeMode> getThemeMode() async {
    final database = await _vault.read();
    final value = (database['settings'] as Map?)?['themeMode'];
    return WalletThemeMode.values
            .where((mode) => mode.name == value)
            .firstOrNull ??
        WalletThemeMode.system;
  }

  @override
  Future<void> saveThemeMode(WalletThemeMode themeMode) =>
      _vault.mutate<void>((database) {
        final settings = Map<String, dynamic>.from(
          database['settings'] as Map? ?? const <String, dynamic>{},
        );
        settings['themeMode'] = themeMode.name;
        database['settings'] = settings;
      });
}
