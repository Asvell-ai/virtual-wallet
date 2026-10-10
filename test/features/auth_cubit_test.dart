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

  testWidgets('incorrect PIN stays render-safe on a short screen',
      (tester) async {
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
  });

  final bool hasVaultValue;
  final Completer<void>? unlockCompleter;
  final Failure? unlockFailure;
  String? createdPin;

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
  Future<bool> isBiometricAvailable() async => false;

  @override
  Future<bool> isBiometricEnabled() async => false;

  @override
  Future<void> enableBiometrics(String pin) async {}

  @override
  Future<void> disableBiometrics() async {}

  @override
  Future<bool> unlockWithBiometrics() async => false;

  @override
  Future<void> verifyPin(String pin) async {}

  @override
  void lock() {}
}
