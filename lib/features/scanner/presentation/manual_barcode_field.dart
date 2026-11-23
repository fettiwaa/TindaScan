import 'package:flutter/material.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/features/products/domain/product_validators.dart';

/// Manual-entry fallback for when scanning fails (poor light, damaged
/// barcode, no camera permission).
class ManualBarcodeField extends StatefulWidget {
  const ManualBarcodeField({required this.onSubmit, super.key});

  final ValueChanged<String> onSubmit;

  @override
  State<ManualBarcodeField> createState() => _ManualBarcodeFieldState();
}

class _ManualBarcodeFieldState extends State<ManualBarcodeField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = ProductValidators.normalizeBarcode(_controller.text);
    if (ProductValidators.barcode(code) != null) return;
    widget.onSubmit(code);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const Key('manual-barcode'),
            controller: _controller,
            keyboardType: TextInputType.number,
            maxLength: AppConstants.maxBarcodeLength,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.scannerManualHint,
              prefixIcon: const Icon(Icons.keyboard),
              counterText: '',
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(onPressed: _submit, child: Text(l10n.scannerManualSubmit)),
      ],
    );
  }
}
