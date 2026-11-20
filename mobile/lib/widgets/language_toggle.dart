import 'package:flutter/material.dart';
import '../data/app_store.dart';
import '../services/notifications_service.dart';

/// Always-available, accessible language control; preference is persisted.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, required this.store, this.onChanged, this.notifications});
  final AppStore store;
  final VoidCallback? onChanged;
  final NotificationService? notifications;

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
          // Refresh a previously scheduled reminder in the selected language.
          if (notifications != null) {
            try {
              await notifications!.configureReminder(
                enabled: store.settings.notifyReminders,
                time: store.settings.reminderTime,
                english: store.settings.english,
              );
            } catch (_) { /* Notification failures must not block switching languages. */ }
          }
          onChanged?.call();
        },
        icon: const Icon(Icons.translate, size: 19),
        label: Text(english ? 'العربية' : 'English'),
      )),
    );
  }
}
