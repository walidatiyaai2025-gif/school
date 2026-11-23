import 'package:flutter/material.dart';
import '../core/brand.dart';

/// Shared shadowed/glossy 3D popup entrance for the game's choice dialogs.
/// Material AlertDialogs throughout the app inherit Brand.dialogTheme.
Future<T?> showClean3DDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Close',
    barrierColor: const Color(0xA9203459),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (dialogContext, _, __) => Theme(
      data: Theme.of(dialogContext).copyWith(
        dialogTheme: Brand.theme.dialogTheme,
      ),
      child: Builder(builder: builder),
    ),
    transitionBuilder: (dialogContext, animation, _, child) {
      if (MediaQuery.disableAnimationsOf(dialogContext)) return child;
      final curved = CurvedAnimation(
        parent: animation, curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: .88, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}
