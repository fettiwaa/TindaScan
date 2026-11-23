import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tindascan/core/errors/failure_messages.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/router/app_routes.dart';
import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/shared/models/product.dart';
import 'package:tindascan/shared/providers/repository_providers.dart';

/// Looks up [code]; returns the active product or shows "Product not found".
/// Owners get an "Add this product" shortcut with the barcode prefilled;
/// staff only see the message.
Future<Product?> lookupBarcode(
  BuildContext context,
  WidgetRef ref,
  String code,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  Product? product;
  try {
    product = await ref.read(productRepositoryProvider).findByBarcode(code);
  } on Object catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(error.toUserMessage(l10n))));
    return null;
  }
  if (product != null && product.isActive) return product;
  if (!context.mounted) return null;
  await showProductNotFoundDialog(
    context,
    barcode: code,
    isOwner: ref.read(currentUserProvider)?.isOwner ?? false,
  );
  return null;
}

/// "Product not found" dialog with the owner-only add shortcut.
Future<void> showProductNotFoundDialog(
  BuildContext context, {
  required String barcode,
  required bool isOwner,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) {
    final l10n = dialogContext.l10n;
    return AlertDialog(
      icon: const Icon(Icons.search_off),
      title: Text(l10n.productNotFound),
      content: Text(l10n.productNotFoundMessage(barcode)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.close),
        ),
        if (isOwner)
          FilledButton.icon(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.push(
                Uri(
                  path: AppRoutes.productNew,
                  queryParameters: {AppRoutes.barcodeParam: barcode},
                ).toString(),
              );
            },
            label: Text(l10n.productAddThis),
          ),
      ],
    );
  },
);
