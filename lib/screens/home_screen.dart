import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/translation.dart';
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
    final pinned = await widgetService.getPinnedVerse();
    if (pinned == null && mounted) _openPicker();
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
    final l10n = AppLocalizations.of(context);
    final pinnedAsync = ref.watch(pinnedVerseProvider);
    final translationAsync = ref.watch(selectedTranslationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          translationAsync.when(
            data: (translation) => _TranslationDropdown(
              current: translation,
              onChanged: (t) => ref
                  .read(selectedTranslationProvider.notifier)
                  .setTranslation(t),
            ),
            loading: () => const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, st) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: l10n.selectVerseTooltip,
            onPressed: _openPicker,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  children: [
                    _SectionLabel(
                      label: l10n.pinnedVerseTitle,
                      icon: Icons.push_pin_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 10),
                    _VerseCard(
                      verseAsync: pinnedAsync,
                      emptyMessage: l10n.noPinnedVerse,
                      onEmpty: _openPicker,
                      onUnpin: () =>
                          ref.read(pinnedVerseProvider.notifier).unpinVerse(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _openPicker,
                  icon: const Icon(Icons.menu_book_rounded),
                  label: Text(l10n.selectVerse),
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

// ─── 번역본 드롭다운 (언어별 그룹) ─────────────────────────────────────────

/// 언어 코드 → 표시 이름
const _languageNames = {
  'ko': '한국어',
  'en': 'English',
  'ja': '日本語',
  'zh': '中文',
  'es': 'Español',
  'pt': 'Português',
  'de': 'Deutsch',
  'fr': 'Français',
  'ru': 'Русский',
  'ar': 'العربية',
  'id': 'Indonesia',
  'vi': 'Tiếng Việt',
};

class _TranslationDropdown extends StatelessWidget {
  final Translation current;
  final void Function(Translation) onChanged;

  const _TranslationDropdown({
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 번들된 번역본만 표시, 언어 순서 유지
    final bundled = Translation.bundled;

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Translation>(
          value: current,
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          // AppBar에 표시할 선택된 값 (shortName만)
          selectedItemBuilder: (_) => bundled
              .map((t) => Center(child: Text(t.shortName)))
              .toList(),
          // 드롭다운 아이템 (언어별 그룹 헤더 + 번역본)
          items: _buildGroupedItems(bundled, theme),
          onChanged: (t) {
            if (t != null && t != current) onChanged(t);
          },
        ),
      ),
    );
  }

  List<DropdownMenuItem<Translation>> _buildGroupedItems(
    List<Translation> translations,
    ThemeData theme,
  ) {
    final items = <DropdownMenuItem<Translation>>[];

    // 언어별로 그룹핑
    final grouped = <String, List<Translation>>{};
    for (final t in translations) {
      grouped.putIfAbsent(t.language, () => []).add(t);
    }

    // 언어별로 헤더 + 번역본 아이템 추가
    for (final entry in grouped.entries) {
      final langCode = entry.key;
      final langTranslations = entry.value;
      final langName = _languageNames[langCode] ?? langCode.toUpperCase();

      // 여러 번역본이 있을 때만 언어 헤더 표시
      if (langTranslations.length > 1 || grouped.length > 1) {
        items.add(
          DropdownMenuItem<Translation>(
            enabled: false,
            value: Translation(
              id: '__header_$langCode',
              language: langCode,
              name: langName,
              shortName: langName,
              dbFileName: '',
            ),
            child: Text(
              langName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      }

      for (final t in langTranslations) {
        final isSelected = t.id == current.id;
        items.add(
          DropdownMenuItem<Translation>(
            value: t,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 8),
                Icon(
                  isSelected
                      ? Icons.check_rounded
                      : Icons.circle_outlined,
                  size: 14,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.shortName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      t.name,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.45),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                if (!t.isBundled) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.download_rounded,
                    size: 13,
                    color: theme.colorScheme.tertiary,
                  ),
                ],
              ],
            ),
          ),
        );
      }
    }

    return items;
  }
}

// ─── 섹션 레이블 ──────────────────────────────────────────────────────────

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

// ─── 말씀 카드 ────────────────────────────────────────────────────────────

class _VerseCard extends StatelessWidget {
  final AsyncValue<Verse?> verseAsync;
  final String emptyMessage;
  final VoidCallback? onEmpty;
  final VoidCallback? onUnpin;
  const _VerseCard({
    required this.verseAsync,
    required this.emptyMessage,
    this.onEmpty,
    this.onUnpin,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return verseAsync.when(
      data: (verse) {
        if (verse == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: 48,
                  color: color.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    height: 1.7,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (onEmpty != null) ...[
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: onEmpty,
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: Text(l10n.selectVerse),
                  ),
                ],
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.format_quote_rounded,
                size: 26,
                color: color.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 18),
              Text(
                verse.text,
                style: GoogleFonts.notoSerif(
                  fontSize: 17,
                  height: 1.9,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: onUnpin,
                  icon: const Icon(Icons.push_pin_outlined, size: 14),
                  label: Text(l10n.unpin),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    textStyle: const TextStyle(fontSize: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => SizedBox(
        height: 140,
        child: Center(
          child: CircularProgressIndicator(color: color, strokeWidth: 2),
        ),
      ),
      error: (e, st) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          l10n.errorMsg(e.toString()),
          style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
        ),
      ),
    );
  }
}
