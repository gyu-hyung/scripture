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
  // 사용자가 선택한 사진 (custom_photo 테마 선택 시에만 non-null)
  File? _customPhotoFile;

  // ── 사진 선택 ──────────────────────────────────────────────────────
  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,  // 라이브 액티비티 메모리 제한을 위해 더 축소
      maxHeight: 600,
      imageQuality: 60, // 압축률 강화
    );
    if (picked == null || !mounted) return;
    setState(() {
      _customPhotoFile = File(picked.path);
      _selectedTheme = WidgetTheme.customPhoto;
    });
  }

  // ── 소프트 프롬프트 → 세션 시작 ────────────────────────────────────
  Future<void> _showSoftPrompt(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) async {
    // 사진 테마를 선택했지만 아직 사진을 고르지 않은 경우 사진 먼저 선택
    if (_selectedTheme.id == AppConstants.themeCustomPhoto &&
        _customPhotoFile == null) {
      await _pickPhoto();
      if (_customPhotoFile == null || !mounted) return;
    }

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

    // 사진 테마인 경우 App Group 컨테이너에 먼저 저장
    if (_selectedTheme.id == AppConstants.themeCustomPhoto &&
        _customPhotoFile != null) {
      final Uint8List bytes = await _customPhotoFile!.readAsBytes();
      await ref.read(widgetServiceProvider).saveCustomPhoto(bytes);
    }

    await ref.read(pinnedVerseProvider.notifier).pinVerse(
          widget.verse,
          themeId: _selectedTheme.id,
        );
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ── 프리뷰 위젯 (실제 Live Activity 잠금화면 바 레이아웃과 동일) ────
  Widget _buildPreview(ThemeData _) {
    final isPhoto = _selectedTheme.id == AppConstants.themeCustomPhoto;
    final hasPhoto = _customPhotoFile != null;
    final bgColor = _selectedTheme.background;
    final textColor = (isPhoto && hasPhoto) ? Colors.white : _selectedTheme.textColor;
    final accentColor = (isPhoto && hasPhoto) ? Colors.white.withValues(alpha: 0.85) : _selectedTheme.accentColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 88,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── 배경 ──────────────────────────────────────────────────
            if (isPhoto && hasPhoto)
              Positioned.fill(
                child: Image.file(
                  _customPhotoFile!,
                  fit: BoxFit.cover,
                ),
              )
            else
              Positioned.fill(child: ColoredBox(color: bgColor)),

            // 사진 위 어두운 오버레이 (텍스트 가독성)
            if (isPhoto && hasPhoto)
              Positioned.fill(
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
              ),

            // ── 콘텐츠 (ScriptureLiveActivityLockView와 동일 구조) ────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 좌측: 참조 + 본문
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        const SizedBox(height: 3),
                        Text(
                          widget.verse.text,
                          style: GoogleFonts.gowunBatang(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 우측: 걸음 수 플레이스홀더
                  SizedBox(
                    width: 52,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('👣', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(
                          '0',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        Text(
                          '걸음',
                          style: TextStyle(
                            fontSize: 9,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
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
    final isPhoto = wt.id == AppConstants.themeCustomPhoto;

    return GestureDetector(
      onTap: () async {
        if (isPhoto) {
          await _pickPhoto();
        } else {
          setState(() => _selectedTheme = wt);
        }
      },
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isPhoto ? (_customPhotoFile != null ? null : theme.colorScheme.surfaceContainerHighest) : wt.background,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.15),
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
            child: isPhoto
                ? _buildPhotoCircle(isSelected, wt, theme)
                : isSelected
                    ? Icon(Icons.check, color: wt.textColor, size: 24)
                    : null,
          ),
          const SizedBox(height: 8),
          Text(
            wt.localizedName(l10n),
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCircle(
      bool isSelected, WidgetTheme wt, ThemeData theme) {
    if (_customPhotoFile != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_customPhotoFile!, fit: BoxFit.cover),
          if (isSelected)
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Icon(Icons.check, color: Colors.white, size: 24),
            ),
        ],
      );
    }
    // 아직 사진을 선택하지 않은 상태
    return Icon(
      Icons.add_photo_alternate_rounded,
      color: theme.colorScheme.primary,
      size: 28,
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
        children: [
          const SizedBox(height: 40),
          // 프리뷰
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildPreview(theme),
          ),
          const Spacer(),
          // 테마 선택 리스트
          SizedBox(
            height: 120,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: WidgetTheme.all.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final wt = WidgetTheme.all[index];
                final isSelected = wt.id == _selectedTheme.id;
                return _buildThemeItem(wt, isSelected, theme, l10n);
              },
            ),
          ),
          const SizedBox(height: 24),
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
