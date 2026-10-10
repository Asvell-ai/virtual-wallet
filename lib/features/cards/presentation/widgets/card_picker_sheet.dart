import 'package:flutter/material.dart';
import 'package:hamyon/core/utils/formatters.dart';
import 'package:hamyon/features/cards/domain/entities/wallet_card.dart';

const _addCardAction = '__add_card__';

Future<WalletCard?> showWalletCardPicker({
  required BuildContext context,
  required List<WalletCard> cards,
  required String title,
  required String emptyMessage,
  required Future<WalletCard?> Function() onAddCard,
  String selectedCardId = '',
  String excludedCardId = '',
}) async {
  final availableCards = cards
      .where((card) => card.id != excludedCardId)
      .toList(growable: false);
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _WalletCardPickerSheet(
      cards: availableCards,
      selectedCardId: selectedCardId,
      title: title,
      emptyMessage: emptyMessage,
    ),
  );
  if (!context.mounted || result == null) return null;
  if (result == _addCardAction) return onAddCard();
  for (final card in availableCards) {
    if (card.id == result) return card;
  }
  return null;
}

class _WalletCardPickerSheet extends StatelessWidget {
  const _WalletCardPickerSheet({
    required this.cards,
    required this.selectedCardId,
    required this.title,
    required this.emptyMessage,
  });

  final List<WalletCard> cards;
  final String selectedCardId;
  final String title;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              cards.isEmpty ? emptyMessage : 'Kartani tanlang.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            if (cards.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_card_rounded,
                      color: scheme.primary,
                      size: 36,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      emptyMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(context, _addCardAction),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Karta qo‘shish'),
                    ),
                  ],
                ),
              )
            else ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: cards.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    final selected = card.id == selectedCardId;
                    return Material(
                      color: selected
                          ? scheme.primaryContainer
                          : scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                      child: ListTile(
                        onTap: () => Navigator.pop(context, card.id),
                        minTileHeight: 72,
                        leading: CircleAvatar(
                          backgroundColor: Color(card.colorValue),
                          foregroundColor: Colors.white,
                          child: const Icon(Icons.credit_card_rounded),
                        ),
                        title: Text(
                          card.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${AppFormatters.maskedCard(card.number)} • ${AppFormatters.money(card.balance)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: selected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: scheme.primary,
                              )
                            : const Icon(Icons.chevron_right_rounded),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, _addCardAction),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Yangi karta qo‘shish'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
