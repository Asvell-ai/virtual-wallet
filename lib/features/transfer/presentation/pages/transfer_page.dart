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
import 'package:hamyon/features/receipt/domain/services/receipt_service.dart';
import 'package:hamyon/features/receipt/presentation/navigation/receipt_navigation.dart';
import 'package:hamyon/features/transfer/presentation/cubit/transfer_cubit.dart';
import 'package:hamyon/features/transfer/presentation/cubit/transfer_state.dart';

class TransferPage extends StatelessWidget {
  const TransferPage({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<TransferCubit, TransferState>(
    listener: (context, state) async {
      if (state.requiresLock) {
        await context.read<AuthCubit>().enforceGuardLock();
        return;
      }
      if (state.status == TransferStatus.success && state.transaction != null) {
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
      } else if (state.status == TransferStatus.failure &&
          state.message != null &&
          !state.isConfirmingTransfer) {
        await context.read<HistoryCubit>().load();
      }
    },
    builder: (context, state) {
      final cards = context.watch<CardsCubit>().state.cards;
      final source = _selectedCard(cards, state.sourceCardId);
      final destination = _selectedCard(cards, state.destinationCardId);
      final hasInsufficientBalance =
          source != null && state.amount > 0 && state.total > source.balance;
      final canConfirm =
          cards.length >= 2 &&
          state.canRequestConfirmation &&
          source != null &&
          state.total <= source.balance;

      return Scaffold(
        appBar: AppBar(title: const Text('Pul o‘tkazish')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            if (cards.length < 2) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'O‘tkazma uchun kamida 2 ta virtual karta qo‘shing.',
                ),
              ),
            ],
            const SizedBox(height: 20),
            _CardSelectorField(
              label: 'Qaysi kartadan',
              placeholder: 'Yechiladigan kartani tanlang',
              card: source,
              onTap: () => _pickSource(context),
            ),
            const SizedBox(height: 12),
            _CardSelectorField(
              label: 'Qaysi kartaga',
              placeholder: 'Qabul qiluvchi kartani tanlang',
              card: destination,
              onTap: () => _pickDestination(context),
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: context.read<TransferCubit>().amountChanged,
              decoration: InputDecoration(
                labelText: 'O‘tkazma summasi',
                suffixText: 'so‘m',
                prefixIcon: const Icon(Icons.payments_outlined),
                errorText: hasInsufficientBalance
                    ? 'Kartada yetarli mablag‘ mavjud emas'
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Komissiya (0.5%)'),
                      Text(AppFormatters.money(state.commission)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Jami yechiladi',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          AppFormatters.money(state.total),
                          key: ValueKey(state.total),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (state.message != null &&
                state.status == TransferStatus.failure &&
                !state.isConfirmingTransfer)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  state.message!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'O‘tkazmani tasdiqlash',
              icon: Icons.swap_horiz_rounded,
              onPressed: !canConfirm
                  ? null
                  : () => _showPinConfirmation(context),
            ),
          ],
        ),
      );
    },
  );

  WalletCard? _selectedCard(List<WalletCard> cards, String id) {
    for (final card in cards) {
      if (card.id == id) return card;
    }
    return null;
  }

  Future<WalletCard?> _addCard(BuildContext context) async {
    final cardsCubit = context.read<CardsCubit>();
    final added = await showAddCardSheet(context);
    if (!added || cardsCubit.state.cards.isEmpty) return null;
    return cardsCubit.state.cards.last;
  }

  Future<void> _pickSource(BuildContext context) async {
    final cardsCubit = context.read<CardsCubit>();
    final transferCubit = context.read<TransferCubit>();
    final card = await showWalletCardPicker(
      context: context,
      cards: cardsCubit.state.cards,
      selectedCardId: transferCubit.state.sourceCardId,
      title: 'Qaysi kartadan yuboriladi?',
      emptyMessage: 'O‘tkazma uchun avval karta qo‘shing.',
      onAddCard: () => _addCard(context),
    );
    if (card != null) {
      transferCubit.sourceChanged(card.id, balance: card.balance);
    }
  }

  Future<void> _pickDestination(BuildContext context) async {
    final cardsCubit = context.read<CardsCubit>();
    final transferCubit = context.read<TransferCubit>();
    final card = await showWalletCardPicker(
      context: context,
      cards: cardsCubit.state.cards,
      selectedCardId: transferCubit.state.destinationCardId,
      excludedCardId: transferCubit.state.sourceCardId,
      title: 'Qaysi kartaga yuboriladi?',
      emptyMessage: 'Qabul qiluvchi boshqa kartani qo‘shing.',
      onAddCard: () => _addCard(context),
    );
    if (card != null) transferCubit.destinationChanged(card.id);
  }

  Future<void> _showPinConfirmation(BuildContext context) async {
    final transferCubit = context.read<TransferCubit>()..beginConfirmation();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      showDragHandle: false,
      builder: (_) => BlocProvider.value(
        value: transferCubit,
        child: BlocBuilder<TransferCubit, TransferState>(
          builder: (context, state) => FractionallySizedBox(
            heightFactor: 1,
            child: PinConfirmationSheet(
              title: 'O‘tkazmani tasdiqlang',
              subtitle: 'Davom etish uchun 4 xonali PIN-kodingizni kiriting',
              pinLength: state.pinInput.length,
              submitting: state.status == TransferStatus.submitting,
              message: state.status == TransferStatus.failure
                  ? state.message
                  : null,
              onDigit: context.read<TransferCubit>().addPinDigit,
              onBackspace: context.read<TransferCubit>().removePinDigit,
            ),
          ),
        ),
      ),
    );
    if (context.mounted && transferCubit.state.isConfirmingTransfer) {
      transferCubit.cancelConfirmation();
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
            prefixIcon: const Icon(Icons.credit_card_rounded),
            suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
          child: card == null
              ? Text(
                  placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${card!.name} • ${AppFormatters.maskedCard(card!.number)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Mavjud balans: ${AppFormatters.money(card!.balance)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ),
  );
}
