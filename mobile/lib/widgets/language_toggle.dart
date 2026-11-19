import 'package:flutter/material.dart';
import '../data/app_store.dart';

/// Always-available, accessible language control; preference is persisted.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, required this.store, this.onChanged});
  final AppStore store;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final english = store.settings.english;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Tooltip(
        message: english ? 'Switch to Arabic' : 'التبديل إلى الإنجليزية',
        child: TextButton.icon(
        onPressed: () async {
          store.settings.english = !store.settings.english;
          await store.saveSettings();
          onChanged?.call();
        },
        icon: const Icon(Icons.translate, size: 19),
        label: Text(english ? 'العربية' : 'English'),
      )),
    );
  }
}
