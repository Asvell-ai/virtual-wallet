import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hamyon/core/error/failures.dart';
import 'package:hamyon/core/security/secure_vault.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('hamyon_vault_test_');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('ma’lumot AES-GCM bilan shifrlanadi va qayta ochiladi', () async {
    final vault = SecureVault.forDirectory(directory);
    await vault.createNew('1234');
    await vault.mutate((database) {
      database['secretMarker'] = 'ochiq_korinmasligi_kerak';
    });

    final raw = await File('${directory.path}/hamyon_vault.dat').readAsString();
    expect(raw, isNot(contains('ochiq_korinmasligi_kerak')));
    expect(raw, contains('AES-256-GCM'));

    vault.lock();
    final reopened = SecureVault.forDirectory(directory);
    expect(await reopened.unlock('0000'), isFalse);
    expect(await reopened.unlock('1234'), isTrue);
    expect((await reopened.read())['secretMarker'], 'ochiq_korinmasligi_kerak');
  });

  test('ciphertext qo‘lda o‘zgartirilsa GCM tekshiruvi rad etadi', () async {
    final vault = SecureVault.forDirectory(directory);
    await vault.createNew('1234');
    final file = File('${directory.path}/hamyon_vault.dat');
    final raw = await file.readAsString();
    final changed = raw.replaceFirst('ciphertext":"', 'ciphertext":"A');
    await file.writeAsString(changed);

    final reopened = SecureVault.forDirectory(directory);
    await expectLater(
      reopened.unlock('1234'),
      throwsA(isA<IntegrityFailure>()),
    );
  });
}
