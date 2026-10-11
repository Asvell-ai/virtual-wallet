import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamyon/core/error/failures.dart';
import 'package:hamyon/features/auth/domain/repositories/auth_repository.dart';
import 'package:hamyon/features/auth/domain/usecases/auth_usecases.dart';
import 'package:hamyon/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:hamyon/features/auth/presentation/cubit/auth_state.dart';
import 'package:hamyon/features/auth/presentation/pages/pin_page.dart';

void main() {
  test('creates and confirms a PIN automatically after four digits', () async {
    final repository = _FakeAuthRepository(hasVaultValue: false);
    final cubit = AuthCubit(
      repository: repository,
      createPin: CreatePin(repository),
      unlockWallet: UnlockWallet(repository),
    );
    addTearDown(cubit.close);

    await cubit.initialize();
    _enterPin(cubit, '1234');

    expect(cubit.state.status, AuthStatus.setupRequired);
    expect(cubit.state.setupFirstPin, '1234');
    expect(cubit.state.pinInput, isEmpty);

    _enterPin(cubit, '1234');
    await _flushEventQueue();

    expect(repository.createdPin, '1234');
    expect(cubit.state.status, AuthStatus.unlocked);
    expect(cubit.state.isSubmitting, isFalse);
  });

  test('keeps PIN route state while unlock is loading', () async {
    final unlockCompleter = Completer<void>();
    final repository = _FakeAuthRepository(
      hasVaultValue: true,
      unlockCompleter: unlockCompleter,
    );
    final cubit = AuthCubit(
      repository: repository,
      createPin: CreatePin(repository),
      unlockWallet: UnlockWallet(repository),
    );
    addTearDown(cubit.close);

    await cubit.initialize();
    _enterPin(cubit, '1234');

    expect(cubit.state.status, AuthStatus.locked);
    expect(cubit.state.isSubmitting, isTrue);

    unlockCompleter.complete();
    await _flushEventQueue();
    expect(cubit.state.status, AuthStatus.unlocked);
  });

  test('clears PIN and shows the error after an incorrect PIN', () async {
    final repository = _FakeAuthRepository(
      hasVaultValue: true,
      unlockFailure: const AuthenticationFailure(),
    );
    final cubit = AuthCubit(
      repository: repository,
      createPin: CreatePin(repository),
      unlockWallet: UnlockWallet(repository),
    );
    addTearDown(cubit.close);

    await cubit.initialize();
    _enterPin(cubit, '9999');
    await _flushEventQueue();

    expect(cubit.state.status, AuthStatus.locked);
    expect(cubit.state.pinInput, isEmpty);
    expect(cubit.state.message, 'PIN-kod noto‘g‘ri');
    expect(cubit.state.isSubmitting, isFalse);
  });

  test('automatically unlocks with biometrics when the wallet opens', () async {
    final repository = _FakeAuthRepository(
      hasVaultValue: true,
      biometricAvailableValue: true,
      biometricEnabledValue: true,
      biometricUnlockResult: true,
    );
    final cubit = AuthCubit(
      repository: repository,
      createPin: CreatePin(repository),
      unlockWallet: UnlockWallet(repository),
    );
    addTearDown(cubit.close);

    await cubit.initialize();

    expect(repository.biometricUnlockCalls, 1);
    expect(cubit.state.status, AuthStatus.unlocked);
  });

  test(
    'biometric cancel leaves PIN entry available without an auto retry',
    () async {
      final repository = _FakeAuthRepository(
        hasVaultValue: true,
        biometricAvailableValue: true,
        biometricEnabledValue: true,
      );
      final cubit = AuthCubit(
        repository: repository,
        createPin: CreatePin(repository),
        unlockWallet: UnlockWallet(repository),
      );
      addTearDown(cubit.close);

      await cubit.initialize();
      await cubit.unlockWithBiometrics(automatic: true);
      cubit.addDigit('1');

      expect(repository.biometricUnlockCalls, 1);
      expect(cubit.state.status, AuthStatus.locked);
      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.pinInput, '1');
    },
  );

  test('biometric setting exposes progress until enabling finishes', () async {
    final enableCompleter = Completer<void>();
    final repository = _FakeAuthRepository(
      hasVaultValue: true,
      biometricAvailableValue: true,
      biometricEnableCompleter: enableCompleter,
    );
    final cubit = AuthCubit(
      repository: repository,
      createPin: CreatePin(repository),
      unlockWallet: UnlockWallet(repository),
    );
    addTearDown(cubit.close);
    await cubit.initialize();

    final result = cubit.biometricSettingChanged(enabled: true, pin: '1234');
    await _flushEventQueue();

    expect(cubit.state.isBiometricSettingInProgress, isTrue);
    expect(cubit.isBiometricOperationInProgress, isTrue);

    enableCompleter.complete();
    expect(await result, isTrue);
    expect(cubit.state.isBiometricSettingInProgress, isFalse);
    expect(cubit.state.biometricEnabled, isTrue);
    expect(cubit.isBiometricOperationInProgress, isFalse);
  });

  test('unexpected biometric error always clears progress', () async {
    final repository = _FakeAuthRepository(
      hasVaultValue: true,
      biometricAvailableValue: true,
      biometricEnableError: StateError('platform failure'),
    );
    final cubit = AuthCubit(
      repository: repository,
      createPin: CreatePin(repository),
      unlockWallet: UnlockWallet(repository),
    );
    addTearDown(cubit.close);
    await cubit.initialize();

    expect(
      await cubit.biometricSettingChanged(enabled: true, pin: '1234'),
      isFalse,
    );
    expect(cubit.state.isBiometricSettingInProgress, isFalse);
    expect(cubit.isBiometricOperationInProgress, isFalse);
    expect(cubit.state.message, 'Biometrik sozlamani o‘zgartirib bo‘lmadi');
  });

  testWidgets('incorrect PIN stays render-safe on a short screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeAuthRepository(
      hasVaultValue: true,
      unlockFailure: const AuthenticationFailure(),
    );
    final cubit = AuthCubit(
      repository: repository,
      createPin: CreatePin(repository),
      unlockWallet: UnlockWallet(repository),
    );
    addTearDown(cubit.close);
    await cubit.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthCubit>.value(
          value: cubit,
          child: const PinPage(),
        ),
      ),
    );

    for (var index = 0; index < 4; index++) {
      await tester.tap(find.text('9'));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    expect(find.text('PIN-kod noto‘g‘ri'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'fingerprint action is left of zero and keypad clears the bottom',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _FakeAuthRepository(
        hasVaultValue: true,
        biometricAvailableValue: true,
        biometricEnabledValue: true,
      );
      final cubit = AuthCubit(
        repository: repository,
        createPin: CreatePin(repository),
        unlockWallet: UnlockWallet(repository),
      );
      addTearDown(cubit.close);
      await cubit.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>.value(
            value: cubit,
            child: const PinPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fingerprint = find.byIcon(Icons.fingerprint_rounded);
      final zero = find.text('0');
      final backspace = find.byIcon(Icons.backspace_outlined);
      expect(fingerprint, findsOneWidget);
      expect(find.text('Barmoq izi yoki Face ID'), findsNothing);
      expect(
        tester.getCenter(fingerprint).dx,
        lessThan(tester.getCenter(zero).dx),
      );
      expect(tester.getCenter(fingerprint).dy, tester.getCenter(zero).dy);
      expect(tester.getBottomRight(backspace).dy, lessThan(780));
      expect(tester.takeException(), isNull);
    },
  );
}

void _enterPin(AuthCubit cubit, String pin) {
  for (final digit in pin.split('')) {
    cubit.addDigit(digit);
  }
}

Future<void> _flushEventQueue() => Future<void>.delayed(Duration.zero);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    required this.hasVaultValue,
    this.unlockCompleter,
    this.unlockFailure,
    this.biometricAvailableValue = false,
    this.biometricEnabledValue = false,
    this.biometricUnlockResult = false,
    this.biometricEnableCompleter,
    this.biometricEnableError,
  });

  final bool hasVaultValue;
  final Completer<void>? unlockCompleter;
  final Failure? unlockFailure;
  final bool biometricAvailableValue;
  final bool biometricEnabledValue;
  final bool biometricUnlockResult;
  final Completer<void>? biometricEnableCompleter;
  final Object? biometricEnableError;
  String? createdPin;
  int biometricUnlockCalls = 0;

  @override
  Future<bool> hasVault() async => hasVaultValue;

  @override
  Future<void> createPin(String pin) async => createdPin = pin;

  @override
  Future<void> unlock(String pin) async {
    if (unlockFailure case final failure?) throw failure;
    await unlockCompleter?.future;
  }

  @override
  Future<int> failedAttempts() async => unlockFailure == null ? 0 : 1;

  @override
  Future<DateTime?> blockedUntil() async => null;

  @override
  Future<bool> isBiometricAvailable() async => biometricAvailableValue;

  @override
  Future<bool> isBiometricEnabled() async => biometricEnabledValue;

  @override
  Future<void> enableBiometrics(String pin) async {
    if (biometricEnableError case final error?) throw error;
    await biometricEnableCompleter?.future;
  }

  @override
  Future<void> disableBiometrics() async {}

  @override
  Future<bool> unlockWithBiometrics() async {
    biometricUnlockCalls += 1;
    return biometricUnlockResult;
  }

  @override
  Future<void> verifyPin(String pin) async {}

  @override
  void lock() {}
}
