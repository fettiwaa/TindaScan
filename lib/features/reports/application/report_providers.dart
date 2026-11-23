import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/errors/app_logger.dart';
import 'package:tindascan/core/errors/failure.dart';
import 'package:tindascan/core/utils/manila_time.dart';
import 'package:tindascan/features/reports/domain/excel_export.dart';
import 'package:tindascan/features/reports/domain/report_filter.dart';
import 'package:tindascan/shared/models/daily_stats.dart';
import 'package:tindascan/shared/models/product.dart';
import 'package:tindascan/shared/models/stock_movement.dart';
import 'package:tindascan/shared/providers/repository_providers.dart';

/// The selected report and range.
class ReportFilterNotifier extends Notifier<ReportFilter> {
  @override
  ReportFilter build() => ReportFilter.initial(ref.read(clockProvider)());

  // ignore: use_setters_to_change_properties
  void update(ReportFilter filter) => state = filter;
}

final reportFilterProvider =
    NotifierProvider.autoDispose<ReportFilterNotifier, ReportFilter>(
      ReportFilterNotifier.new,
    );

/// Daily stats for the range (one read per day, max 366).
final reportStatsProvider = FutureProvider.autoDispose<List<DailyStats>>((ref) {
  final keys = ref.watch(reportFilterProvider.select((f) => f.dayKeys));
  return ref
      .watch(statsRepositoryProvider)
      .fetchDays(keys.take(AppConstants.maxReportDays).toList());
});

/// Current inventory (capped).
final reportInventoryProvider = FutureProvider.autoDispose<List<Product>>(
  (ref) => ref.watch(productRepositoryProvider).allActive(),
);

/// Stock movements in the range (capped).
final reportMovementsProvider = FutureProvider.autoDispose<List<StockMovement>>(
  (ref) {
    final filter = ref.watch(reportFilterProvider);
    return ref
        .watch(stockRepositoryProvider)
        .movementsBetween(filter.from, filter.toExclusive);
  },
);

/// Generates the workbook off the UI thread, saves it to the temp folder
/// and opens the share sheet.
class ReportExporter extends AsyncNotifier<void> {
  static const String _mimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  @override
  FutureOr<void> build() {}

  Future<bool> export(ExcelReportSpec spec, {required String fileName}) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      try {
        final bytes = await compute(buildWorkbook, spec);
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}${Platform.pathSeparator}$fileName');
        await file.writeAsBytes(bytes, flush: true);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: _mimeType)],
            subject: fileName,
          ),
        );
      } on Object catch (error, stack) {
        AppLogger.error('Report export', error, stack);
        throw const ExportFailure();
      }
    });
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}

final reportExporterProvider =
    AsyncNotifierProvider.autoDispose<ReportExporter, void>(ReportExporter.new);
