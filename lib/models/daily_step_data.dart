class DailyStepData {
  final DateTime date;
  final int steps;
  final String? verseReference;
  final String? verseText;

  const DailyStepData({
    required this.date,
    required this.steps,
    this.verseReference,
    this.verseText,
  });
}
