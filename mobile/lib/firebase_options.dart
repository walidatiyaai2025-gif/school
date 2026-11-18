// Generated from the owner-supplied Firebase Android/iOS config files.
// Client-side identifiers / API keys, NOT an FCM server credential.
// Changes to the Firebase project require regenerating this file and the native configs.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('School PDF Firebase is configured for Android and iOS only.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Firebase is not configured on this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyAzomqIyHbET_h0oGlbwRq4sR7NVW-byro",
    appId: "1:718574327363:android:a12c3a0e123b5ed42966f6",
    messagingSenderId: "718574327363",
    projectId: "schoolpdf-50sols",
    storageBucket: "schoolpdf-50sols.firebasestorage.app",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyAABQ3zVIqY3cyy9tlFZ0AEHInupNTt7U8",
    appId: "1:718574327363:ios:74ab988e043c60c12966f6",
    messagingSenderId: "718574327363",
    projectId: "schoolpdf-50sols",
    storageBucket: "schoolpdf-50sols.firebasestorage.app",
    iosBundleId: "com.fiftysols.schoolpdf",
  );
}
