import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_step_data.dart';
import '../utils/constants.dart';
import 'bible_provider.dart';

final weeklyStepsProvider =
    FutureProvider.autoDispose<List<DailyStepData>>((ref) async {
  final svc = ref.read(liveActivityServiceProvider);
  final rawSteps = await svc.fetchWeeklySteps();

  final prefs = await SharedPreferences.getInstance();
  final historyJson =
      prefs.getString(AppConstants.keyVerseHistory) ?? '{}';
  final history = Map<String, dynamic>.from(jsonDecode(historyJson));

  final todayStr = DateTime.now().toIso8601String().substring(0, 10);
  final currentRef = prefs.getString(AppConstants.keyCurrentVerseRef);
  final currentText = prefs.getString(AppConstants.keyCurrentVerseText);

  return rawSteps.map((entry) {
    final dateStr = entry['date'] as String;
    final steps = entry['steps'] as int? ?? 0;
    final verseData = history[dateStr];

    String? ref;
    String? text;
    if (verseData is Map) {
      ref = verseData['ref'] as String?;
      text = verseData['text'] as String?;
    } else if (verseData is String) {
      ref = verseData;
    }

    if (ref == null && dateStr == todayStr && currentRef != null) {
      ref = currentRef;
      text = currentText;
    }

    return DailyStepData(
      date: DateTime.parse(dateStr),
      steps: steps,
      verseReference: ref,
      verseText: text,
    );
  }).toList();
});
