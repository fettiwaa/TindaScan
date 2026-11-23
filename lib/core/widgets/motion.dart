import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:tindascan/core/theme/app_tokens.dart';

/// Shared motion helpers. Every helper is a no-op when animations are
/// disabled in accessibility settings.
extension MotionWidgetX on Widget {
  /// Staggered fade + slide-up entrance for list item [index]. Only the
  /// first [AppMotion.maxStaggeredItems] items animate (performance).
  Widget staggerIn(BuildContext context, int index) {
    final motion = context.motion;
    if (!motion.enabled || index >= AppMotion.maxStaggeredItems) return this;
    return animate(delay: motion.stagger * index)
        .fadeIn(duration: motion.normal, curve: AppMotion.enter)
        .slideY(
          begin: 0.08,
          end: 0,
          duration: motion.normal,
          curve: AppMotion.enter,
        );
  }

  /// Section entrance (fade + small rise), e.g. dashboard cards.
  Widget enterSection(BuildContext context, {int order = 0}) =>
      staggerIn(context, order);
}

/// Scales its child to [AppMotion.pressedScale] while pressed. Uses a
/// [Listener], so it never steals taps from the ripple underneath.
class Pressable extends StatefulWidget {
  const Pressable({required this.child, this.enabled = true, super.key});

  final Widget child;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (widget.enabled && _pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _pressed ? AppMotion.pressedScale : 1,
      duration: context.motion.fast,
      curve: AppMotion.enter,
      child: widget.child,
    ),
  );
}

/// Shakes its child horizontally whenever [trigger] changes (unknown
/// barcode, validation error).
class ShakeOnChange extends StatelessWidget {
  const ShakeOnChange({required this.trigger, required this.child, super.key});

  final Object? trigger;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    if (!motion.enabled || trigger == null) return child;
    return child
        .animate(key: ValueKey(trigger))
        .shake(hz: 4, offset: const Offset(6, 0), duration: motion.slow);
  }
}
