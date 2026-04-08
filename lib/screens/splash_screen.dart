import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // 더 빠르게 페이드
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // 1. 애니메이션 시작 (Fade In)
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _controller.forward();
    });

    // 2. 2초 뒤 빠르게 Fade Out
    Timer(const Duration(milliseconds: 2000), () {
      if (mounted) _controller.reverse();
    });

    // 3. 완전히 사라진 즉시(2.8초) 홈 화면으로 빛의 속도로 전환
    Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 300), // 아주 빠르게
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
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD), // 깨끗하고 우아한 웜 화이트
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
                  // 시각적 균형을 위한 아주 얇은 디바이너 선
                  Container(
                    width: 20,
                    height: 1.5,
                    color: const Color(0xFF2C2A38).withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 40),

                  // 메인 시편 말씀 (가장 감성적이고 우아한 '고운 바탕'체 적용)
                  Text(
                    '주의 말씀은 내 발에 등이요\n내 길에 빛이니이다',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.gowunBatang(
                      fontSize: 28,
                      height: 1.8,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2C2A38),
                      letterSpacing: -0.5,
                    ),
                  ),
                  
                  const SizedBox(height: 35),

                  // 출처 (정갈하고 현대적인 '나눔 명조' 혹은 '고운 바탕')
                  Text(
                    '시편 119:105',
                    style: GoogleFonts.gowunBatang(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2C2A38).withValues(alpha: 0.4),
                      letterSpacing: 3.0,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // 하단 균형 선
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
