import 'package:flutter/services.dart';
import '../models/verse.dart';

class LiveActivityService {
  static const _channel = MethodChannel('com.jgh.scripture.liveActivity');

  /// 말씀 고정과 동시에 Live Activity 세션을 시작합니다.
  /// iOS 16.2 미만 기기에서는 아무 동작도 하지 않습니다.
  /// 반환값: null이면 성공, 'ACTIVITIES_DISABLED'이면 권한 거부됨.
  Future<String?> startSession(Verse verse, String themeId) async {
    try {
      await _channel.invokeMethod<void>('startSession', {
        'verseText': verse.text,
        'verseRef': verse.reference,
        'themeId': themeId,
      });
      return null;
    } on PlatformException catch (e) {
      if (e.code == 'ACTIVITIES_DISABLED') {
        return 'ACTIVITIES_DISABLED';
      }
      print('[LiveActivityService] startSession failed: ${e.message}');
      return null;
    } on MissingPluginException {
      // Android 또는 시뮬레이터 — 무시
      return null;
    }
  }

  /// 고정 해제와 동시에 Live Activity 세션을 종료합니다.
  Future<void> stopSession() async {
    try {
      await _channel.invokeMethod<void>('stopSession');
    } on PlatformException catch (e) {
      print('[LiveActivityService] stopSession failed: ${e.message}');
    } on MissingPluginException {
      // Android 또는 시뮬레이터 — 무시
    }
  }

  /// 현재 세션 활성 여부를 반환합니다.
  Future<bool> get isSessionActive async {
    try {
      return await _channel.invokeMethod<bool>('isSessionActive') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Live Activity(실시간 현황) 권한이 허용되어 있는지 확인합니다.
  Future<bool> get isLiveActivityEnabled async {
    try {
      return await _channel.invokeMethod<bool>('isLiveActivityEnabled') ?? true;
    } on PlatformException {
      return true;
    } on MissingPluginException {
      return true; // Android 등에서는 해당 없음
    }
  }

  /// iOS "동작 및 피트니스(Motion & Fitness)" 권한을 요청합니다.
  /// - 미결정 상태: 시스템 다이얼로그 표시
  /// Android / iOS 16.2 미만에서는 아무 동작도 하지 않습니다.
  Future<void> requestMotionFitnessPermission() async {
    try {
      await _channel.invokeMethod<void>('requestMotionFitnessPermission');
    } on PlatformException catch (e) {
      print('[LiveActivityService] requestMotionFitnessPermission failed: ${e.message}');
    } on MissingPluginException {
      // Android 또는 시뮬레이터 — 무시
    }
  }

  /// 이번 주(일~토) 날짜별 걸음 수를 조회합니다.
  Future<List<Map<String, dynamic>>> fetchWeeklySteps() async {
    try {
      final result = await _channel.invokeListMethod<Map>('fetchWeeklySteps');
      if (result == null) return [];
      return result
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on PlatformException {
      return [];
    } on MissingPluginException {
      return [];
    }
  }

  @Deprecated('Use requestMotionFitnessPermission()')
  Future<void> requestHealthKitPermission() => requestMotionFitnessPermission();
}
