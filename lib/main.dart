import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';
import 'app.dart';
import 'models/translation.dart';
import 'services/bible_service.dart';
import 'services/widget_service.dart';
import 'utils/constants.dart';

const _dailyVerseTask = 'com.scripture.dailyVerse';

// Android 전용 백그라운드 작업 디스패처
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    if (task == _dailyVerseTask) {
      await HomeWidget.setAppGroupId(AppConstants.appGroupId);
      // 백그라운드 태스크는 기본 번역본(개역개정) 사용
      final bibleService = BibleService(Translation.bundled[0]);
      final widgetService = WidgetService(bibleService);
      await widgetService.updateDailyVerse();
    }
    return true;
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isIOS || Platform.isAndroid) {
    await HomeWidget.setAppGroupId(AppConstants.appGroupId);
  }

  // workmanager는 Android에서만 사용
  // iOS는 WidgetKit TimelineProvider가 자체적으로 매일 갱신 처리
  if (Platform.isAndroid) {
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      _dailyVerseTask,
      _dailyVerseTask,
      frequency: const Duration(hours: 24),
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  runApp(
    const ProviderScope(
      child: ScriptureApp(),
    ),
  );
}
