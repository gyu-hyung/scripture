import 'package:flutter/services.dart';
import '../models/verse.dart';

class LiveActivityService {
  static const _channel = MethodChannel('com.jgh.scripture.liveActivity');

  /// 말씀 고정과 동시에 Live Activity 세션을 시작합니다.
  /// iOS 16.2 미만 기기에서는 아무 동작도 하지 않습니다.
  Future<void> startSession(Verse verse, String themeId) async {
    try {
      await _channel.invokeMethod<void>('startSession', {
        'verseText': verse.text,
        'verseRef': verse.reference,
        'themeId': themeId,
      });
    } on PlatformException catch (e) {
      // 시스템이 Live Activities를 지원하지 않거나 권한 없음 — 무시
      print('[LiveActivityService] startSession failed: ${e.message}');
    } on MissingPluginException {
      // Android 또는 시뮬레이터 — 무시
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

  /// HealthKit 권한을 요청합니다.
  /// - 미결정 상태: 시스템 다이얼로그 표시
  /// - 이미 결정된 상태: iOS 설정 앱으로 이동
  /// Android / iOS 16.2 미만에서는 아무 동작도 하지 않습니다.
  Future<void> requestHealthKitPermission() async {
    try {
      await _channel.invokeMethod<void>('requestHealthKitPermission');
    } on PlatformException catch (e) {
      print('[LiveActivityService] requestHealthKitPermission failed: ${e.message}');
    } on MissingPluginException {
      // Android 또는 시뮬레이터 — 무시
    }
  }
}
