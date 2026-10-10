import 'package:hamyon/features/settings/domain/repositories/settings_repository.dart';

class GetThemeMode {
  const GetThemeMode(this._repository);

  final SettingsRepository _repository;

  Future<WalletThemeMode> call() => _repository.getThemeMode();
}

class SaveThemeMode {
  const SaveThemeMode(this._repository);

  final SettingsRepository _repository;

  Future<void> call(WalletThemeMode themeMode) =>
      _repository.saveThemeMode(themeMode);
}
