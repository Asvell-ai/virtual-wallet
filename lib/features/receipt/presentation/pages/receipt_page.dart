import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamyon/core/utils/formatters.dart';
import 'package:hamyon/features/cards/domain/entities/wallet_card.dart';
import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';
import 'package:hamyon/features/qr/domain/qr_payload.dart';
import 'package:hamyon/features/qr/presentation/widgets/qr_code_sheet.dart';
import 'package:hamyon/features/receipt/domain/services/receipt_service.dart';
import 'package:hamyon/features/receipt/presentation/cubit/receipt_cubit.dart';
import 'package:hamyon/features/receipt/presentation/cubit/receipt_state.dart';

class ReceiptPage extends StatelessWidget {
  const ReceiptPage({
    required this.transaction,
    required this.cards,
    required this.receiptService,
    super.key,
  });

  final WalletTransaction transaction;
  final List<WalletCard> cards;
  final ReceiptService receiptService;

  @override
  Widget build(BuildContext context) {
    final transaction = this.transaction;
    final successful = transaction.status == TransactionStatus.completed;
    return BlocProvider(
      create: (_) => ReceiptCubit(receiptService),
      child: BlocBuilder<ReceiptCubit, ReceiptState>(
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Tranzaksiya cheki')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: successful
                          ? Colors.green.withOpacity(0.12)
                          : Theme.of(context).colorScheme.errorContainer,
                      child: Icon(
                        successful ? Icons.check_rounded : Icons.close_rounded,
                        size: 40,
                        color: successful
                            ? Colors.green
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      successful ? 'Muvaffaqiyatli' : 'Rad etilgan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppFormatters.money(transaction.amount),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Divider(height: 36),
                    _ReceiptRow(
                      label: 'Sana',
                      value: AppFormatters.date(transaction.createdAt),
                    ),
                    _ReceiptRow(
                      label: 'Turi',
                      value: transaction.type == TransactionType.transfer
                          ? 'Pul o‘tkazmasi'
                          : transaction.serviceName ?? 'To‘lov',
                    ),
                    if (transaction.account != null)
                      _ReceiptRow(label: 'Hisob', value: transaction.account!),
                    _ReceiptRow(
                      label: 'Komissiya',
                      value: AppFormatters.money(transaction.commission),
                    ),
                    _ReceiptRow(label: 'Tranzaksiya ID', value: transaction.id),
                    if (!transaction.integrityValid)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'Diqqat: HMAC tekshiruvi muvaffaqiyatsiz tugadi.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => QrCodeSheet.show(
                  context,
                  title: 'Chek QR-kodi',
                  subtitle: 'Tranzaksiya: ${transaction.id}',
                  payload: QrPayload.receipt(transaction),
                ),
                icon: const Icon(Icons.qr_code_2_rounded),
                label: const Text('QR-kodni ko‘rsatish'),
              ),
              const SizedBox(height: 10),

              OutlinedButton.icon(
                onPressed: state.status == ReceiptStatus.working
                    ? null
                    : () => context.read<ReceiptCubit>().share(
                        transaction: transaction,
                        cards: cards,
                      ),
                icon: const Icon(Icons.share_rounded),
                label: const Text('Ulashish'),
              ),

              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: state.status == ReceiptStatus.working
                    ? null
                    : () => context.read<ReceiptCubit>().save(
                        transaction: transaction,
                        cards: cards,
                      ),
                icon: const Icon(Icons.download_rounded),
                label: const Text('PDF qilib saqlash'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
