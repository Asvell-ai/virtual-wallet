import 'dart:io';

import 'package:hamyon/core/utils/formatters.dart';
import 'package:hamyon/features/cards/domain/entities/wallet_card.dart';
import 'package:hamyon/features/history/domain/entities/wallet_transaction.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ReceiptService {
  const ReceiptService();

  Future<File> savePdf({
    required WalletTransaction transaction,
    required List<WalletCard> cards,
  }) async {
    final source = _cardById(cards, transaction.sourceCardId);
    final destination = transaction.destinationCardId == null
        ? null
        : _cardById(cards, transaction.destinationCardId!);
    final document = pw.Document(
      title: 'Hamyon receipt ${transaction.id}',
      author: 'Hamyon',
    )..addPage(
        pw.Page(
          build: (_) => pw.Padding(
            padding: const pw.EdgeInsets.all(28),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('HAMYON',
                    style: pw.TextStyle(
                        fontSize: 25, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text(_safe('Tranzaksiya cheki')),
                pw.Divider(height: 32),
                _row('ID', transaction.id),
                _row('Sana', AppFormatters.date(transaction.createdAt)),
                _row(
                  'Turi',
                  transaction.type == TransactionType.transfer
                      ? _safe('Pul o‘tkazmasi')
                      : _safe('Xizmat to‘lovi'),
                ),
                _row('Manba karta',
                    source == null ? transaction.sourceCardId : source.name),
                if (source != null)
                  _row('Karta raqami',
                      AppFormatters.maskedCard(source.number)),
                if (source != null) _row('Karta turi', source.type.label),
                if (destination != null) ...[
                  _row('Qabul qiluvchi', destination.name),
                  _row('Qabul karta',
                      AppFormatters.maskedCard(destination.number)),
                ],
                if (transaction.serviceName != null)
                  _row('Xizmat', _safe(transaction.serviceName!)),
                if (transaction.account != null)
                  _row('Hisob', transaction.account!),
                _row('Summa', _safe(AppFormatters.money(transaction.amount))),
                _row('Komissiya',
                    _safe(AppFormatters.money(transaction.commission))),
                _row('Jami', _safe(AppFormatters.money(
                    transaction.amount + transaction.commission))),
                _row('Status', _status(transaction.status)),
                pw.Divider(height: 32),
                pw.Text(
                  _safe('Elektron chek. Haqiqiy pul operatsiyasi emas.'),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
        ),
      );

    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/receipts');
    await directory.create(recursive: true);
    final file = File('${directory.path}/receipt_${transaction.id}.pdf');
    await file.writeAsBytes(await document.save(), flush: true);
    return file;
  }

  Future<File> sharePdf({
    required WalletTransaction transaction,
    required List<WalletCard> cards,
  }) async {
    final file = await savePdf(transaction: transaction, cards: cards);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        text: _safe('Hamyon tranzaksiya cheki'),
        subject: 'Hamyon receipt',
      ),
    );
    return file;
  }

  pw.Widget _row(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 125,
              child: pw.Text(_safe(label),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Expanded(child: pw.Text(_safe(value))),
          ],
        ),
      );

  WalletCard? _cardById(List<WalletCard> cards, String id) {
    for (final card in cards) {
      if (card.id == id) return card;
    }
    return null;
  }

  String _status(TransactionStatus status) => switch (status) {
        TransactionStatus.completed => 'Muvaffaqiyatli',
        TransactionStatus.failed => 'Rad etilgan',
        TransactionStatus.tampered => 'Yaxlitlik buzilgan',
      };

  String _safe(String value) => value
      .replaceAll('‘', "'")
      .replaceAll('’', "'")
      .replaceAll('–', '-')
      .replaceAll('—', '-');
}
