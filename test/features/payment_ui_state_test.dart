import 'package:flutter_test/flutter_test.dart';
import 'package:hamyon/features/home/presentation/cubit/home_cubit.dart';
import 'package:hamyon/features/payments/presentation/cubit/payment_state.dart';
import 'package:hamyon/features/transfer/presentation/cubit/transfer_state.dart';

void main() {
  test('balance entrance animation is consumed only once per app session', () {
    final cubit = HomeCubit();
    addTearDown(cubit.close);

    expect(cubit.consumeBalanceAnimation(), isTrue);
    expect(cubit.consumeBalanceAnimation(), isFalse);
  });

  test('payment confirmation is enabled only after required details', () {
    const initial = PaymentState();
    expect(initial.canRequestConfirmation, isFalse);

    final ready = initial.copyWith(
      sourceCardId: 'card-1',
      sourceBalance: 30000,
      accountInput: '998901234567',
      amountInput: '25000',
    );
    expect(ready.canRequestConfirmation, isTrue);
    expect(ready.copyWith(amountInput: '0').canRequestConfirmation, isFalse);
    expect(
      ready.copyWith(amountInput: '30001').canRequestConfirmation,
      isFalse,
    );
  });

  test('transfer confirmation requires two different cards, valid amount, and sufficient balance', () {
    const initial = TransferState();
    expect(initial.canRequestConfirmation, isFalse);

    final ready = initial.copyWith(
      sourceCardId: 'card-1',
      sourceBalance: 100000,
      destinationCardId: 'card-2',
      amountInput: '50000',
    );
    expect(ready.canRequestConfirmation, isTrue);
    expect(ready.isBalanceInsufficient, isFalse);

    expect(
      ready.copyWith(destinationCardId: 'card-1').canRequestConfirmation,
      isFalse,
    );

    final exceedBalance = ready.copyWith(amountInput: '200000');
    expect(exceedBalance.isBalanceInsufficient, isTrue);
    expect(exceedBalance.canRequestConfirmation, isFalse);
  });
}
