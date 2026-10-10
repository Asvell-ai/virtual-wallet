import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamyon/core/utils/formatters.dart';
import 'package:hamyon/core/widgets/fade_slide_in.dart';
import 'package:hamyon/core/widgets/primary_button.dart';
import 'package:hamyon/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:hamyon/features/cards/presentation/cubit/cards_cubit.dart';
import 'package:hamyon/features/history/presentation/cubit/history_cubit.dart';
import 'package:hamyon/features/payments/domain/entities/payment_service.dart';
import 'package:hamyon/features/payments/presentation/cubit/payment_cubit.dart';
import 'package:hamyon/features/payments/presentation/cubit/payment_state.dart';
import 'package:hamyon/features/receipt/domain/services/receipt_service.dart';
import 'package:hamyon/features/receipt/presentation/pages/receipt_page.dart';

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocConsumer<PaymentCubit, PaymentState>(
        listener: (context, state) async {
          if (state.requiresLock) {
            await context.read<AuthCubit>().enforceGuardLock();
            return;
          }
          if (state.status == PaymentStatus.success &&
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
          } else if (state.status == PaymentStatus.failure &&
              state.message != null) {
            await context.read<HistoryCubit>().load();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          final cards = context.watch<CardsCubit>().state.cards;
          return Scaffold(
            appBar: AppBar(title: const Text('Xizmatlar uchun to‘lov')),
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
                        colors: [Color(0xFF173B57), Color(0xFF26C6A0)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: const Icon(Icons.bolt_rounded,
                              color: Colors.white, size: 29),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tezkor to‘lovlar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mobil, internet va kommunal xizmatlar',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.72),
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: PaymentService.values
                      .map(
                        (service) => ChoiceChip(
                          selected: state.service == service,
                          onSelected: (_) => context
                              .read<PaymentCubit>()
                              .serviceChanged(service),
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
                DropdownButtonFormField<String>(
                  value: state.sourceCardId.isEmpty ? null : state.sourceCardId,
                  decoration: const InputDecoration(
                    labelText: 'To‘lov kartasi',
                    prefixIcon: Icon(Icons.credit_card_rounded),
                  ),
                  items: cards
                      .map((card) => DropdownMenuItem(
                            value: card.id,
                            child: Text(
                              '${card.name} — ${AppFormatters.money(card.balance)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: context.read<PaymentCubit>().sourceChanged,
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
                  decoration: const InputDecoration(
                    labelText: 'To‘lov summasi',
                    suffixText: 'so‘m',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  onChanged: context.read<PaymentCubit>().pinChanged,
                  decoration: const InputDecoration(
                    labelText: 'Tasdiqlash PIN-kodi',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
                if (state.message != null &&
                    state.status == PaymentStatus.failure)
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
                  label: 'To‘lovni tasdiqlash',
                  loading: state.status == PaymentStatus.submitting,
                  icon: Icons.receipt_long_rounded,
                  onPressed:
                      cards.isEmpty ? null : context.read<PaymentCubit>().submit,
                ),
              ],
            ),
          );
        },
      );
}
