import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamyon/core/utils/formatters.dart';
import 'package:hamyon/features/cards/domain/entities/wallet_card.dart';
import 'package:hamyon/features/cards/presentation/cubit/cards_cubit.dart';
import 'package:hamyon/features/cards/presentation/widgets/wallet_card_tile.dart';
import 'package:hamyon/features/history/presentation/cubit/history_cubit.dart';
import 'package:hamyon/features/history/presentation/widgets/transaction_tile.dart';
import 'package:hamyon/features/receipt/domain/services/receipt_service.dart';
import 'package:hamyon/features/receipt/presentation/pages/receipt_page.dart';
import 'package:hamyon/features/transfer/presentation/cubit/transfer_cubit.dart';
import 'package:hamyon/features/transfer/presentation/pages/transfer_page.dart';

class CardDetailsPage extends StatelessWidget {
  const CardDetailsPage({required this.cardId, super.key});

  final String cardId;

  @override
  Widget build(BuildContext context) {
    final cardsCubit = context.read<CardsCubit>();
    final cardsState = context.watch<CardsCubit>().state;
    final cards = cardsState.cards;
    final card = _findCard(cards);
    if (card == null) {
      return const Scaffold(body: Center(child: Text('Karta topilmadi')));
    }
    final transactions = context
        .watch<HistoryCubit>()
        .state
        .transactions
        .where(
          (transaction) =>
              transaction.sourceCardId == card.id ||
              transaction.destinationCardId == card.id,
        )
        .toList(growable: false);
    final scheme = Theme.of(context).colorScheme;
    final revealed = cardsState.revealedCardId == card.id;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) cardsCubit.hideSensitiveDetails(card.id);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Karta tafsilotlari')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            WalletCardTile(card: card, revealSensitive: revealed),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => cardsCubit.toggleSensitiveDetails(card.id),
                    icon: Icon(
                      revealed
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    label: Text(revealed ? 'Yashirish' : 'Ko‘rsatish'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<TransferCubit>().startWithSource(
                        card.id,
                        balance: card.balance,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const TransferPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.north_east_rounded),
                    label: const Text('O‘tkazma'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Karta raqami',
                    value: revealed
                        ? AppFormatters.cardNumber(card.number)
                        : AppFormatters.maskedCard(card.number),
                    onCopy: revealed ? () => _copy(card.number) : null,
                  ),
                  const Divider(height: 28),
                  _DetailRow(
                    label: 'Karta egasi',
                    value: card.name.toUpperCase(),
                    onCopy: revealed ? () => _copy(card.name) : null,
                  ),
                  const Divider(height: 28),
                  _DetailRow(
                    label: 'Amal qilish muddati',
                    value: revealed ? card.expiryLabel : '** / **',
                    onCopy: revealed ? () => _copy(card.expiryLabel) : null,
                  ),
                  const Divider(height: 28),
                  _DetailRow(
                    label: 'Mavjud balans',
                    value: AppFormatters.money(card.balance),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Karta amaliyotlari',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            if (transactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Bu karta bo‘yicha amaliyotlar hali yo‘q.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              )
            else
              ...transactions.map(
                (transaction) => TransactionTile(
                  transaction: transaction,
                  cardId: card.id,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ReceiptPage(
                        transaction: transaction,
                        cards: cards,
                        receiptService: context.read<ReceiptService>(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
  }

  WalletCard? _findCard(List<WalletCard> cards) {
    for (final card in cards) {
      if (card.id == cardId) return card;
    }
    return null;
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.onCopy});

  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      if (onCopy != null)
        IconButton(
          tooltip: 'Nusxalash',
          onPressed: onCopy,
          icon: const Icon(Icons.copy_rounded),
        ),
    ],
  );
}
