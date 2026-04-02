import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/verse.dart';
import '../providers/providers.dart';

import '../widgets/bible_navigator_sheet.dart';
import 'chapter_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _navigatorShown = false;

  void _navigateToChapter(Verse verse) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChapterScreen(
          bookId: verse.bookId,
          bookName: verse.bookName ?? verse.bookAbbreviation ?? '',
          chapter: verse.chapter,
          highlightVerse: verse.verse,
        ),
      ),
    );
  }

  /// 말씀이 없을 때 자동으로 네비게이터 시트를 열고,
  /// 선택된 절을 홈 화면에 고정한다.
  Future<void> _openNavigatorAndPin() async {
    if (_navigatorShown) return;
    _navigatorShown = true;

    await Future.delayed(Duration.zero); // 프레임 안전
    if (!mounted) return;

    final result = await showModalBottomSheet<BibleNavResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // 강제 선택
      builder: (_) => const BibleNavigatorSheet(
        initialBookId: 58, // 히브리서 (Hebrews)
        initialChapter: 4,
        initialVerse: 12,
      ),
    );

    if (!mounted) return;
    _navigatorShown = false;

    if (result == null) return;

    // 선택된 절을 BibleService로 fetch해서 pin
    final svc = ref.read(bibleServiceProvider);
    final verse = await svc.getVerse(result.book.id, result.chapter, result.verse);
    if (verse == null || !mounted) return;

    await ref.read(pinnedVerseProvider.notifier).pinVerse(verse);
  }

  @override
  Widget build(BuildContext context) {
    final pinnedAsync = ref.watch(pinnedVerseProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: pinnedAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: color, strokeWidth: 2),
          ),
          error: (e, _) => Center(
            child: Text(
              l10n.errorMsg(e.toString()),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
          data: (verse) {
            if (verse == null) {
              // 말씀이 없으면 다음 프레임에서 자동으로 네비게이터 오픈
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _openNavigatorAndPin();
              });
              return Center(
                child: CircularProgressIndicator(color: color, strokeWidth: 2),
              );
            }
            return _PinnedVerseCenter(
              verse: verse,
              theme: theme,
              color: color,
              onTap: () => _navigateToChapter(verse),
            );
          },
        ),
      ),
    );
  }
}

// ─── 고정된 말씀 중앙 표시 ───────────────────────────────────────────────────

class _PinnedVerseCenter extends StatelessWidget {
  final Verse verse;
  final ThemeData theme;
  final Color color;
  final VoidCallback onTap;

  const _PinnedVerseCenter({
    required this.verse,
    required this.theme,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque, // 빈 공간도 터치 인식
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40), // 넉넉한 상하 여백
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 인용 아이콘
              Icon(
                Icons.format_quote_rounded,
                size: 28,
                color: color.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 20),

              // 본문 텍스트
              Text(
                verse.text,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSerif(
                  fontSize: 18,
                  height: 1.9,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              // 참조 (창세기 1:1)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  verse.reference,
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),

              const SizedBox(height: 32),
              // 탭 힌트
              Text(
                '탭하여 본문 보기',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
