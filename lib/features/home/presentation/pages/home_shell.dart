import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamyon/features/cards/presentation/cubit/cards_cubit.dart';
import 'package:hamyon/features/cards/presentation/pages/cards_page.dart';
import 'package:hamyon/features/history/presentation/cubit/history_cubit.dart';
import 'package:hamyon/features/history/presentation/pages/history_page.dart';
import 'package:hamyon/features/home/presentation/cubit/home_cubit.dart';
import 'package:hamyon/features/payments/presentation/pages/payments_page.dart';
import 'package:hamyon/features/settings/presentation/pages/settings_page.dart';
import 'package:hamyon/features/transfer/presentation/pages/transfer_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _pages = [
    CardsPage(),
    TransferPage(),
    PaymentsPage(),
    HistoryPage(),
    SettingsPage(),
  ];
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: context.read<HomeCubit>().state);
    context.read<CardsCubit>().load();
    context.read<HistoryCubit>().load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<HomeCubit, int>(
        listener: (context, index) => _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        ),
        builder: (context, index) => Scaffold(
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: context.read<HomeCubit>().pageChanged,
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Asosiy'),
              NavigationDestination(
                  icon: Icon(Icons.swap_horiz_outlined),
                  selectedIcon: Icon(Icons.swap_horiz_rounded),
                  label: 'O‘tkazma'),
              NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: 'To‘lov'),
              NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history_rounded),
                  label: 'Tarix'),
              NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: 'Sozlama'),
            ],
          ),
        ),
      );
}
