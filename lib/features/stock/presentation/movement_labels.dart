import 'package:flutter/material.dart';

import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/shared/models/stock_movement.dart';

/// Localized names and icons for movement types.
extension MovementTypeLabel on MovementType {
  String label(AppLocalizations l10n) => switch (this) {
    MovementType.restock => l10n.movementRestock,
    MovementType.sale => l10n.movementSale,
    MovementType.spoilage => l10n.movementSpoilage,
    MovementType.adjustment => l10n.movementAdjustment,
  };

  IconData get icon => switch (this) {
    MovementType.restock => Icons.add_box_outlined,
    MovementType.sale => Icons.point_of_sale,
    MovementType.spoilage => Icons.delete_outline,
    MovementType.adjustment => Icons.tune,
  };
}
