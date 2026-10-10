import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamyon/core/widgets/fade_slide_in.dart';
import 'package:hamyon/features/cards/presentation/cubit/cards_cubit.dart';
import 'package:hamyon/features/cards/presentation/cubit/cards_state.dart';
import 'package:hamyon/features/history/presentation/cubit/history_cubit.dart';
import 'package:hamyon/features/history/presentation/cubit/history_state.dart';
import 'package:hamyon/features/history/presentation/widgets/transaction_tile.dart';
import 'package:hamyon/features/receipt/domain/services/receipt_service.dart';
import 'package:hamyon/features/receipt/presentation/pages/receipt_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          final cards = context.watch<CardsCubit>().state.cards;
          return Scaffold(
            appBar: AppBar(title: const Text('Tranzaksiyalar tarixi')),
            body: Column(
              children: [
              
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: HistoryFilter.values
                        .map(
                          (filter) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              selected: state.filter == filter,
                              onSelected: (_) => context
                                  .read<HistoryCubit>()
                                  .filterChanged(filter),
                              label: Text(switch (filter) {
                                HistoryFilter.all => 'Barchasi',
                                HistoryFilter.transfers => 'O‘tkazmalar',
                                HistoryFilter.payments => 'To‘lovlar',
                                HistoryFilter.completed => 'Bajarilgan',
                                HistoryFilter.failed => 'Rad etilgan',
                              }),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Expanded(
                  child: state.status == HistoryStatus.loading &&
                          state.transactions.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : state.filtered.isEmpty
                          ? const Center(child: Text('Tranzaksiyalar topilmadi'))
                          : RefreshIndicator(
                              onRefresh: context.read<HistoryCubit>().load,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 100),
                                itemCount: state.filtered.length,
                                itemBuilder: (context, index) {
                                  final transaction = state.filtered[index];
                                  return TransactionTile(
                                    transaction: transaction,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => ReceiptPage(
                                          transaction: transaction,
                                          cards: cards,
                                          receiptService:
                                              context.read<ReceiptService>(),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          );
        },
      );
}
