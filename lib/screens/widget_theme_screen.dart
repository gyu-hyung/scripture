import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../models/verse.dart';
import '../models/widget_theme.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';

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

    if (confirmed != true || !mounted) return;

    await ref.read(pinnedVerseProvider.notifier).pinVerse(
          widget.verse,
          themeId: _selectedTheme.id,
        );
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ── 프리뷰 위젯 (실제 Live Activity 잠금화면 바 레이아웃과 동일) ────
  Widget _buildPreview(ThemeData _) {
    final bgColor = _selectedTheme.background;
    final textColor = _selectedTheme.textColor;
    final accentColor = _selectedTheme.accentColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 실제 콘텐츠
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 상단: 참조 + 본문 (내용이 길면 얘만 축소됨)
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        // FittedBox 안에서도 텍스트가 가로를 꽉 채우도록 가상 너비 설정
                        width: MediaQuery.of(context).size.width - 48 - 32,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.verse.reference,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.verse.text,
                              style: GoogleFonts.gowunBatang(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 하단 바: 얘는 축소되지 않고 무조건 우측 끝에 붙음
                  Row(
                    children: [
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                onPressed: () => _showSoftPrompt(context, theme, l10n),
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
