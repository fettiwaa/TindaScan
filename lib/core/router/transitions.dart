import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tindascan/core/theme/app_tokens.dart';

/// Slide-up + fade page for modal flows (scanner, receipt). Shows the page
/// immediately when animations are disabled.
CustomTransitionPage<T> slideUpPage<T>({
  required LocalKey key,
  required Widget child,
}) => CustomTransitionPage<T>(
  key: key,
  child: child,
  transitionDuration: AppMotion.slow,
  reverseTransitionDuration: AppMotion.normal,
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.enter,
      reverseCurve: AppMotion.transition,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  },
);

/// Keeps every shell branch alive (like an IndexedStack) but fades
/// between them, a light "fade-through" between main sections.
class FadeBranchContainer extends StatelessWidget {
  const FadeBranchContainer({
    required this.currentIndex,
    required this.children,
    super.key,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final duration = context.motion.normal;
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          _Branch(
            active: i == currentIndex,
            duration: duration,
            child: children[i],
          ),
      ],
    );
  }
}

class _Branch extends StatelessWidget {
  const _Branch({
    required this.active,
    required this.duration,
    required this.child,
  });

  final bool active;
  final Duration duration;
  final Widget child;

  @override
  // TickerMode must sit *inside* AnimatedOpacity: if it wrapped the
  // AnimatedOpacity, the leaving branch's own fade-out ticker would be muted
  // and the branch would stay visible on top of the new one.
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !active,
    child: ExcludeSemantics(
      excluding: !active,
      child: AnimatedOpacity(
        opacity: active ? 1 : 0,
        duration: duration,
        curve: AppMotion.transition,
        child: TickerMode(
          enabled: active,
          child: Offstage(
            offstage: !active && duration == Duration.zero,
            child: child,
          ),
        ),
      ),
    ),
  );
}
