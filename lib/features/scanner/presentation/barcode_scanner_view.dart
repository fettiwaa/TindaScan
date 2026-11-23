import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/errors/app_logger.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/features/products/domain/product_validators.dart';
import 'package:tindascan/features/scanner/domain/scan_debouncer.dart';

enum _CameraAccess { checking, granted, denied, permanentlyDenied, error }

/// Result of handling a scan, used for visual feedback on the frame:
/// `true` flashes green, `false` flashes amber, `null` shows nothing.
typedef ScanHandler = FutureOr<bool?> Function(String code);

/// Reusable camera barcode scanner.
///
/// Handles: camera permission (including "permanently denied" with a
/// shortcut to system settings), a rounded scan frame with an animated scan
/// line, green/amber flash feedback, torch toggle, duplicate-read
/// debouncing, and releasing the camera when the app goes to background.
///
/// Known risk: scan accuracy depends on lighting, focus and print quality.
/// Every screen using this view therefore also offers manual entry.
class BarcodeScannerView extends StatefulWidget {
  const BarcodeScannerView({required this.onScan, super.key});

  /// Called once per accepted (debounced, normalized) barcode.
  final ScanHandler onScan;

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView>
    with WidgetsBindingObserver {
  // Restricting formats to retail barcodes speeds up detection.
  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.qrCode,
    ],
  );
  final ScanDebouncer _debouncer = ScanDebouncer(AppConstants.scanDebounce);
  _CameraAccess _access = _CameraAccess.checking;

  /// Frame flash: true = success (green), false = warning (amber).
  bool? _flash;
  Timer? _flashTimer;
  static const Duration _flashDuration = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_checkPermission(request: true));
  }

  Future<void> _checkPermission({required bool request}) async {
    try {
      var status = await Permission.camera.status;
      if (!status.isGranted && request && !status.isPermanentlyDenied) {
        status = await Permission.camera.request();
      }
      if (!mounted) return;
      setState(() {
        _access = status.isGranted
            ? _CameraAccess.granted
            : status.isPermanentlyDenied || status.isRestricted
            ? _CameraAccess.permanentlyDenied
            : _CameraAccess.denied;
      });
      if (status.isGranted) await _start();
    } on Object catch (error, stack) {
      AppLogger.error('Camera permission', error, stack);
      if (mounted) setState(() => _access = _CameraAccess.error);
    }
  }

  Future<void> _start() async {
    try {
      await _controller.start();
    } on MobileScannerException catch (error) {
      // Already running is fine; anything else shows the error panel.
      if (error.errorCode !=
              MobileScannerErrorCode.controllerAlreadyInitialized &&
          error.errorCode != MobileScannerErrorCode.controllerInitializing) {
        AppLogger.error('Scanner start', error);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // The user may have granted the permission in system settings.
        if (_access == _CameraAccess.granted) {
          unawaited(_start());
        } else {
          unawaited(_checkPermission(request: false));
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // Release the camera for other apps and to save battery.
        unawaited(_controller.stop());
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.trim().isEmpty) continue;
      final code = ProductValidators.normalizeBarcode(raw);
      if (!_debouncer.accept(code, DateTime.now())) return;
      final result = await widget.onScan(code);
      if (result != null && mounted) _showFlash(success: result);
      return;
    }
  }

  void _showFlash({required bool success}) {
    _flashTimer?.cancel();
    setState(() => _flash = success);
    _flashTimer = Timer(_flashDuration, () {
      if (mounted) setState(() => _flash = null);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flashTimer?.cancel();
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final frameColor = switch (_flash) {
      true => tokens.success,
      false => tokens.warning,
      null => Colors.white,
    };
    return Semantics(
      label: l10n.scannerSemantics,
      container: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.large),
        child: ColoredBox(
          color: Colors.black,
          child: switch (_access) {
            _CameraAccess.checking => const Center(
              child: CircularProgressIndicator(),
            ),
            _CameraAccess.granted => _ScannerPreview(
              controller: _controller,
              onDetect: _handleDetect,
              frameColor: frameColor,
            ),
            _CameraAccess.denied => _PermissionPanel(
              message: l10n.scannerPermissionNeeded,
              actionLabel: l10n.scannerAllowCamera,
              onAction: () => _checkPermission(request: true),
            ),
            _CameraAccess.permanentlyDenied => _PermissionPanel(
              message: l10n.scannerPermissionDenied,
              actionLabel: l10n.scannerOpenSettings,
              onAction: openAppSettings,
            ),
            _CameraAccess.error => _PermissionPanel(message: l10n.scannerError),
          },
        ),
      ),
    );
  }
}

