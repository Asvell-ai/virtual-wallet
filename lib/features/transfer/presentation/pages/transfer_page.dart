import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamyon/core/utils/formatters.dart';
import 'package:hamyon/core/widgets/fade_slide_in.dart';
import 'package:hamyon/core/widgets/primary_button.dart';
import 'package:hamyon/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:hamyon/features/cards/presentation/cubit/cards_cubit.dart';
import 'package:hamyon/features/cards/presentation/cubit/cards_state.dart';
import 'package:hamyon/features/history/presentation/cubit/history_cubit.dart';
import 'package:hamyon/features/receipt/domain/services/receipt_service.dart';
import 'package:hamyon/features/receipt/presentation/pages/receipt_page.dart';
import 'package:hamyon/features/transfer/presentation/cubit/transfer_cubit.dart';
import 'package:hamyon/features/transfer/presentation/cubit/transfer_state.dart';

class TransferPage extends StatelessWidget {
  const TransferPage({super.key});

  @override
  Widget build(BuildContext context) => BlocConsumer<TransferCubit, TransferState>(
        listener: (context, state) async {
          if (state.requiresLock) {
            await context.read<AuthCubit>().enforceGuardLock();
            return;
          }
          if (state.status == TransferStatus.success &&
              state.transaction != null) {
            await Future.wait([
              context.read<CardsCubit>().load(),
              context.read<HistoryCubit>().load(),
            ]);
            if (!context.mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ReceiptPage(
                  transaction: state.transaction!,
                  cards: context.read<CardsCubit>().state.cards,
                  receiptService: context.read<ReceiptService>(),
                ),
              ),
            );
          } else if (state.status == TransferStatus.failure &&
              state.message != null) {
            await context.read<HistoryCubit>().load();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          final cardState = context.watch<CardsCubit>().state;
          return Scaffold(
            appBar: AppBar(title: const Text('Pul o‘tkazish')),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                FadeSlideIn(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0A1D45), Color(0xFF246BFE)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: const Icon(Icons.swap_horiz_rounded,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Xavfsiz o‘tkazma',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kartalar o‘rtasida bir zumda • 0.5%',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.68),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (cardState.cards.length < 2)
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
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: state.sourceCardId.isEmpty ? null : state.sourceCardId,
                  decoration: const InputDecoration(
                    labelText: 'Qaysi kartadan',
                    prefixIcon: Icon(Icons.credit_card_rounded),
                  ),
                  items: cardState.cards
                      .map((card) => DropdownMenuItem(
                            value: card.id,
                            child: Text(
                              '${card.name} — ${AppFormatters.money(card.balance)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: context.read<TransferCubit>().sourceChanged,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: state.destinationCardId.isEmpty
                      ? null
                      : state.destinationCardId,
                  decoration: const InputDecoration(
                    labelText: 'Qaysi kartaga',
                    prefixIcon: Icon(Icons.move_down_rounded),
                  ),
                  items: cardState.cards
                      .where((card) => card.id != state.sourceCardId)
                      .map((card) => DropdownMenuItem(
                            value: card.id,
                            child: Text(card.name),
                          ))
                      .toList(),
                  onChanged: context.read<TransferCubit>().destinationChanged,
                ),
                const SizedBox(height: 12),
                TextField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: context.read<TransferCubit>().amountChanged,
                  decoration: const InputDecoration(
                    labelText: 'O‘tkazma summasi',
                    suffixText: 'so‘m',
                    prefixIcon: Icon(Icons.payments_outlined),
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
                          const Text('Jami yechiladi',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Text(
                              AppFormatters.money(state.total),
                              key: ValueKey(state.total),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  onChanged: context.read<TransferCubit>().pinChanged,
                  decoration: const InputDecoration(
                    labelText: 'Tasdiqlash PIN-kodi',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
                if (state.message != null &&
                    state.status == TransferStatus.failure)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      state.message!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'O‘tkazmani tasdiqlash',
                  loading: state.status == TransferStatus.submitting,
                  icon: Icons.swap_horiz_rounded,
                  onPressed: cardState.cards.length < 2
                      ? null
                      : context.read<TransferCubit>().submit,
                ),
              ],
            ),
          );
        },
      );
}
