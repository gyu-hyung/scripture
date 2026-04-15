import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/verse.dart';
import '../models/widget_theme.dart';
import '../providers/providers.dart';

class WidgetThemeScreen extends ConsumerStatefulWidget {
  final Verse verse;

  const WidgetThemeScreen({super.key, required this.verse});

  @override
  ConsumerState<WidgetThemeScreen> createState() => _WidgetThemeScreenState();
}

class _WidgetThemeScreenState extends ConsumerState<WidgetThemeScreen> {
  WidgetTheme _selectedTheme = WidgetTheme.modernDark;

  // ── 소프트 프롬프트 → 세션 시작 ────────────────────────────────────
  Future<void> _showSoftPrompt(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              Icons.directions_walk_rounded,
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.softPromptTitle,
              style: GoogleFonts.gowunBatang(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.softPromptBody,
              style: GoogleFonts.gowunBatang(
                fontSize: 14,
                height: 1.6,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(sheetContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.softPromptConfirm,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(sheetContext).pop(false),
              child: Text(
                l10n.softPromptCancel,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == null || !mounted) return;

    // 권한을 허용하지 않아도(또는 거부하더라도) 세션은 시작되어야 하므로
    // "허용"을 선택한 경우에만 권한 요청을 시도합니다.
    if (confirmed == true) {
      await ref.read(liveActivityServiceProvider).requestMotionFitnessPermission();
    }

    await ref.read(pinnedVerseProvider.notifier).pinVerse(
          widget.verse,
          themeId: _selectedTheme.id,
        );
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ── 프리뷰 위젯 (실제 Live Activity 잠금화면 레이아웃과 동일) ────
  Widget _buildPreview(ThemeData _) {
    final bgColor = _selectedTheme.background;
    final textColor = _selectedTheme.textColor;
    final accentColor = _selectedTheme.accentColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
        ),
        child: Stack(
          children: [
            // 메인 컨텐츠: 참조 + 본문 (중앙 배치)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.verse.reference,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.verse.text,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 하단 우측: 걸음수 (잠금화면과 동일한 가로 배치)
                  Row(
                    children: [
                      const Spacer(),
                      const Text('👣', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '0',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '걸음',
                        style: TextStyle(
                          fontSize: 9,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 테마 선택 리스트 아이템 ─────────────────────────────────────────
  Widget _buildThemeItem(
      WidgetTheme wt, bool isSelected, ThemeData theme, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedTheme = wt);
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: wt.background,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            width: isSelected ? 3 : 1,
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
        clipBehavior: Clip.antiAlias,
        child: isSelected
            ? Icon(Icons.check, color: wt.textColor, size: 24)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          l10n.widgetThemeTitle,
          style: GoogleFonts.gowunBatang(
              fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 프리뷰 위치를 화면 상단 60~70% 구역(중하단 쪽)으로 조정
          const Spacer(flex: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildPreview(theme),
          ),
          const Spacer(flex: 3),
          // 테마 선택 리스트 (색상 팔레트)
          SizedBox(
            height: 72,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: WidgetTheme.all.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final wt = WidgetTheme.all[index];
                final isSelected = wt.id == _selectedTheme.id;
                return Center(child: _buildThemeItem(wt, isSelected, theme, l10n));
              },
            ),
          ),
          const SizedBox(height: 16),
          // 세션 시작 버튼
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _showSoftPrompt(context, theme, l10n);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  l10n.startSessionButton,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// ─── 최초 실행 시 홈화면에서 표시되는 바텀시트 ───────────────────────────────

class WidgetThemeBottomSheet extends ConsumerStatefulWidget {
  final Verse verse;

  const WidgetThemeBottomSheet({super.key, required this.verse});

  @override
  ConsumerState<WidgetThemeBottomSheet> createState() =>
      _WidgetThemeBottomSheetState();
}

class _WidgetThemeBottomSheetState
    extends ConsumerState<WidgetThemeBottomSheet> {
  WidgetTheme _selectedTheme = WidgetTheme.modernDark;

  // 바텀시트 내 소프트 프롬프트 → 세션 시작
  Future<void> _startSession(BuildContext ctx) async {
    final theme = Theme.of(ctx);
    final l10n = AppLocalizations.of(ctx);

    // 동작 및 피트니스 권한 요청 안내 시트
    final confirmed = await showModalBottomSheet<bool>(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              Icons.directions_walk_rounded,
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.softPromptTitle,
              style: GoogleFonts.gowunBatang(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.softPromptBody,
              style: GoogleFonts.gowunBatang(
                fontSize: 14,
                height: 1.6,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(sheetCtx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.softPromptConfirm,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(sheetCtx).pop(false),
              child: Text(
                l10n.softPromptCancel,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == null || !mounted) return;

    // 권한을 허용하지 않아도 세션은 시작되어야 하므로,
    // "허용"을 선택한 경우에만 권한 요청을 시도합니다.
    if (confirmed == true) {
      await ref.read(liveActivityServiceProvider).requestMotionFitnessPermission();
    }

    await ref.read(pinnedVerseProvider.notifier).pinVerse(
          widget.verse,
          themeId: _selectedTheme.id,
        );

    if (!mounted) return;
    Navigator.of(context).pop(); // 바텀시트 닫기
  }

  Widget _buildPreview() {
    final bgColor = _selectedTheme.background;
    final textColor = _selectedTheme.textColor;
    final accentColor = _selectedTheme.accentColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: bgColor),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.verse.reference,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.verse.text,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                      height: 1.5,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Spacer(),
                      const Text('👣', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '0',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '걸음',
                        style: TextStyle(
                          fontSize: 9,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 드래그 핸들
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 제목
          Text(
            '말씀 동행을 시작해요',
            style: GoogleFonts.gowunBatang(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '잠금화면에 표시될 테마를 선택해 주세요',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // 테마 프리뷰
          _buildPreview(),
          const SizedBox(height: 20),
          // 테마 선택 팔레트
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: WidgetTheme.all.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final wt = WidgetTheme.all[index];
                final isSelected = wt.id == _selectedTheme.id;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedTheme = wt);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: wt.background,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.1),
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: isSelected
                        ? Icon(Icons.check, color: wt.textColor, size: 22)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          // 동행 시작 버튼
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _startSession(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                '동행 시작하기',
                style: GoogleFonts.gowunBatang(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // 나중에 설정 버튼
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '나중에 설정하기',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
