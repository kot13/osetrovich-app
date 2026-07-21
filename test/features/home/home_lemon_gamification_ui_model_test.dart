import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/home/domain/home_lemon_gamification_ui_model.dart';

void main() {
  group('buildHomeLemonGamificationUiModel', () {
    test('maps lemons to filled count', () {
      expect(buildHomeLemonGamificationUiModel(0).filledCount, 0);
      expect(buildHomeLemonGamificationUiModel(7).filledCount, 7);
      expect(buildHomeLemonGamificationUiModel(10).filledCount, 10);
    });

    test('clamps negative and overflow values', () {
      expect(buildHomeLemonGamificationUiModel(-3).filledCount, 0);
      expect(buildHomeLemonGamificationUiModel(15).filledCount, 10);
    });

    test('calculates remaining lemons until gift', () {
      expect(buildHomeLemonGamificationUiModel(0).remainingUntilGift, 10);
      expect(buildHomeLemonGamificationUiModel(7).remainingUntilGift, 3);
      expect(buildHomeLemonGamificationUiModel(9).remainingUntilGift, 1);
      expect(buildHomeLemonGamificationUiModel(10).remainingUntilGift, 0);
    });

    test('marks gift ready at 10 lemons', () {
      expect(buildHomeLemonGamificationUiModel(9).isGiftReady, isFalse);
      expect(buildHomeLemonGamificationUiModel(10).isGiftReady, isTrue);
    });

    test('progress is fraction of filled slots', () {
      expect(buildHomeLemonGamificationUiModel(7).progress, 0.7);
    });
  });
}
