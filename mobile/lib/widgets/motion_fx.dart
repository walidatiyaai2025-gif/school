import 'package:flutter/material.dart';

/// Finite, low-cost entrance motion, with reduced-motion support.
/// No infinite tickers: safe to use in lists and on entry-level phones.
class MotionReveal extends StatelessWidget {
  const MotionReveal({super.key, required this.child,
    this.order = 0, this.distance = 18, this.fromScale = .96});
  final Widget child;
  final int order;
  final double distance;
  final double fromScale;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + order.clamp(0, 7).toInt() * 90),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, distance * (1 - value)),
          child: Transform.scale(
            scale: fromScale + (1 - fromScale) * value,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Springs a card gently on touch, never animates continuously in background.
class MotionPress extends StatefulWidget {
  const MotionPress({super.key, required this.child, required this.onTap,
    this.radius = 23, this.pressedScale = .965});
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final double pressedScale;

  @override State<MotionPress> createState() => _MotionPressState();
}

class _MotionPressState extends State<MotionPress> {
  bool _pressed = false;
  @override Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      duration: reduced ? Duration.zero : const Duration(milliseconds: 130),
      curve: Curves.easeOutBack,
      scale: _pressed && !reduced ? widget.pressedScale : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.radius),
          onHighlightChanged: (pressed) {
            if (mounted && _pressed != pressed) {
              setState(() => _pressed = pressed);
            }
          },
          onTap: widget.onTap,
          child: widget.child,
        ),
      ),
    );
  }
}
