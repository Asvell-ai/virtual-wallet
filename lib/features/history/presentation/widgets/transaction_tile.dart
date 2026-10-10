import 'package:flutter/material.dart';
import 'package:hamyon/core/theme/app_theme.dart';
import 'package:hamyon/core/utils/formatters.dart';
import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({required this.transaction, required this.onTap, super.key});

  final WalletTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = transaction.status == TransactionStatus.completed;
    final tampered = transaction.status == TransactionStatus.tampered;
    final isTransfer = transaction.type == TransactionType.transfer;
    final accent = tampered
        ? Theme.of(context).colorScheme.error
        : isTransfer
            ? Theme.of(context).colorScheme.primary
            : AppTheme.mint;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.11),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    tampered
                        ? Icons.gpp_bad_rounded
                        : isTransfer
                            ? Icons.north_east_rounded
                            : Icons.receipt_long_rounded,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTransfer
                            ? 'Pul o‘tkazmasi'
                            : transaction.serviceName ?? 'To‘lov',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        AppFormatters.date(transaction.createdAt),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '-${AppFormatters.money(transaction.amount + transaction.commission)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (completed ? AppTheme.mint : accent)
                            .withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tampered
                            ? 'O‘zgargan'
                            : completed
                                ? 'Bajarildi'
                                : 'Rad etildi',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: completed ? const Color(0xFF119B7B) : accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
