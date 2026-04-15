import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../models/verse.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';

import 'chapter_screen.dart';
import 'menu_screen.dart';
import 'widget_theme_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  bool _navigatorShown = false;
  bool _isSessionActive = false;
  bool _isStarting = false; // 체크마크 전환 상태

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSessionActive();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // 엔진 안정화 후 체크 (복귀 직후 MethodChannel 호출 크래시 방지)
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _checkSessionActive();
      });
    }
  }

  Future<void> _checkSessionActive() async {
    try {
      if (!mounted) return;
      final active = await ref.read(liveActivityServiceProvider).isSessionActive;
      if (mounted) setState(() => _isSessionActive = active);
    } catch (_) {
      // MethodChannel 호출 실패 시 무시
    }
  }

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

  void _showLiveActivityDisabledDialog() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.liveActivityDisabledTitle,
          style: GoogleFonts.gowunBatang(
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        content: Text(
          l10n.liveActivityDisabledBody,
          style: GoogleFonts.gowunBatang(
            fontSize: 14,
            height: 1.6,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.softPromptCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              launchUrl(Uri.parse('app-settings:'));
            },
            child: Text(l10n.liveActivityDisabledOpenSettings),
          ),
        ],
      ),
    );
  }

  /// 말씀이 없을 때 요한복음 1:1을 자동 고정
  Future<void> _pinDefaultVerse() async {
    if (_navigatorShown) return;
    _navigatorShown = true;

    final svc = ref.read(bibleServiceProvider);
    final verse = await svc.getVerse(43, 1, 1); // 요한복음 1:1
    if (verse == null || !mounted) return;

    await ref.read(pinnedVerseProvider.notifier).pinVerse(verse);
    _navigatorShown = false;
  }

  Future<void> _onStartSession() async {
    if (_isStarting) return;

    // 최초 실행 여부 확인 → 한 번도 설정한 적 없으면 테마 바텀시트 표시
    final prefs = await SharedPreferences.getInstance();
    final hasLaunched = prefs.getBool(AppConstants.keyHasLaunchedBefore) ?? false;

    if (!hasLaunched) {
      // 플래그 저장 (중복 표시 방지)
      await prefs.setBool(AppConstants.keyHasLaunchedBefore, true);

      final verse = ref.read(pinnedVerseProvider).value;
      if (verse != null && mounted) {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          isDismissible: true,
          enableDrag: true,
          builder: (_) => WidgetThemeBottomSheet(verse: verse),
        );
        // 바텀시트가 닫힌 뒤 세션 활성 상태 갱신 (햅틱과 함께)
        if (mounted) {
          HapticFeedback.mediumImpact();
          setState(() => _isSessionActive = true);
        }
      }
      return;
    }

    // 이후 실행: 기존 방식대로 바로 세션 시작
    setState(() => _isStarting = true);
    HapticFeedback.mediumImpact();

    final result = await ref.read(pinnedVerseProvider.notifier).restartSession();

    if (result == 'ACTIVITIES_DISABLED' && mounted) {
      setState(() => _isStarting = false);
      _showLiveActivityDisabledDialog();
      return;
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _isSessionActive = true;
      _isStarting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pinnedAsync = ref.watch(pinnedVerseProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = theme.colorScheme.primary;

    // 고정 말씀 상태가 바뀔 때마다 세션 활성 여부 갱신
    ref.listen(pinnedVerseProvider, (prev, next) {
      next.whenData((verse) {
        if (verse != null) {
          // 새 말씀이 고정된 경우 (초기 설정이 아닌 경우)
          if (prev?.value != null && verse.id != prev!.value!.id) {
            HapticFeedback.mediumImpact();
          }
          if (mounted) setState(() => _isSessionActive = true);
        }
      });
    });

    final showStartButton = !_isSessionActive &&
        !_isStarting &&
        Platform.isIOS &&
        pinnedAsync.value != null;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isSessionActive && Platform.isIOS ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !(_isSessionActive && Platform.isIOS),
              child: IconButton(
                icon: Icon(
                  Icons.stop_circle_outlined,
                  color: color.withValues(alpha: 0.6),
                  size: 22,
                ),
                tooltip: l10n.stopSession,
                onPressed: () async {
                  await ref
                      .read(pinnedVerseProvider.notifier)
                      .stopSessionOnly();
                  if (mounted) setState(() => _isSessionActive = false);
                },
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: color.withValues(alpha: 0.6),
              size: 22,
            ),
            tooltip: l10n.menu,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MenuScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // 말씀 콘텐츠 (항상 화면 중앙)
            pinnedAsync.when(
              loading: () => Center(
                child:
                    CircularProgressIndicator(color: color, strokeWidth: 2),
              ),
              error: (e, _) => Center(
                child: Text(
                  l10n.errorMsg(e.toString()),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
              data: (verse) {
                if (verse == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _pinDefaultVerse();
                  });
                  return Center(
                    child: CircularProgressIndicator(
                        color: color, strokeWidth: 2),
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
            // 하단 버튼
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: _StartSessionButton(
                visible: showStartButton || _isStarting,
                isStarting: _isStarting,
                color: color,
                onPressed: _onStartSession,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 세션 시작 버튼 (애니메이션 포함) ─────────────────────────────────────────

class _StartSessionButton extends StatelessWidget {
  final bool visible;
  final bool isStarting;
  final Color color;
  final VoidCallback onPressed;

  const _StartSessionButton({
    required this.visible,
    required this.isStarting,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AnimatedSlide(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInCubic,
      offset: visible ? Offset.zero : const Offset(0, 2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: visible ? 1.0 : 0.0,
        child: ElevatedButton(
          onPressed: isStarting ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            disabledBackgroundColor: color,
            disabledForegroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 6,
            shadowColor: color.withValues(alpha: 0.4),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: isStarting
                ? const Icon(Icons.check_rounded, key: ValueKey('check'), size: 28)
                : Text(
                    l10n.startSession,
                    key: const ValueKey('text'),
                    style: GoogleFonts.gowunBatang(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
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
    final l10n = AppLocalizations.of(context);

    return Center(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.format_quote_rounded,
                size: 28,
                color: color.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 20),
              Text(
                verse.text,
                textAlign: TextAlign.center,
                style: GoogleFonts.gowunBatang(
                  fontSize: 18,
                  height: 1.9,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  verse.reference,
                  style: GoogleFonts.gowunBatang(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.tapToRead,
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
