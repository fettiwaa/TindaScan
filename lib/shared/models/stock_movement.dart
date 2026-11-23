import 'package:flutter/foundation.dart';

import 'package:tindascan/core/constants/firestore_paths.dart';
import 'package:tindascan/shared/models/firestore_parsing.dart';

/// Why stock changed. Values match the security rules.
enum MovementType {
  restock('restock'),
  sale('sale'),
  spoilage('spoilage'),
  adjustment('adjustment');

  const MovementType(this.value);

  final String value;

  static MovementType fromValue(Object? value) => MovementType.values
      .firstWhere((t) => t.value == value, orElse: () => adjustment);
}

/// An append-only stock change (`stock_movements/{id}`).
@immutable
class StockMovement {
  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.qtyChange,
    required this.note,
    required this.userId,
    this.userName = '',
    this.saleId,
    this.createdAt,
  });

  factory StockMovement.fromMap(String id, Map<String, Object?> map) =>
      StockMovement(
        id: id,
        productId: map.readString(MovementFields.productId),
        productName: map.readString(MovementFields.productName),
        type: MovementType.fromValue(map[MovementFields.type]),
        qtyChange: map.readInt(MovementFields.qtyChange),
        note: map.readString(MovementFields.note),
        userId: map.readString(MovementFields.userId),
        userName: map.readString(MovementFields.userName),
        saleId: map.readStringOrNull(MovementFields.saleId),
        createdAt: map.readDateTime(MovementFields.createdAt),
      );

  final String id;
  final String productId;
  final String productName;
  final MovementType type;

  /// Positive adds stock, negative removes it.
  final int qtyChange;
  final String note;
  final String userId;
  final String userName;
  final String? saleId;
  final DateTime? createdAt;

  /// Fields written on creation; `createdAt` is added by the repository.
  Map<String, Object?> toMap() => {
    MovementFields.productId: productId,
    MovementFields.productName: productName,
    MovementFields.type: type.value,
    MovementFields.qtyChange: qtyChange,
    MovementFields.note: note,
    MovementFields.userId: userId,
    MovementFields.userName: userName,
    if (saleId != null) MovementFields.saleId: saleId,
  };
}
