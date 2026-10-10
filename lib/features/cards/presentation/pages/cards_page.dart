import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamyon/core/theme/app_theme.dart';
import 'package:hamyon/core/utils/formatters.dart';
import 'package:hamyon/core/widgets/fade_slide_in.dart';
import 'package:hamyon/core/widgets/primary_button.dart';
import 'package:hamyon/features/cards/presentation/cubit/cards_cubit.dart';
import 'package:hamyon/features/cards/presentation/cubit/cards_state.dart';
import 'package:hamyon/features/cards/presentation/formatters/card_number_input_formatter.dart';
import 'package:hamyon/features/cards/presentation/widgets/wallet_card_tile.dart';
import 'package:hamyon/features/history/presentation/cubit/history_cubit.dart';
import 'package:hamyon/features/history/presentation/cubit/history_state.dart';
import 'package:hamyon/features/history/presentation/widgets/transaction_tile.dart';
import 'package:hamyon/features/home/presentation/cubit/home_cubit.dart';
import 'package:hamyon/features/receipt/domain/services/receipt_service.dart';
import 'package:hamyon/features/receipt/presentation/pages/receipt_page.dart';

class CardsPage extends StatelessWidget {
  const CardsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocConsumer<CardsCubit, CardsState>(
        listener: (context, state) {
          if (state.message != null && state.status == CardsStatus.failure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          final history = context.watch<HistoryCubit>().state;
          final recent = history.transactions.take(3).toList();
          final scheme = Theme.of(context).colorScheme;
          return Scaffold(
            body: SafeArea(
              bottom: false,
              child: state.status == CardsStatus.loading && state.cards.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () async {
                        await Future.wait([
                          context.read<CardsCubit>().load(),
                          context.read<HistoryCubit>().load(),
                        ]);
                      },
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                            sliver: SliverList.list(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: scheme.primary,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Xayrli kun 👋',
                                            style: TextStyle(
                                              color: scheme.onSurfaceVariant,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            'Hamyon',
                                            style: TextStyle(
                                              fontSize: 21,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton.filledTonal(
                                      tooltip: 'Sozlamalar',
                                      onPressed: () => context
                                          .read<HomeCubit>()
                                          .pageChanged(4),
                                      icon: const Icon(Icons.tune_rounded),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                FadeSlideIn(
                                  child: Container(
                                    padding: const EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                      color: scheme.brightness == Brightness.light
                                          ? AppTheme.navy
                                          : const Color(0xFF111C31),
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Umumiy balans',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.65),
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              TweenAnimationBuilder<double>(
                                                tween: Tween(
                                                  begin: 0,
                                                  end: state.totalBalance
                                                      .toDouble(),
                                                ),
                                                duration: const Duration(
                                                    milliseconds: 700),
                                                curve: Curves.easeOutCubic,
                                                builder: (context, value, _) =>
                                                    Text(
                                                  AppFormatters.money(
                                                      value.round()),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 27,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: -0.8,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.10),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.show_chart_rounded,
                                            color: AppTheme.mint,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Row(
                                  children: [
                                    Text(
                                      'Kartalarim',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(fontWeight: FontWeight.w900),
                                    ),
                                    const Spacer(),
                                    TextButton.icon(
                                      onPressed: () => showModalBottomSheet<void>(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (_) => BlocProvider.value(
                                          value: context.read<CardsCubit>(),
                                          child: const _AddCardSheet(),
                                        ),
                                      ),
                                      icon: const Icon(Icons.add_rounded, size: 19),
                                      label: const Text('Qo‘shish'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                          if (state.cards.isEmpty)
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              sliver: SliverToBoxAdapter(
                                child: FadeSlideIn(
                                  child: Container(
                                    padding: const EdgeInsets.all(28),
                                    decoration: BoxDecoration(
                                      color: scheme.surface,
                                      borderRadius: BorderRadius.circular(26),
                                      border:
                                          Border.all(color: scheme.outlineVariant),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            color: scheme.primaryContainer,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.add_card_rounded,
                                              color: scheme.primary, size: 30),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Birinchi UZCARD kartangizni yarating',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '16 xonali virtual karta bilan o‘tkazma va to‘lovlarni boshlang.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: scheme.onSurfaceVariant),
                                        ),
                                        const SizedBox(height: 20),
                                        FilledButton.icon(
                                          onPressed: () =>
                                              showModalBottomSheet<void>(
                                            context: context,
                                            isScrollControlled: true,
                                            builder: (_) => BlocProvider.value(
                                              value:
                                                  context.read<CardsCubit>(),
                                              child: const _AddCardSheet(),
                                            ),
                                          ),
                                          icon: const Icon(Icons.add_rounded),
                                          label: const Text('Karta yaratish'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else ...[
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: 230,
                                child: PageView.builder(
                                  itemCount: state.cards.length,
                                  onPageChanged: context
                                      .read<CardsCubit>()
                                      .selectedCardChanged,
                                  itemBuilder: (context, index) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: WalletCardTile(
                                        card: state.cards[index]),
                                  ),
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    state.cards.length,
                                    (index) => AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      curve: Curves.easeOut,
                                      width: index == state.selectedCardIndex
                                          ? 22
                                          : 7,
                                      height: 7,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      decoration: BoxDecoration(
                                        color: index == state.selectedCardIndex
                                            ? scheme.primary
                                            : scheme.outlineVariant,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                            sliver: SliverList.list(
                              children: [
                                FadeSlideIn(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _QuickAction(
                                          icon: Icons.north_east_rounded,
                                          label: 'O‘tkazma',
                                          color: scheme.primary,
                                          onTap: () => context
                                              .read<HomeCubit>()
                                              .pageChanged(1),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _QuickAction(
                                          icon: Icons.receipt_long_rounded,
                                          label: 'To‘lov',
                                          color: AppTheme.mint,
                                          onTap: () => context
                                              .read<HomeCubit>()
                                              .pageChanged(2),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _QuickAction(
                                          icon: Icons.add_card_rounded,
                                          label: 'Karta',
                                          color: const Color(0xFFFF9F43),
                                          onTap: () =>
                                              showModalBottomSheet<void>(
                                            context: context,
                                            isScrollControlled: true,
                                            builder: (_) => BlocProvider.value(
                                              value:
                                                  context.read<CardsCubit>(),
                                              child: const _AddCardSheet(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 30),
                                Row(
                                  children: [
                                    Text(
                                      'So‘nggi amallar',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(fontWeight: FontWeight.w900),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () => context
                                          .read<HomeCubit>()
                                          .pageChanged(3),
                                      child: const Text('Barchasi'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (history.status == HistoryStatus.loading &&
                                    recent.isEmpty)
                                  const Center(
                                      child: CircularProgressIndicator())
                                else if (recent.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                      color: scheme.surface,
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.history_rounded,
                                            color: scheme.onSurfaceVariant),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Hozircha tranzaksiyalar yo‘q',
                                          style: TextStyle(
                                              color: scheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ...recent.map(
                                    (transaction) => TransactionTile(
                                      transaction: transaction,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) => ReceiptPage(
                                            transaction: transaction,
                                            cards: state.cards,
                                            receiptService: context
                                                .read<ReceiptService>(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 110),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        },
      );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: 9),
                Text(label,
                    maxLines: 1,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );
}

class _AddCardSheet extends StatelessWidget {
  const _AddCardSheet();

  @override
  Widget build(BuildContext context) => BlocBuilder<CardsCubit, CardsState>(
        builder: (context, state) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Yangi virtual karta',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ma’lumotlarni kiriting va UZCARD kartangizni yarating.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.credit_card_rounded,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Karta turi', style: TextStyle(fontSize: 12)),
                            SizedBox(height: 2),
                            Text('UZCARD',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 16)),
                          ],
                        ),
                      ),
                      const Icon(Icons.verified_rounded, color: AppTheme.mint),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  textCapitalization: TextCapitalization.words,
                  onChanged: context.read<CardsCubit>().nameChanged,
                  decoration: const InputDecoration(
                    labelText: 'Karta nomi',
                    hintText: 'Masalan: Asosiy karta',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [CardNumberInputFormatter()],
                  onChanged: context.read<CardsCubit>().numberChanged,
                  decoration: const InputDecoration(
                    labelText: '16 xonali karta raqami',
                    hintText: '8600 1234 5678 9012',
                    prefixIcon: Icon(Icons.credit_card_rounded),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: context.read<CardsCubit>().balanceChanged,
                  decoration: const InputDecoration(
                    labelText: 'Boshlang‘ich balans',
                    suffixText: 'so‘m',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                ),
                if (state.message != null && state.status == CardsStatus.failure)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      state.message!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: 'UZCARD kartani yaratish',
                  loading: state.status == CardsStatus.submitting,
                  icon: Icons.add_card_rounded,
                  onPressed: () async {
                    final success = await context.read<CardsCubit>().submit();
                    if (success && context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      );
}
