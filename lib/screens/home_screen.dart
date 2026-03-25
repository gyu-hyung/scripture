import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/verse.dart';
import '../providers/providers.dart';
import 'bible_picker_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFirstRun());
  }

  Future<void> _checkFirstRun() async {
    final widgetService = ref.read(widgetServiceProvider);
    final daily = await widgetService.getDailyVerse();
    if (daily == null && mounted) _openPicker();
  }

  void _openPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BiblePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pinnedAsync = ref.watch(pinnedVerseProvider);
    final dailyAsync = ref.watch(dailyVerseProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('말씀위젯'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: '말씀 선택',
            onPressed: _openPicker,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 위아래 스크롤 카드 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  children: [
                    _SectionLabel(
                      label: '내가 선택한 말씀',
                      icon: Icons.push_pin_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 10),
                    _VerseCard(
                      verseAsync: pinnedAsync,
                      emptyMessage: '아직 말씀을 선택하지 않았어요\n아래 버튼으로 말씀을 선택해보세요',
                      onEmpty: _openPicker,
                      onUnpin: () =>
                          ref.read(pinnedVerseProvider.notifier).unpinVerse(),
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(
                      label: '오늘의 말씀',
                      icon: Icons.auto_awesome_rounded,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(height: 10),
                    _VerseCard(
                      verseAsync: dailyAsync,
                      emptyMessage: '오늘의 말씀을 불러오는 중...',
                      accentColor: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            // 하단 고정 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _openPicker,
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('말씀 선택하기'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SectionLabel({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _VerseCard extends StatelessWidget {
  final AsyncValue<Verse?> verseAsync;
  final String emptyMessage;
  final VoidCallback? onEmpty;
  final VoidCallback? onUnpin;
  final Color? accentColor;

  const _VerseCard({
    required this.verseAsync,
    required this.emptyMessage,
    this.onEmpty,
    this.onUnpin,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;

    return verseAsync.when(
      data: (verse) {
        if (verse == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Icon(Icons.menu_book_outlined,
                    size: 40, color: color.withValues(alpha: 0.3)),
                const SizedBox(height: 14),
                Text(
                  emptyMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (onEmpty != null) ...[
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: onEmpty,
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: const Text('말씀 선택하기'),
                  ),
                ],
              ],
            ),
          );
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: [
              Icon(Icons.format_quote_rounded,
                  size: 24, color: color.withValues(alpha: 0.35)),
              const SizedBox(height: 16),
              Text(
                verse.text,
                style: GoogleFonts.notoSerif(
                  fontSize: 17,
                  height: 1.85,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
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
              if (onUnpin != null) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onUnpin,
                  icon: const Icon(Icons.push_pin_outlined, size: 14),
                  label: const Text('고정 해제'),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    textStyle: const TextStyle(fontSize: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(color: color, strokeWidth: 2),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text('오류: $e',
            style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
      ),
    );
  }
}
