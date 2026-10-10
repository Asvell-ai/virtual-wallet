import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hamyon/app.dart';
import 'package:hamyon/core/security/secure_vault.dart';
import 'package:hamyon/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:hamyon/features/auth/domain/repositories/auth_repository.dart';
import 'package:hamyon/features/auth/domain/usecases/auth_usecases.dart';
import 'package:hamyon/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:hamyon/features/cards/data/repositories/cards_repository_impl.dart';
import 'package:hamyon/features/cards/domain/repositories/cards_repository.dart';
import 'package:hamyon/features/cards/domain/usecases/card_usecases.dart';
import 'package:hamyon/features/cards/presentation/cubit/cards_cubit.dart';
import 'package:hamyon/features/history/data/repositories/history_repository_impl.dart';
import 'package:hamyon/features/history/domain/repositories/history_repository.dart';
import 'package:hamyon/features/history/domain/usecases/get_transactions.dart';
import 'package:hamyon/features/history/presentation/cubit/history_cubit.dart';
import 'package:hamyon/features/home/presentation/cubit/home_cubit.dart';
import 'package:hamyon/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:hamyon/features/payments/domain/repositories/payment_repository.dart';
import 'package:hamyon/features/payments/domain/usecases/make_payment.dart';
import 'package:hamyon/features/payments/presentation/cubit/payment_cubit.dart';
import 'package:hamyon/features/receipt/domain/services/receipt_service.dart';
import 'package:hamyon/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:hamyon/features/settings/domain/repositories/settings_repository.dart';
import 'package:hamyon/features/settings/domain/usecases/settings_usecases.dart';
import 'package:hamyon/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:hamyon/features/transfer/data/repositories/transfer_repository_impl.dart';
import 'package:hamyon/features/transfer/domain/repositories/transfer_repository.dart';
import 'package:hamyon/features/transfer/domain/usecases/transfer_funds.dart';
import 'package:hamyon/features/transfer/presentation/cubit/transfer_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  final vault = await SecureVault.create();
  const secureStorage = FlutterSecureStorage();
  final authRepository = AuthRepositoryImpl(vault, secureStorage);
  final cardsRepository = CardsRepositoryImpl(vault);
  final historyRepository = HistoryRepositoryImpl(vault);
  final transferRepository = TransferRepositoryImpl(vault);
  final paymentRepository = PaymentRepositoryImpl(vault);
  final settingsRepository = SettingsRepositoryImpl(vault, secureStorage);
  final verifyPin = VerifyPin(authRepository);
  final settingsCubit = SettingsCubit(
    getThemeMode: GetThemeMode(settingsRepository),
    saveThemeMode: SaveThemeMode(settingsRepository),
  );
  await settingsCubit.load();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<CardsRepository>.value(value: cardsRepository),
        RepositoryProvider<HistoryRepository>.value(value: historyRepository),
        RepositoryProvider<TransferRepository>.value(value: transferRepository),
        RepositoryProvider<PaymentRepository>.value(value: paymentRepository),
        RepositoryProvider<SettingsRepository>.value(value: settingsRepository),
        RepositoryProvider<ReceiptService>(
          create: (_) => const ReceiptService(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthCubit(
              repository: authRepository,
              createPin: CreatePin(authRepository),
              unlockWallet: UnlockWallet(authRepository),
            )..initialize(),
          ),
          BlocProvider(
            create: (_) => CardsCubit(
              getCards: GetCards(cardsRepository),
              addCard: AddCard(cardsRepository),
            ),
          ),
          BlocProvider(
            create: (_) => HistoryCubit(GetTransactions(historyRepository)),
          ),
          BlocProvider(
            create: (_) =>
                TransferCubit(TransferFunds(transferRepository, verifyPin)),
          ),
          BlocProvider(
            create: (_) =>
                PaymentCubit(MakePayment(paymentRepository, verifyPin)),
          ),
          BlocProvider(create: (_) => HomeCubit()),
          BlocProvider(create: (_) => settingsCubit),
        ],
        child: const HamyonApp(),
      ),
    ),
  );
}
