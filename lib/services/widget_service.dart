import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/verse.dart';
import '../utils/constants.dart';
import 'bible_service.dart';

class WidgetService {
  final BibleService _bibleService;

  WidgetService(this._bibleService);

  /// 사용자가 직접 말씀을 고정 설정
  Future<void> pinVerse(Verse verse, {String? themeId}) async {
    final prefs = await SharedPreferences.getInstance();

    // 테마 ID가 있으면 저장, 없으면 기존 테마 사용
    final currentTheme = themeId ??
        prefs.getString(AppConstants.keyBackgroundStyle) ??
        AppConstants.themeModernDark;
    if (themeId != null) {
      await prefs.setString(AppConstants.keyBackgroundStyle, themeId);
    }

    await prefs.setBool(AppConstants.keyIsPinned, true);
    await prefs.setInt(AppConstants.keyPinnedVerseId, verse.id);
    await _saveCurrentVerse(verse);
    await _updateNativeWidget(verse, isPinned: true, themeId: currentTheme);
  }

  /// 고정 해제 → 자동 일일 모드로 전환
  Future<void> unpinVerse() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsPinned, false);
    await prefs.remove(AppConstants.keyPinnedVerseId);
    final daily = await getDailyVerse();
    if (daily != null) {
      await _saveCurrentVerse(daily);
      await _updateNativeWidget(daily, isPinned: false);
    } else {
      await _forceNewDailyVerse();
    }
  }

  /// 고정 여부 확인
  Future<bool> isPinned() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyIsPinned) ?? false;
  }

  /// 사용자가 선택한 고정 말씀 반환 (없으면 null)
  Future<Verse?> getPinnedVerse() async {
    final prefs = await SharedPreferences.getInstance();
    final isPinnedFlag = prefs.getBool(AppConstants.keyIsPinned) ?? false;
    if (!isPinnedFlag) return null;
    final verseId = prefs.getInt(AppConstants.keyPinnedVerseId);
    if (verseId == null) return null;
    return await _bibleService.getVerseById(verseId);
  }

  /// 오늘의 말씀 반환
  Future<Verse?> getDailyVerse() async {
    final prefs = await SharedPreferences.getInstance();
    final verseId = prefs.getInt(AppConstants.keyDailyVerseId);
    if (verseId == null) return null;
    return await _bibleService.getVerseById(verseId);
  }

  /// 날짜가 바뀌었거나 일일 말씀이 없으면 갱신
  Future<void> checkAndUpdateDailyVerseIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final verseId = prefs.getInt(AppConstants.keyDailyVerseId);
    if (verseId == null || await _needsUpdate()) {
      await _forceNewDailyVerse();
    }
  }

  /// 강제로 새 일일 말씀 선택
  Future<void> _forceNewDailyVerse({String? category}) async {
    final verse = await _bibleService.getRandomPopularVerse(category: category);
    if (verse == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyDailyVerseId, verse.id);
    await prefs.setString(
      AppConstants.keyLastUpdateDate,
      DateTime.now().toIso8601String(),
    );

    // 고정 말씀이 없으면 위젯도 갱신
    final pinned = await isPinned();
    if (!pinned) {
      await _saveCurrentVerse(verse);
      await _updateNativeWidget(verse, isPinned: false);
    }
  }

  /// 일일 말씀 갱신 (workmanager 백그라운드 작업 & 수동 갱신 공용)
  Future<void> updateDailyVerse({String? category}) async {
    await _forceNewDailyVerse(category: category);
  }

  Future<Verse?> getCurrentVerse() async {
    final prefs = await SharedPreferences.getInstance();
    final verseId = prefs.getInt(AppConstants.keyCurrentVerseId);
    if (verseId == null) return null;
    return await _bibleService.getVerseById(verseId);
  }

  Future<void> _saveCurrentVerse(Verse verse) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyCurrentVerseId, verse.id);
    await prefs.setString(AppConstants.keyCurrentVerseText, verse.text);
    await prefs.setString(AppConstants.keyCurrentVerseRef, verse.reference);
  }

  Future<void> _updateNativeWidget(Verse verse,
      {bool? isPinned, String? themeId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pinnedStatus = isPinned ?? await this.isPinned();
      final currentTheme = themeId ??
          prefs.getString(AppConstants.keyBackgroundStyle) ??
          AppConstants.themeModernDark;

      await HomeWidget.setAppGroupId(AppConstants.appGroupId);
      await HomeWidget.saveWidgetData(
          AppConstants.keyWidgetVerseText, verse.text);
      await HomeWidget.saveWidgetData(
          AppConstants.keyWidgetVerseRef, verse.reference);
      await HomeWidget.saveWidgetData(
          AppConstants.keyWidgetIsPinned, pinnedStatus);
      await HomeWidget.saveWidgetData(AppConstants.keyWidgetTheme, currentTheme);

      await HomeWidget.updateWidget(
        androidName: AppConstants.widgetAndroidName,
        iOSName: AppConstants.widgetIosName,
      );
    } catch (e) {
      // Widget might not be placed yet
    }
  }

  /// 선택한 사진을 App Group 공유 컨테이너에 저장하고 위젯을 갱신합니다.
  Future<void> saveCustomPhoto(Uint8List jpegBytes) async {
    const channel = MethodChannel('com.scripture.liveActivity');
    try {
      await channel.invokeMethod<void>('saveCustomPhoto', {
        'data': jpegBytes,
      });
    } on PlatformException catch (e) {
      print('[WidgetService] saveCustomPhoto failed: ${e.message}');
    } on MissingPluginException {
      // 시뮬레이터 또는 미지원 환경
    }
  }

  Future<String> getCurrentThemeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyBackgroundStyle) ?? AppConstants.themeModernDark;
  }

  Future<bool> _needsUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getString(AppConstants.keyLastUpdateDate);
    if (lastUpdate == null) return true;

    final lastDate = DateTime.parse(lastUpdate);
    final now = DateTime.now();
    return lastDate.day != now.day ||
        lastDate.month != now.month ||
        lastDate.year != now.year;
  }
}
