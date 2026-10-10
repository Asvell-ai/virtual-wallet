import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hamyon/core/security/secure_vault.dart';
import 'package:hamyon/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:hamyon/features/settings/domain/repositories/settings_repository.dart';

void main() {
  test('tema tanlovi shifrlangan vault ichida saqlanadi', () async {
    final directory = await Directory.systemTemp.createTemp(
      'hamyon_settings_test_',
    );
    addTearDown(() => directory.delete(recursive: true));

    final vault = SecureVault.forDirectory(directory);
    await vault.createNew('1234');
    final repository = SettingsRepositoryImpl(vault);

    expect(await repository.getThemeMode(), WalletThemeMode.system);
    await repository.saveThemeMode(WalletThemeMode.dark);

    final raw = await File('${directory.path}/hamyon_vault.dat').readAsString();
    expect(raw, isNot(contains('themeMode')));

    vault.lock();
    final reopenedVault = SecureVault.forDirectory(directory);
    expect(await reopenedVault.unlock('1234'), isTrue);
    expect(
      await SettingsRepositoryImpl(reopenedVault).getThemeMode(),
      WalletThemeMode.dark,
    );
  });
}
