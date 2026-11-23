import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_pdf/games/xo_ad_frequency.dart';
import 'package:school_pdf/data/app_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('only the sixth completed match qualifies for an ad break', () {
    var count = 0;
    for (var i = 0; i < 5; i++) {
      count = XoAdFrequency.recordCompleted(count);
      expect(XoAdFrequency.isBreakDue(count), false);
    }
    count = XoAdFrequency.recordCompleted(count);
    expect(XoAdFrequency.isBreakDue(count), true);
    expect(XoAdFrequency.recordCompleted(count), 6);
  });

  test('completed matches persist and ad reset is explicit', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    for (var i = 0; i < 6; i++) {
      await store.noteXoGameCompleted();
    }
    final reopened = await AppStore.load();
    expect(reopened.xoAdBreakDue, true);
    expect(reopened.xoAdRounds, 6);
    await reopened.noteXoInterstitialShown();
    final resetStore = await AppStore.load();
    expect(resetStore.xoAdRounds, 0);
    expect(resetStore.xoAdBreakDue, false);
  });
}
