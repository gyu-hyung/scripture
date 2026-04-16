import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'weekly_chart_screen.dart';

class HomePagerScreen extends StatefulWidget {
  const HomePagerScreen({super.key});

  @override
  State<HomePagerScreen> createState() => _HomePagerScreenState();
}

class _HomePagerScreenState extends State<HomePagerScreen> {
  final _pageController = PageController();
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() => _currentPage = _pageController.page ?? 0);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            children: const [
              HomeScreen(),
              WeeklyChartScreen(),
            ],
          ),
          // 페이지 인디케이터
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (i) {
                final distance = (_currentPage - i).abs().clamp(0.0, 1.0);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: distance < 0.5 ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: distance < 0.5
                        ? color.withValues(alpha: 0.6)
                        : color.withValues(alpha: 0.15),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
