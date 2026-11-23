import 'package:flutter/material.dart';

/// Raised tiles respond to touch and state changes with finite, tactile motion.
class Game3DTile extends StatefulWidget {
  const Game3DTile({
    super.key, required this.child, this.onTap,
    this.color = const Color(0xFFEDF4FF), this.selected = false,
    this.radius = 14, this.label,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final bool selected;
  final double radius;
  final String? label;

  @override State<Game3DTile> createState() => _Game3DTileState();
}

class _Game3DTileState extends State<Game3DTile> {
  bool _pressed = false;

  @override Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final hsl = HSLColor.fromColor(widget.color);
    final shade = hsl.withLightness(
      (hsl.lightness - .23).clamp(.17, .69).toDouble()).toColor();
    final raised = widget.selected || _pressed ? 2.0 : 5.0;
    final decoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [
          Color.lerp(widget.color, Colors.white, .54)!,
          widget.color,
          Color.lerp(widget.color, shade, .45)!,
        ]),
      borderRadius: BorderRadius.circular(widget.radius),
      border: Border.all(color: const Color(0xB3FFFFFF), width: 1.2),
      boxShadow: [
        BoxShadow(color: shade.withValues(alpha: .24),
          blurRadius: 4, offset: const Offset(0, 3)),
      ],
    );

    final tile = AnimatedScale(
      scale: _pressed && !reduced ? .95 : 1,
      duration: reduced ? Duration.zero : const Duration(milliseconds: 115),
      curve: Curves.easeOutBack,
      child: Stack(fit: StackFit.expand, children: [
        Positioned.fill(top: 5, child: DecoratedBox(
          decoration: BoxDecoration(
            color: shade,
            borderRadius: BorderRadius.circular(widget.radius)),
        )),
        Positioned.fill(bottom: raised, child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.radius),
          child: Ink(
            decoration: decoration,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (pressed) {
                if (mounted && _pressed != pressed) {
                  setState(() => _pressed = pressed);
                }
              },
              borderRadius: BorderRadius.circular(widget.radius),
              child: Stack(fit: StackFit.expand, children: [
                Positioned(top: 3, left: 6, right: 6,
                  child: IgnorePointer(child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: const LinearGradient(colors: [
                        Color(0x99FFFFFF), Color(0x00FFFFFF),
                      ]),
                    ),
                  )),
                ),
                Center(child: widget.child),
              ]),
            ),
          ),
        )),
      ]),
    );
    if (widget.label == null) return tile;
    return Semantics(
      label: widget.label,
      button: widget.onTap != null,
      child: tile);
  }
}
