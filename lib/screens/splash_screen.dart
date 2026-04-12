import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/bible_provider.dart';
import 'home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Future<void> _preloadFuture;
  final Completer<void> _timerCompleter = Completer<void>();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // 데이터 프리로드 시작 (애니메이션과 병렬)
    _preloadFuture = _preloadAndPersistVerse();

    // 1. 애니메이션 시작 (Fade In)
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _controller.forward();
    });

    // 2. 2.2초 뒤 Fade Out
    Timer(const Duration(milliseconds: 2200), () {
      if (mounted) _controller.reverse();
    });

    // 3. 3초 후 타이머 완료 신호
    Timer(const Duration(milliseconds: 3000), () {
      _timerCompleter.complete();
    });

    // 4. 타이머 + 프리로드 둘 다 완료 후 홈 화면으로 전환
    _navigateWhenReady();
  }

  /// 기존 pinned verse를 확인하거나, 없으면 요한복음 1:1을 DB에서 가져와 SharedPreferences에 저장
  Future<void> _preloadAndPersistVerse() async {
    try {
      final widgetService = ref.read(widgetServiceProvider);

      // 이미 고정된 말씀이 있으면 추가 작업 불필요
      final pinned = await widgetService.getPinnedVerse();
      if (pinned != null) return;

      // 첫 실행: 요한복음 1:1 가져오기 (DB 복사도 이때 완료됨)
      final bibleService = ref.read(bibleServiceProvider);
      final verse = await bibleService.getVerse(43, 1, 1);
      if (verse == null) return;

      // SharedPreferences에 저장 → HomeScreen의 provider가 이 데이터를 읽음
      await widgetService.pinVerse(verse);
    } catch (_) {
      // 실패해도 HomeScreen의 _pinDefaultVerse() 폴백이 처리
    }
  }

  Future<void> _navigateWhenReady() async {
    // 애니메이션 타이머 대기
    await _timerCompleter.future;

    // 프리로드 완료 대기 (최대 5초 제한)
    await _preloadFuture.timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 20,
                    height: 1.5,
                    color: const Color(0xFF2C2A38).withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    '태초에 말씀이 계시니라\n이 말씀이 하나님과 함께 계셨으니\n이 말씀은 곧 하나님이시니라',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.gowunBatang(
                      fontSize: 24,
                      height: 1.8,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2C2A38),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 35),
                  Text(
                    '요한복음 1:1',
                    style: GoogleFonts.gowunBatang(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2C2A38).withValues(alpha: 0.4),
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: 20,
                    height: 1.5,
                    color: const Color(0xFF2C2A38).withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
