import 'package:flutter/material.dart';

/// Standard Material DialogRoute retains inherited themes across its entire
/// exit animation. The app-wide Brand theme supplies the Clean 3D surface.
/// Avoid an extra inherited Theme inserted by a custom showGeneralDialog.
Future<T?> showClean3DDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final reducedMotion = MediaQuery.disableAnimationsOf(context);
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: const Color(0xA9203459),
    builder: builder,
    animationStyle: AnimationStyle(
      duration: reducedMotion ? Duration.zero
          : const Duration(milliseconds: 300),
      reverseDuration: reducedMotion ? Duration.zero
          : const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
  );
}
