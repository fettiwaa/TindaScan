import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/features/scanner/presentation/barcode_scanner_view.dart';
import 'package:tindascan/features/scanner/presentation/manual_barcode_field.dart';

/// Full-screen single scan. Pops with the barcode (scanned or typed).
/// Usage: `final code = await context.push<String>(AppRoutes.scan);`
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _done = false;

  bool? _finish(String code) {
    if (_done) return null;
    _done = true;
    context.pop(code);
    return true;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.scannerTitle)),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Gaps.md),
        child: Column(
          children: [
            Expanded(child: BarcodeScannerView(onScan: _finish)),
            const SizedBox(height: Gaps.md),
            ManualBarcodeField(onSubmit: _finish),
          ],
        ),
      ),
    ),
  );
}
