import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';
import 'app.dart';
import 'models/translation.dart';
import 'services/bible_service.dart';
import 'services/widget_service.dart';
import 'utils/constants.dart';

const _dailyVerseTask = 'com.jgh.scripture.dailyVerse';

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

  // 네트워크 폰트 다운로드 차단 — 번들된 로컬 폰트만 사용
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(
    const ProviderScope(
      child: ScriptureApp(),
    ),
  );

  // Workmanager는 UI에 영향 없으므로 백그라운드 초기화
  if (Platform.isAndroid) {
    Workmanager().initialize(callbackDispatcher).then((_) {
      Workmanager().registerPeriodicTask(
        _dailyVerseTask,
        _dailyVerseTask,
        frequency: const Duration(hours: 24),
        constraints: Constraints(networkType: NetworkType.notRequired),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    });
  }
}