class _ScannerPreview extends StatelessWidget {
  const _ScannerPreview({
    required this.controller,
    required this.onDetect,
    required this.frameColor,
  });

  final MobileScannerController controller;
  final void Function(BarcodeCapture) onDetect;
  final Color frameColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: controller,
          onDetect: onDetect,
          errorBuilder: (context, error) =>
              _PermissionPanel(message: l10n.scannerError),
        ),
        IgnorePointer(child: ScanFrameOverlay(color: frameColor)),
        Positioned(
          left: Gaps.md,
          right: AppSizes.minTapTarget + Gaps.md,
          bottom: Gaps.md,
          child: Text(
            l10n.scannerHint,
            style: const TextStyle(
              color: Colors.white,
              shadows: [Shadow(blurRadius: 4)],
            ),
          ),
        ),
        Positioned(
          right: Gaps.sm,
          bottom: Gaps.sm,
          child: ValueListenableBuilder<MobileScannerState>(
            valueListenable: controller,
            builder: (context, state, _) {
              final on = state.torchState == TorchState.on;
              if (state.torchState == TorchState.unavailable) {
                return const SizedBox.shrink();
              }
              return IconButton.filledTonal(
                tooltip: on ? l10n.scannerTorchOff : l10n.scannerTorchOn,
                icon: Icon(
                  on
                      ? Symbols.flashlight_off_rounded
                      : Symbols.flashlight_on_rounded,
                ),
                onPressed: controller.toggleTorch,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PermissionPanel extends StatelessWidget {
  const _PermissionPanel({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(Gaps.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Symbols.no_photography_rounded, color: Colors.white),
          const SizedBox(height: Gaps.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: Gaps.sm),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

/// Soft dark overlay with a rounded scan window, corner marks in [color]
/// and an animated scan line (static when animations are disabled).
class ScanFrameOverlay extends StatefulWidget {
  const ScanFrameOverlay({required this.color, super.key});

  final Color color;

  @override
  State<ScanFrameOverlay> createState() => _ScanFrameOverlayState();
}

class _ScanFrameOverlayState extends State<ScanFrameOverlay>
    with SingleTickerProviderStateMixin {
  static const Duration _sweep = Duration(milliseconds: 1800);
  late final AnimationController _line = AnimationController(
    vsync: this,
    duration: _sweep,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only animate when motion is allowed; TickerMode pauses it when the
    // scanner is not visible.
    if (context.motion.enabled) {
      if (!_line.isAnimating) _line.repeat(reverse: true);
    } else {
      _line
        ..stop()
        ..value = 0.5;
    }
  }

  @override
  void dispose() {
    _line.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<Color?>(
    tween: ColorTween(end: widget.color),
    duration: context.motion.fast,
    builder: (context, color, _) => AnimatedBuilder(
      animation: _line,
      builder: (context, _) => CustomPaint(
        painter: _ScanFramePainter(
          color: color ?? Colors.white,
          line: Curves.easeInOut.transform(_line.value),
        ),
      ),
    ),
  );
}

class _ScanFramePainter extends CustomPainter {
  const _ScanFramePainter({required this.color, required this.line});

  final Color color;
  final double line;

  static const double _widthFactor = 0.78;
  static const double _heightFactor = 0.42;
  static const double _corner = 26;
  static const Radius _radius = Radius.circular(18);

  @override
  void paint(Canvas canvas, Size size) {
    final window = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * _widthFactor,
      height: size.height * _heightFactor,
    );
    final rrect = RRect.fromRectAndRadius(window, _radius);
    canvas.drawPath(
      Path()
        ..addRect(Offset.zero & size)
        ..addRRect(rrect)
        ..fillType = PathFillType.evenOdd,
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );

    final stroke = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final (corner, dx, dy) in [
      (window.topLeft, 1.0, 1.0),
      (window.topRight, -1.0, 1.0),
      (window.bottomLeft, 1.0, -1.0),
      (window.bottomRight, -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(corner, corner.translate(_corner * dx, 0), stroke)
        ..drawLine(corner, corner.translate(0, _corner * dy), stroke);
    }

    final y = window.top + 8 + (window.height - 16) * line;
    canvas.drawLine(
      Offset(window.left + 12, y),
      Offset(window.right - 12, y),
      Paint()
        ..color = color.withValues(alpha: 0.85)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ScanFramePainter old) =>
      old.color != color || old.line != line;
}
