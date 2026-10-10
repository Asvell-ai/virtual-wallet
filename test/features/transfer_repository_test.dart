import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hamyon/core/error/failures.dart';
import 'package:hamyon/core/security/secure_vault.dart';
import 'package:hamyon/core/utils/money_policy.dart';
import 'package:hamyon/features/cards/data/repositories/cards_repository_impl.dart';
import 'package:hamyon/features/history/data/repositories/history_repository_impl.dart';
import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';
import 'package:hamyon/features/transfer/data/repositories/transfer_repository_impl.dart';

void main() {
  late Directory directory;
  late SecureVault vault;
  late CardsRepositoryImpl cardsRepository;
  late TransferRepositoryImpl transferRepository;
  late HistoryRepositoryImpl historyRepository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('hamyon_transfer_test_');
    vault = SecureVault.forDirectory(directory);
    await vault.createNew('1234');
    cardsRepository = CardsRepositoryImpl(vault);
    transferRepository = TransferRepositoryImpl(vault);
    historyRepository = HistoryRepositoryImpl(vault);
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('transfer balanslarni va 0.5% komissiyani to‘g‘ri hisoblaydi', () async {
    final first = await cardsRepository.addCard(
      name: 'Birinchi',
      number: '8600000000000001',
      initialBalance: 200000,
    );
    final second = await cardsRepository.addCard(
      name: 'Ikkinchi',
      number: '8600000000000002',
      initialBalance: 10000,
    );
    final commission = MoneyPolicy.commissionFor(100000);

    final transaction = await transferRepository.transfer(
      sourceCardId: first.id,
      destinationCardId: second.id,
      amount: 100000,
      commission: commission,
    );

    final cards = await cardsRepository.getCards();
    expect(cards.firstWhere((card) => card.id == first.id).balance, 99500);
    expect(cards.firstWhere((card) => card.id == second.id).balance, 110000);
    expect(transaction.status, TransactionStatus.completed);
    expect(transaction.commission, 500);

    vault.lock();
    final reopened = SecureVault.forDirectory(directory);
    expect(await reopened.unlock('1234'), isTrue);
    final persistedCards = await CardsRepositoryImpl(reopened).getCards();
    expect(persistedCards.firstWhere((card) => card.id == first.id).balance, 99500);
  });

  test('mablag‘ yetmasa rad etadi, tarixga yozadi va balansni o‘zgartirmaydi',
      () async {
    final first = await cardsRepository.addCard(
      name: 'Birinchi',
      number: '8600000000000011',
      initialBalance: 1000,
    );
    final second = await cardsRepository.addCard(
      name: 'Ikkinchi',
      number: '8600000000000012',
      initialBalance: 0,
    );

    await expectLater(
      transferRepository.transfer(
        sourceCardId: first.id,
        destinationCardId: second.id,
        amount: 1000,
        commission: MoneyPolicy.commissionFor(1000),
      ),
      throwsA(isA<InsufficientBalanceFailure>()),
    );

    final cards = await cardsRepository.getCards();
    expect(cards.firstWhere((card) => card.id == first.id).balance, 1000);
    expect(cards.firstWhere((card) => card.id == second.id).balance, 0);
    final history = await historyRepository.getTransactions();
    expect(history, hasLength(1));
    expect(history.single.status, TransactionStatus.failed);
    expect(history.single.integrityValid, isTrue);
  });

  test('tranzaksiya o‘zgartirilsa HMAC buni aniqlaydi', () async {
    final first = await cardsRepository.addCard(
      name: 'Birinchi',
      number: '8600000000000021',
      initialBalance: 100000,
    );
    final second = await cardsRepository.addCard(
      name: 'Ikkinchi',
      number: '8600000000000022',
      initialBalance: 0,
    );
    await transferRepository.transfer(
      sourceCardId: first.id,
      destinationCardId: second.id,
      amount: 10000,
      commission: MoneyPolicy.commissionFor(10000),
    );

    await vault.mutate((database) {
      final rows = List<Map<String, dynamic>>.from(
        database['transactions']! as List,
      );
      rows.single['amount'] = 999999;
      database['transactions'] = rows;
    });

    final history = await historyRepository.getTransactions();
    expect(history.single.integrityValid, isFalse);
    expect(history.single.status, TransactionStatus.tampered);
  });
}
