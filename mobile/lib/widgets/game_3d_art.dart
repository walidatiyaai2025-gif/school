import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Flutter-rendered pseudo-3D game art: gradients, extruded tiles, reflections
/// and soft shadows. No network imagery or extra native dependencies.
enum GameArtKind { xo, math, words, sudoku }

class Game3DArt extends StatelessWidget {
  const Game3DArt({super.key, required this.kind, this.size = 116});
  final GameArtKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 120,
          height: 120,
          child: Transform.rotate(
            angle: kind == GameArtKind.words ? -.10 : .10,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(left: 17, top: 23,
                  child: Container(
                    width: 93, height: 91,
                    decoration: BoxDecoration(
                      color: const Color(0xFF173FAD),
                      borderRadius: BorderRadius.circular(23),
                      boxShadow: const [BoxShadow(
                        color: Color(0x660B2B85),
                        blurRadius: 17, offset: Offset(3, 11),
                      )],
                    ),
                  ),
                ),
                Positioned(left: 11, top: 13,
                  child: _TileFace(
                    size: 95,
                    colors: kind == GameArtKind.math
                        ? const [Color(0xFF82ADFF), Color(0xFF1655D7)]
                        : kind == GameArtKind.sudoku
                          ? const [Color(0xFFFFDB81), Color(0xFFF59D4D)]
                          : const [Color(0xFF30CBFF), Color(0xFF0757E9)],
                    child: kind == GameArtKind.xo ? _XoPieces()
                        : kind == GameArtKind.math ? _MathPieces()
                        : kind == GameArtKind.sudoku ? _SudokuPieces()
                        : _WordPieces(),
                  ),
                ),
                const Positioned(right: 2, top: 0,
                  child: Icon(Icons.auto_awesome_rounded,
                    size: 25, color: Color(0xFFFFC52C))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TileFace extends StatelessWidget {
  const _TileFace({required this.size, required this.colors, required this.child});
  final double size;
  final List<Color> colors;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topLeft,
        end: Alignment.bottomRight, colors: colors),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xAAFFFFFF), width: 1.7),
      boxShadow: [
        const BoxShadow(color: Color(0x330438A7),
          blurRadius: 7, offset: Offset(0, 4)),
      ],
    ),
    child: Stack(children: [
      Positioned(top: 1, left: 6, right: 6,
        child: Container(height: 9, decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [
            Color(0x77FFFFFF), Color(0x00FFFFFF)]),
          borderRadius: BorderRadius.circular(10)))),
      child,
    ]),
  );
}

class _XoPieces extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(children: [
    Center(child: CustomPaint(size: const Size(71, 72),
      painter: _XoGridPainter())),
    const Positioned(top: 0, left: 1,
      child: _EmbossedText('X', Color(0xFF1BDBFF))),
    const Positioned(top: 0, right: 0,
      child: _EmbossedText('O', Color(0xFFFF62B0))),
    const Positioned(bottom: 1, left: 1,
      child: _EmbossedText('O', Color(0xFFFF62B0))),
    const Positioned(bottom: 1, right: 1,
      child: _EmbossedText('X', Color(0xFF1BDBFF))),
  ]);
}

class _XoGridPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFADDEFF)
      ..strokeWidth = 3..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 2),
      Offset(size.width, size.height / 2), paint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EmbossedText extends StatelessWidget {
  const _EmbossedText(this.value, this.color);
  final String value;
  final Color color;
  @override Widget build(BuildContext context) => Text(value,
    style: TextStyle(color: color,
      fontSize: 39, fontWeight: FontWeight.w900,
      height: .92,
      shadows: const [
        Shadow(color: Color(0xFF0C3D8B), offset: Offset(2, 4),
          blurRadius: 2),
        Shadow(color: Color(0xAAFFFFFF), offset: Offset(-1, -1),
          blurRadius: 1),
      ]));
}

class _MathPieces extends StatelessWidget {
  @override Widget build(BuildContext context) =>
    GridView.count(crossAxisCount: 2, physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(3), mainAxisSpacing: 5, crossAxisSpacing: 5,
      children: const [
        _MiniTile('+', Color(0xFFFF62AD)),
        _MiniTile('−', Color(0xFF3CB4FF)),
        _MiniTile('×', Color(0xFFFFB829)),
        _MiniTile('=', Color(0xFF2DCF88)),
      ],
    );
}

class _WordPieces extends StatelessWidget {
  @override Widget build(BuildContext context) => Stack(children: [
    const Positioned(left: 20, top: 0,
      child: _LetterTile('A', Color(0xFF29B6FF))),
    const Positioned(left: 1, bottom: 0,
      child: _LetterTile('B', Color(0xFFFFB526))),
    const Positioned(right: 0, bottom: 2,
      child: _LetterTile('C', Color(0xFF9D61F6))),
  ]);
}

class _LetterTile extends StatelessWidget {
  const _LetterTile(this.letter, this.color);
  final String letter;
  final Color color;
  @override Widget build(BuildContext context) => _MiniTile(
    letter, color, side: 41, fontSize: 29);
}

class _MiniTile extends StatelessWidget {
  const _MiniTile(this.text, this.color, {this.side, this.fontSize = 25});
  final String text;
  final Color color;
  final double? side;
  final double fontSize;

  @override Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(color);
    final bottom = hsl.withLightness(math.max(.25, hsl.lightness - .19)).toColor();
    return Container(
      width: side, height: side,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, .25)!, color, bottom],
          stops: const [0, .6, 1]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x99FFFFFF)),
        boxShadow: [BoxShadow(color: bottom.withValues(alpha: .8),
          blurRadius: 1, offset: const Offset(1, 4))],
      ),
      child: Text(text, style: TextStyle(fontSize: fontSize,
        height: 1.1, fontWeight: FontWeight.w900, color: Colors.white,
        shadows: const [Shadow(color: Color(0x660A276F),
          blurRadius: 2, offset: Offset(1, 2))])),
    );
  }
}


/// A golden 3D Sudoku face, legible in a compact two-column game card.
class _SudokuPieces extends StatelessWidget {
  @override Widget build(BuildContext context) {
    const digits = ['1', '4', '7', '6', '9', '2', '3', '5', '8'];
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(3),
      itemCount: digits.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 3, crossAxisSpacing: 3),
      itemBuilder: (context, index) => Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F8FF),
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [BoxShadow(
            color: Color(0x77456DAD), offset: Offset(1, 2),
            blurRadius: 2)]),
        child: Text(digits[index], style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w900,
          color: index.isEven
              ? const Color(0xFF1958C4) : const Color(0xFFF1A235))),
      ),
    );
  }
}
