import 'package:flutter/material.dart';

/// Glossy raised footer icons with a short selection pop; no looping motion.
class Footer3DIcon extends StatelessWidget {
  const Footer3DIcon({super.key, required this.icon, this.selected = false});
  final IconData icon;
  final bool selected;

  @override Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: !reduced && selected ? 1.08 : 1.0,
      duration: reduced ? Duration.zero : const Duration(milliseconds: 190),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        width: 37, height: 36,
        duration: reduced ? Duration.zero : const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: selected
              ? const [Color(0xFF41C7FF), Color(0xFF0757DB)]
              : const [Color(0xFFF8FCFF), Color(0xFFBDD6F9)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 1.2),
          boxShadow: const [BoxShadow(
            color: Color(0x553A68AD),
            blurRadius: 5, offset: Offset(1, 4))]),
        child: Icon(icon, size: 22,
          color: selected ? Colors.white : const Color(0xFF3068BB),
          shadows: const [Shadow(color: Color(0x440C3F7A),
            blurRadius: 2, offset: Offset(1, 2))]),
      ),
    );
  }
}
