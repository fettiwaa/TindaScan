import 'package:flutter/foundation.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/constants/firestore_paths.dart';
import 'package:tindascan/shared/models/firestore_parsing.dart';

/// Store-wide settings at `settings/store`.
@immutable
class StoreSettings {
  const StoreSettings({
    required this.storeName,
    this.defaultLowStockThreshold = AppConstants.defaultLowStockThreshold,
  });

  factory StoreSettings.fromMap(Map<String, Object?> map) => StoreSettings(
    storeName: map.readString(SettingsFields.storeName, AppConstants.appName),
    defaultLowStockThreshold: map.readInt(
      SettingsFields.defaultLowStockThreshold,
      AppConstants.defaultLowStockThreshold,
    ),
  );

  static const StoreSettings fallback = StoreSettings(
    storeName: AppConstants.appName,
  );

  final String storeName;
  final int defaultLowStockThreshold;

  Map<String, Object?> toMap() => {
    SettingsFields.storeName: storeName,
    SettingsFields.defaultLowStockThreshold: defaultLowStockThreshold,
  };

  StoreSettings copyWith({String? storeName, int? defaultLowStockThreshold}) =>
      StoreSettings(
        storeName: storeName ?? this.storeName,
        defaultLowStockThreshold:
            defaultLowStockThreshold ?? this.defaultLowStockThreshold,
      );

  @override
  bool operator ==(Object other) =>
      other is StoreSettings &&
      other.storeName == storeName &&
      other.defaultLowStockThreshold == defaultLowStockThreshold;

  @override
  int get hashCode => Object.hash(storeName, defaultLowStockThreshold);
}
