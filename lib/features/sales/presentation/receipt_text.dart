import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/utils/money.dart';
import 'package:tindascan/shared/models/sale.dart';

/// Plain-text receipt for sharing (SMS, Messenger, etc.).
String buildReceiptText({
  required Sale sale,
  required String storeName,
  required String dateText,
  required AppLocalizations l10n,
}) {
  final buffer = StringBuffer()
    ..writeln(storeName)
    ..writeln(l10n.receiptNo(sale.receiptNo))
    ..writeln(dateText)
    ..writeln('--------------------------------');
  for (final item in sale.items) {
    buffer
      ..writeln(item.name)
      ..writeln(
        '  ${item.qty} × ${Money.format(item.unitPriceCentavos)}'
        ' = ${Money.format(item.subtotalCentavos)}',
      );
  }
  buffer
    ..writeln('--------------------------------')
    ..writeln('${l10n.sellTotal}: ${Money.format(sale.totalCentavos)}')
    ..writeln(
      '${l10n.receiptCash}: ${Money.format(sale.amountTenderedCentavos)}',
    )
    ..writeln('${l10n.paymentChange}: ${Money.format(sale.changeCentavos)}')
    ..writeln(l10n.receiptCashier(sale.cashierName));
  if (sale.offline) buffer.writeln(l10n.receiptOffline);
  buffer.write(l10n.receiptThanks);
  return buffer.toString();
}
