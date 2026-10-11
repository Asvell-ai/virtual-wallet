import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamyon/core/utils/formatters.dart';
import 'package:hamyon/core/widgets/pin_confirmation_sheet.dart';
import 'package:hamyon/core/widgets/primary_button.dart';
import 'package:hamyon/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:hamyon/features/cards/domain/entities/wallet_card.dart';
import 'package:hamyon/features/cards/presentation/cubit/cards_cubit.dart';
import 'package:hamyon/features/cards/presentation/pages/cards_page.dart';
import 'package:hamyon/features/cards/presentation/widgets/card_picker_sheet.dart';
import 'package:hamyon/features/history/presentation/cubit/history_cubit.dart';
import 'package:hamyon/features/home/presentation/cubit/home_cubit.dart';
import 'package:hamyon/features/payments/domain/entities/payment_service.dart';
import 'package:hamyon/features/payments/presentation/cubit/payment_cubit.dart';
import 'package:hamyon/features/payments/presentation/cubit/payment_state.dart';
import 'package:hamyon/features/receipt/domain/services/receipt_service.dart';
import 'package:hamyon/features/receipt/presentation/navigation/receipt_navigation.dart';

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<PaymentCubit, PaymentState>(
    listener: (context, state) async {
      if (state.requiresLock) {
        await context.read<AuthCubit>().enforceGuardLock();
        return;
      }
      if (state.status == PaymentStatus.success && state.transaction != null) {
        await Future.wait([
          context.read<CardsCubit>().load(),
          context.read<HistoryCubit>().load(),
        ]);
        if (!context.mounted) return;
        context.read<HomeCubit>().pageChanged(0);
        await openCompletedOperationReceipt(
          context: context,
          transaction: state.transaction!,
          cards: context.read<CardsCubit>().state.cards,
          receiptService: context.read<ReceiptService>(),
        );
      } else if (state.status == PaymentStatus.failure &&
          state.message != null &&
          !state.isConfirmingPayment) {
        await context.read<HistoryCubit>().load();
      }
    },
    builder: (context, state) {
      final cards = context.watch<CardsCubit>().state.cards;
      final selectedCard = _selectedCard(cards, state.sourceCardId);
      return Scaffold(
        appBar: AppBar(title: const Text('Xizmatlar uchun to‘lov')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PaymentService.values
                  .map(
                    (service) => ChoiceChip(
                      selected: state.service == service,
                      showCheckmark: false,
                      onSelected: (_) =>
                          context.read<PaymentCubit>().serviceChanged(service),
                      avatar: Icon(switch (service) {
                        PaymentService.mobile => Icons.phone_android_rounded,
                        PaymentService.internet => Icons.wifi_rounded,
                        PaymentService.utilities => Icons.home_work_rounded,
                      }),
                      label: Text(service.title),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            _CardSelectorField(
              label: 'To‘lov kartasi',
              placeholder: 'To‘lov kartasini tanlang',
              card: selectedCard,
              onTap: () => _showCardPicker(context),
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: context.read<PaymentCubit>().accountChanged,
              decoration: InputDecoration(
                labelText: state.service.accountLabel,
                prefixIcon: const Icon(Icons.person_search_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: context.read<PaymentCubit>().amountChanged,
              decoration: InputDecoration(
                labelText: 'To‘lov summasi',
                suffixText: 'so‘m',
                prefixIcon: const Icon(Icons.payments_outlined),
                errorText:
                    (selectedCard != null &&
                        state.amount > 0 &&
                        state.amount > selectedCard.balance)
                    ? 'Kartada yetarli mablag‘ mavjud emas'
                    : null,
              ),
            ),
            if (state.message != null &&
                state.status == PaymentStatus.failure &&
                !state.isConfirmingPayment)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  state.message!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'To‘lovni tasdiqlash',
              icon: Icons.receipt_long_rounded,
              onPressed: cards.isEmpty || !state.canRequestConfirmation
                  ? null
                  : () => _showPinConfirmation(context),
            ),
          ],
        ),
      );
    },
  );

  WalletCard? _selectedCard(List<WalletCard> cards, String selectedId) {
    for (final card in cards) {
      if (card.id == selectedId) return card;
    }
    return null;
  }

  Future<void> _showCardPicker(BuildContext context) async {
    final cardsCubit = context.read<CardsCubit>();
    final paymentCubit = context.read<PaymentCubit>();
    final selected = await showWalletCardPicker(
      context: context,
      cards: cardsCubit.state.cards,
      selectedCardId: paymentCubit.state.sourceCardId,
      title: 'Qaysi kartadan to‘lanadi?',
      emptyMessage: 'To‘lov qilish uchun avval karta qo‘shing.',
      onAddCard: () async {
        final added = await showAddCardSheet(context);
        if (!added || cardsCubit.state.cards.isEmpty) return null;
        return cardsCubit.state.cards.last;
      },
    );
    if (selected != null) {
      paymentCubit.sourceChanged(selected.id, balance: selected.balance);
    }
  }

  Future<void> _showPinConfirmation(BuildContext context) async {
    final paymentCubit = context.read<PaymentCubit>()..beginConfirmation();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      showDragHandle: false,
      builder: (_) => BlocProvider.value(
        value: paymentCubit,
        child: BlocBuilder<PaymentCubit, PaymentState>(
          builder: (context, state) => FractionallySizedBox(
            heightFactor: 1,
            child: PinConfirmationSheet(
              title: 'To‘lovni tasdiqlang',
              subtitle: 'Davom etish uchun 4 xonali PIN-kodingizni kiriting',
              pinLength: state.pinInput.length,
              submitting: state.status == PaymentStatus.submitting,
              message: state.status == PaymentStatus.failure
                  ? state.message
                  : null,
              onDigit: context.read<PaymentCubit>().addPinDigit,
              onBackspace: context.read<PaymentCubit>().removePinDigit,
            ),
          ),
        ),
      ),
    );
    if (context.mounted && paymentCubit.state.isConfirmingPayment) {
      paymentCubit.cancelConfirmation();
    }
  }
}

class _CardSelectorField extends StatelessWidget {
  const _CardSelectorField({
    required this.label,
    required this.placeholder,
    required this.card,
    required this.onTap,
  });

  final String label;
  final String placeholder;
  final WalletCard? card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: InputDecorator(
          isEmpty: false,
          decoration: InputDecoration(
            labelText: label,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            prefixIcon: Image.asset(
              "assets/images/uzcard_logo.png",
              height: 30,
              width: 30,
              fit: BoxFit.contain,
            ),
            suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
          child: Text(
            card == null
                ? placeholder
                : '${card!.name} • ${AppFormatters.maskedCard(card!.number)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: card == null
                ? TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )
                : null,
          ),
        ),
      ),
    ),
  );
}
