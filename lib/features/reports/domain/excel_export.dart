import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';

/// How a column's values are written.
enum CellKind { text, integer, money }

/// One worksheet. Row values must match [kinds]: `String` for text, `int`
/// for integer, and `int` *centavos* for money.
@immutable
class ExcelSheetSpec {
  const ExcelSheetSpec({
    required this.name,
    required this.headers,
    required this.kinds,
    required this.rows,
    this.totals,
  });

  final String name;
  final List<String> headers;
  final List<CellKind> kinds;
  final List<List<Object?>> rows;

  /// Optional bold totals row (same shape as a data row).
  final List<Object?>? totals;
}

/// A whole workbook. Plain data only, so it can be sent to an isolate.
@immutable
class ExcelReportSpec {
  const ExcelReportSpec(this.sheets);

  final List<ExcelSheetSpec> sheets;
}

const String _pesoFormat = '"₱"#,##0.00';
const double _columnWidth = 20;
const int _maxSheetNameLength = 31;
final RegExp _invalidSheetChars = RegExp(r'[\[\]:*?/\\]');

/// Builds an .xlsx file. Top-level so it can run via `compute()` off the UI
/// thread for large ranges.
List<int> buildWorkbook(ExcelReportSpec spec) {
  final excel = Excel.createExcel();
  final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
  final header = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#D9EAD3'),
  );
  final money = CellStyle(
    numberFormat: NumFormat.custom(formatCode: _pesoFormat),
  );
  final totalText = CellStyle(bold: true);
  final totalMoney = CellStyle(
    bold: true,
    numberFormat: NumFormat.custom(formatCode: _pesoFormat),
  );

  for (var s = 0; s < spec.sheets.length; s++) {
    final sheetSpec = spec.sheets[s];
    final name = _sheetName(sheetSpec.name, s);
    if (s == 0) {
      excel.rename(defaultSheet, name);
    }
    final sheet = excel[name];

    sheet.appendRow([for (final h in sheetSpec.headers) TextCellValue(h)]);
    for (var c = 0; c < sheetSpec.headers.length; c++) {
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
              .cellStyle =
          header;
      sheet.setColumnWidth(c, _columnWidth);
    }

    void writeRow(List<Object?> row, {required bool isTotal}) {
      final rowIndex = sheet.maxRows;
      sheet.appendRow([
        for (var c = 0; c < row.length; c++) _cell(row[c], sheetSpec.kinds[c]),
      ]);
      for (var c = 0; c < row.length; c++) {
        final kind = sheetSpec.kinds[c];
        final style = kind == CellKind.money
            ? (isTotal ? totalMoney : money)
            : (isTotal ? totalText : null);
        if (style != null) {
          sheet
                  .cell(
                    CellIndex.indexByColumnRow(
                      columnIndex: c,
                      rowIndex: rowIndex,
                    ),
                  )
                  .cellStyle =
              style;
        }
      }
    }

    for (final row in sheetSpec.rows) {
      writeRow(row, isTotal: false);
    }
    final totals = sheetSpec.totals;
    if (totals != null) writeRow(totals, isTotal: true);
  }

  final bytes = excel.encode();
  if (bytes == null) throw StateError('Excel encoding failed');
  return bytes;
}

CellValue? _cell(Object? value, CellKind kind) {
  if (value == null) return null;
  return switch (kind) {
    CellKind.text => TextCellValue(value.toString()),
    CellKind.integer => IntCellValue(value is int ? value : 0),
    // Spreadsheet display only: centavos -> pesos with a ₱ number format.
    CellKind.money => DoubleCellValue((value is int ? value : 0) / 100),
  };
}

String _sheetName(String raw, int index) {
  final cleaned = raw.replaceAll(_invalidSheetChars, ' ').trim();
  final name = cleaned.isEmpty ? 'Sheet${index + 1}' : cleaned;
  return name.length > _maxSheetNameLength
      ? name.substring(0, _maxSheetNameLength)
      : name;
}
