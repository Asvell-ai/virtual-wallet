import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamyon/core/theme/app_theme.dart';
import 'package:hamyon/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:hamyon/features/auth/presentation/cubit/auth_state.dart';
import 'package:hamyon/features/auth/presentation/pages/pin_page.dart';
import 'package:hamyon/features/cards/presentation/cubit/cards_cubit.dart';
import 'package:hamyon/features/home/presentation/pages/home_shell.dart';
import 'package:hamyon/features/payments/presentation/cubit/payment_cubit.dart';
import 'package:hamyon/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:hamyon/features/settings/presentation/cubit/settings_state.dart';
import 'package:hamyon/features/transfer/presentation/cubit/transfer_cubit.dart';

class HamyonApp extends StatefulWidget {
  const HamyonApp({super.key});

  @override
  State<HamyonApp> createState() => _HamyonAppState();
}

class _HamyonAppState extends State<HamyonApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final authCubit = context.read<AuthCubit>();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (!authCubit.isBiometricOperationInProgress) {
        authCubit.lock();
      }
    } else if (state == AppLifecycleState.resumed &&
        !authCubit.isBiometricOperationInProgress) {
      unawaited(authCubit.unlockWithBiometrics(automatic: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<AuthCubit, AuthState>(
    listenWhen: (previous, current) => previous.status != current.status,
    listener: (context, state) {
      if (state.status == AuthStatus.unlocked) {
        context.read<SettingsCubit>().load();
      } else {
        context.read<TransferCubit>().clearSensitiveData();
        context.read<PaymentCubit>().clearSensitiveData();
        context.read<CardsCubit>().clearSensitiveData();
        _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    },
    child: BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) => MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Hamyon',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: settings.themeMode,
        builder: (context, child) => Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => context.read<AuthCubit>().registerActivity(),
          child: child,
        ),
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) => switch (state.status) {
            AuthStatus.unlocked => const HomeShell(),
            AuthStatus.initial => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            _ => const PinPage(),
          },
        ),
      ),
    ),
  );
}
