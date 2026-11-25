import 'package:flutter/material.dart';

class Brand {
  static const blue = Color(0xFF075DEB);
  static const navy = Color(0xFF102448);
  static const aqua = Color(0xFF00C9ED);
  static const bg = Color(0xFFF3F7FE);
  static const green = Color(0xFF12A86B);
  static const muted = Color(0xFF71819D);

  static ThemeData theme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.fromSeed(seedColor: blue, primary: blue,
      surface: Colors.white, brightness: Brightness.light),
    appBarTheme: const AppBarTheme(backgroundColor: bg, foregroundColor: navy,
      elevation: 0, centerTitle: true),
    // Material dialogs share one glossy Clean 3D surface across the whole app.
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFFF6F9FF),
      surfaceTintColor: Colors.transparent,
      elevation: 17,
      shadowColor: const Color(0xA84464A0),
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(27)),
      titleTextStyle: const TextStyle(
        color: navy, fontSize: 21, fontWeight: FontWeight.w900),
      contentTextStyle: const TextStyle(
        color: navy, fontSize: 14, height: 1.45),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: const Color(0xFFF5F8FF),
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shadowColor: const Color(0x773C5790),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(19),
        side: const BorderSide(color: Colors.white)),
    ),
    cardTheme: CardThemeData(color: Colors.white, surfaceTintColor: Colors.transparent,
      elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15)), textStyle: const TextStyle(fontWeight: FontWeight.w700))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15)))),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFD8E3F2))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFD8E3F2)))),
  );
}

class Logo extends StatelessWidget {
  const Logo({super.key, this.size = 52});
  final double size;
  @override Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * .23),
    child: Image.asset('assets/branding/icon.png', width: size, height: size, fit: BoxFit.cover),
  );
}
