class HomeLemonGamificationUiModel {
  const HomeLemonGamificationUiModel({
    required this.filledCount,
    required this.remainingUntilGift,
    required this.isGiftReady,
    this.totalSlots = 10,
  });

  final int filledCount;
  final int remainingUntilGift;
  final bool isGiftReady;
  final int totalSlots;

  double get progress => filledCount / totalSlots;
}

HomeLemonGamificationUiModel buildHomeLemonGamificationUiModel(int lemons) {
  final filledCount = lemons.clamp(0, 10);
  final isGiftReady = filledCount >= 10;

  return HomeLemonGamificationUiModel(
    filledCount: filledCount,
    remainingUntilGift: isGiftReady ? 0 : 10 - filledCount,
    isGiftReady: isGiftReady,
  );
}
