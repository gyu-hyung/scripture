import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/verse.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';

class WidgetThemeScreen extends ConsumerStatefulWidget {
  final Verse verse;

  const WidgetThemeScreen({super.key, required this.verse});

  @override
  ConsumerState<WidgetThemeScreen> createState() => _WidgetThemeScreenState();
}

class _WidgetThemeScreenState extends ConsumerState<WidgetThemeScreen> {
  String _selectedThemeId = AppConstants.themeModernDark;

  final List<Map<String, dynamic>> _themes = [
    {
      'id': AppConstants.themeModernDark,
      'name': '모던 다크',
      'bg': const Color(0xFF15151C),
      'text': Colors.white,
      'accent': const Color(0xFFB8860B),
    },
    {
      'id': AppConstants.themeMinimalistLight,
      'name': '미니멀 라이트',
      'bg': const Color(0xFFF8F9FA),
      'text': const Color(0xFF2D2D2D),
      'accent': const Color(0xFF0D47A1),
    },
    {
      'id': AppConstants.themeSereneBlue,
      'name': '세린 블루',
      'bg': const Color(0xFF0D47A1),
      'text': Colors.white,
      'accent': const Color(0xFFBBDEFB),
    },
    {
      'id': AppConstants.themeNatureGreen,
      'name': '네이처 그린',
      'bg': const Color(0xFF2E7D32),
      'text': Colors.white,
      'accent': const Color(0xFFC8E6C9),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedTheme = _themes.firstWhere((t) => t['id'] == _selectedThemeId);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('위젯 테마 선택', style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          // 프리뷰 영역
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AspectRatio(
              aspectRatio: 1, // 정사각형 위젯 느낌
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: selectedTheme['bg'],
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.book_rounded, color: selectedTheme['accent'], size: 14),
                        const SizedBox(width: 6),
                        Text(
                          '내가 설정한 말씀',
                          style: TextStyle(color: selectedTheme['accent'], fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      widget.verse.text,
                      style: GoogleFonts.notoSerif(
                        color: selectedTheme['text'],
                        fontSize: 16,
                        height: 1.6,
                      ),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        widget.verse.reference,
                        style: TextStyle(
                          color: selectedTheme['accent'],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          // 테마 선택 리스트
          SizedBox(
            height: 120,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: _themes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final t = _themes[index];
                final isSelected = t['id'] == _selectedThemeId;
                return GestureDetector(
                  onTap: () => setState(() => _selectedThemeId = t['id']),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: t['bg'],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: isSelected
                            ? Icon(Icons.check, color: t['text'], size: 24)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t['name'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          // 완료 버튼
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  await ref.read(pinnedVerseProvider.notifier).pinVerse(widget.verse, themeId: _selectedThemeId);
                  if (mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('위젯에 고정하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
