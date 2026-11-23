import 'package:flutter/material.dart';

/// Tactile game-cell surfaces made with Flutter gradients and a raised face.
/// All colors are local: no images, engine plugin, or network access needed.
class Game3DTile extends StatelessWidget {
  const Game3DTile({
    super.key,
    required this.child,
    this.onTap,
    this.color = const Color(0xFFEDF4FF),
    this.selected = false,
    this.radius = 14,
    this.label,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final bool selected;
  final double radius;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(color);
    final shade = hsl.withLightness(
      (hsl.lightness - .23).clamp(.17, .69)).toColor();
    final raised = selected ? 2.0 : 5.0;
    final decoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [
          Color.lerp(color, Colors.white, .54)!,
          color,
          Color.lerp(color, shade, .45)!,
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xB3FFFFFF), width: 1.2),
      boxShadow: [
        BoxShadow(color: shade.withValues(alpha: .24),
          blurRadius: 4, offset: const Offset(0, 3)),
      ],
    );
    final tile = Stack(fit: StackFit.expand, children: [
      Positioned.fill(top: 5, child: DecoratedBox(
        decoration: BoxDecoration(
          color: shade,
          borderRadius: BorderRadius.circular(radius),
        ),
      )),
      Positioned.fill(bottom: raised, child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          decoration: decoration,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
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
              Center(child: child),
            ]),
          ),
        ),
      )),
    ]);
    if (label == null) return tile;
    return Semantics(label: label, button: onTap != null, child: tile);
  }
}
