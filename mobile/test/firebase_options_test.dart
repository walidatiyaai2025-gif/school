import 'package:flutter_test/flutter_test.dart';
import 'package:school_pdf/firebase_options.dart';

void main() {
  test('Firebase Android/iOS clients share the School PDF project', () {
    expect(DefaultFirebaseOptions.android.projectId, 'schoolpdf-50sols');
    expect(DefaultFirebaseOptions.ios.projectId, 'schoolpdf-50sols');
    expect(DefaultFirebaseOptions.android.messagingSenderId,
        DefaultFirebaseOptions.ios.messagingSenderId);
    expect(DefaultFirebaseOptions.ios.iosBundleId, 'com.fiftysols.schoolpdf');
    expect(DefaultFirebaseOptions.android.appId, contains(':android:'));
    expect(DefaultFirebaseOptions.ios.appId, contains(':ios:'));
  });
}
