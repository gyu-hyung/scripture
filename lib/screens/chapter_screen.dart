import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/verse.dart';
import '../providers/providers.dart';
import '../widgets/bible_navigator_sheet.dart';
import 'widget_theme_screen.dart';

class ChapterScreen extends ConsumerStatefulWidget {
  final int bookId;
  final String bookName;
  final int chapter;
  final int? highlightVerse; // 강조할 절 번호

  const ChapterScreen({
    super.key,
    required this.bookId,
    required this.bookName,
    required this.chapter,
    this.highlightVerse,
  });

  @override
  ConsumerState<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends ConsumerState<ChapterScreen> {
  // ── 검색 상태 ────────────────────────────────────────────────────
  bool _isSearchMode = false;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  List<Verse> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  // ── 본문 상태 ────────────────────────────────────────────────────
  final _scrollController = ScrollController();
  late Future<List<Verse>> _chapterFuture;
  int? _selectedVerseNum; // 현재 선택된 절 번호
  Verse? _selectedVerse; // 현재 선택된 절 객체
  bool _hasInitialScrolled = false; // 초기 스크롤 완료 여부

  @override
  void initState() {
    super.initState();
    _selectedVerseNum = widget.highlightVerse;
    _chapterFuture = _loadChapter();
  }

  Future<List<Verse>> _loadChapter() {
    return ref
        .read(bibleServiceProvider)
        .getVersesByChapter(widget.bookId, widget.chapter);
  }

  void _scrollToVerse() {
    if (widget.highlightVerse == null || _hasInitialScrolled) return;
    if (!_scrollController.hasClients) return;

    _hasInitialScrolled = true;

    final maxExtent = _scrollController.position.maxScrollExtent;
    final offset = ((widget.highlightVerse! - 1) * 72.0).clamp(0.0, maxExtent);
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── 검색 모드 전환 ───────────────────────────────────────────────
  void _enterSearchMode() {
    setState(() => _isSearchMode = true);
    Future.delayed(const Duration(milliseconds: 80), () {
      _searchFocus.requestFocus();
    });
  }

  void _exitSearchMode() {
    setState(() {
      _isSearchMode = false;
      _searchResults = [];
      _isSearching = false;
    });
    _searchController.clear();
    _searchFocus.unfocus();
  }

  // ── 검색 실행 (디바운스 300ms) ───────────────────────────────────
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await ref
          .read(bibleServiceProvider)
          .searchVerses(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  // ── 검색 결과 → 책별 그룹핑 ─────────────────────────────────────
  Map<String, List<Verse>> _groupByBook(List<Verse> verses) {
    final map = <String, List<Verse>>{};
    for (final v in verses) {
      final key = v.bookName ?? '';
      map.putIfAbsent(key, () => []).add(v);
    }
    return map;
  }

  // ── 검색 결과에서 구절 선택 → 해당 ChapterScreen으로 이동 ────────
  void _onSearchVerseSelected(Verse verse) {
    _exitSearchMode();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChapterScreen(
          bookId: verse.bookId,
          bookName: verse.bookName ?? '',
          chapter: verse.chapter,
          highlightVerse: verse.verse,
        ),
      ),
    );
  }

  // ── 책/장/절 네비게이터 열기 ──────────────────────────────────────
  Future<void> _openNavigator() async {
    final result = await showModalBottomSheet<BibleNavResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BibleNavigatorSheet(
        initialBookId: widget.bookId,
        initialChapter: widget.chapter,
        initialVerse: widget.highlightVerse ?? 1,
      ),
    );
    if (result == null || !mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChapterScreen(
          bookId: result.book.id,
          bookName: result.book.name,
          chapter: result.chapter,
          highlightVerse: result.verse,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final l10n = AppLocalizations.of(context);

    final pinnedVerseAsync = ref.watch(pinnedVerseProvider);
    final isAlreadyPinned = pinnedVerseAsync.value?.id == _selectedVerse?.id;
    final showPinButton = _selectedVerse != null && !isAlreadyPinned;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      extendBody: true,
      appBar: _buildAppBar(theme, color, l10n),
      body: _isSearchMode
          ? _buildSearchBody(theme, color, l10n)
          : _buildChapterBody(theme, color, l10n),
      bottomNavigationBar: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        reverseDuration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
        child: showPinButton
            ? _buildBottomBar(theme, color, l10n)
            : const SizedBox.shrink(key: ValueKey('empty_bottom_bar')),
      ),
    );
  }

  // ── 하단 고정 바 ─────────────────────────────────────────────────
  Widget _buildBottomBar(ThemeData theme, Color color, AppLocalizations l10n) {
    return Container(
      key: const ValueKey('pin_bottom_bar'),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: ElevatedButton(
        onPressed: () {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WidgetThemeScreen(verse: _selectedVerse!),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 6,
          shadowColor: color.withValues(alpha: 0.4),
        ),
        child: Text(
          l10n.pinThisVerse,
          style: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────
  AppBar _buildAppBar(ThemeData theme, Color color, AppLocalizations l10n) {
    if (_isSearchMode) {
      return AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _exitSearchMode,
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          onChanged: _onSearchChanged,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: l10n.searchBible,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            border: InputBorder.none,
            isDense: true,
          ),
          textInputAction: TextInputAction.search,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: _exitSearchMode,
            ),
        ],
      );
    }

    // 기본 모드
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: GestureDetector(
        onTap: _openNavigator,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.bookName} ${l10n.chapterLabel(widget.chapter)}',
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.arrow_drop_down_rounded, size: 20, color: color),
            ],
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.search_rounded, color: color),
          onPressed: _enterSearchMode,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── 장 본문 ──────────────────────────────────────────────────────
  Widget _buildChapterBody(
    ThemeData theme,
    Color color,
    AppLocalizations l10n,
  ) {
    return FutureBuilder<List<Verse>>(
      future: _chapterFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: color, strokeWidth: 2),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              l10n.errorMsg(snap.error.toString()),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          );
        }
        final verses = snap.data ?? [];

        // 초기 로드 시 highlightVerse가 있으면 _selectedVerse 설정
        if (_selectedVerseNum != null && _selectedVerse == null) {
          final found = verses.cast<Verse?>().firstWhere(
            (v) => v?.verse == _selectedVerseNum,
            orElse: () => null,
          );
          if (found != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedVerse = found);
            });
          }
        }

        // 데이터 로드 완료 후 하이라이트 절로 스크롤 (최초 1회만)
        if (widget.highlightVerse != null && !_hasInitialScrolled) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToVerse());
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: verses.length,
          itemBuilder: (context, i) {
            final v = verses[i];
            final isSelected = v.verse == _selectedVerseNum;
            return _VerseRow(
              verse: v,
              isHighlighted: isSelected,
              highlightColor: color,
              theme: theme,
              onTap: () {
                setState(() {
                  if (_selectedVerseNum == v.verse) {
                    _selectedVerseNum = null;
                    _selectedVerse = null;
                  } else {
                    _selectedVerseNum = v.verse;
                    _selectedVerse = v;
                  }
                });
              },
            );
          },
        );
      },
    );
  }

  // ── 검색 결과 ────────────────────────────────────────────────────
  Widget _buildSearchBody(ThemeData theme, Color color, AppLocalizations l10n) {
    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_rounded,
              size: 56,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.enterSearchTerm,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    if (_isSearching) {
      return Center(
        child: CircularProgressIndicator(color: color, strokeWidth: 2),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          l10n.noSearchResults,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            fontSize: 15,
          ),
        ),
      );
    }

    final grouped = _groupByBook(_searchResults);
    final keyword = _searchController.text.trim();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Text(
            l10n.searchResultCount(_searchResults.length),
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),
        ...grouped.entries.map((entry) {
          final bookName = entry.key;
          final verseList = entry.value;
          return _BookAccordion(
            bookName: bookName,
            verses: verseList,
            keyword: keyword,
            theme: theme,
            color: color,
            onVerseTap: _onSearchVerseSelected,
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── 절 한 줄 ────────────────────────────────────────────────────────────────

class _VerseRow extends StatelessWidget {
  final Verse verse;
  final bool isHighlighted;
  final Color highlightColor;
  final ThemeData theme;
  final VoidCallback onTap;

  const _VerseRow({
    required this.verse,
    required this.isHighlighted,
    required this.highlightColor,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isHighlighted
              ? highlightColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHighlighted
                ? highlightColor.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '${verse.verse}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isHighlighted
                      ? highlightColor
                      : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  height: 1.9,
                ),
              ),
            ),
            Expanded(
              child: Text(
                verse.text,
                style: GoogleFonts.notoSerif(
                  fontSize: 16,
                  height: 1.9,
                  color: theme.colorScheme.onSurface,
                  fontWeight: isHighlighted
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 책별 아코디언 ──────────────────────────────────────────────────────────

class _BookAccordion extends StatelessWidget {
  final String bookName;
  final List<Verse> verses;
  final String keyword;
  final ThemeData theme;
  final Color color;
  final void Function(Verse) onVerseTap;

  const _BookAccordion({
    required this.bookName,
    required this.verses,
    required this.keyword,
    required this.theme,
    required this.color,
    required this.onVerseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        childrenPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Expanded(
              child: Text(
                bookName,
                style: GoogleFonts.notoSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${verses.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        iconColor: color,
        collapsedIconColor: theme.colorScheme.onSurface.withValues(alpha: 0.35),
        children: verses.map((v) {
          return InkWell(
            onTap: () => onVerseTap(v),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 참조 (장:절)
                  SizedBox(
                    width: 52,
                    child: Text(
                      '${v.chapter}:${v.verse}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _HighlightedText(
                      text: v.text,
                      keyword: keyword,
                      baseStyle: GoogleFonts.notoSerif(
                        fontSize: 14,
                        height: 1.7,
                        color: theme.colorScheme.onSurface,
                      ),
                      highlightStyle: GoogleFonts.notoSerif(
                        fontSize: 14,
                        height: 1.7,
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── 검색어 하이라이팅 텍스트 ──────────────────────────────────────────────

class _HighlightedText extends StatelessWidget {
  final String text;
  final String keyword;
  final TextStyle baseStyle;
  final TextStyle highlightStyle;

  const _HighlightedText({
    required this.text,
    required this.keyword,
    required this.baseStyle,
    required this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (keyword.isEmpty) return Text(text, style: baseStyle);

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();
    int start = 0;

    while (true) {
      final idx = lowerText.indexOf(lowerKeyword, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: baseStyle));
      }
      spans.add(
        TextSpan(
          text: text.substring(idx, idx + keyword.length),
          style: highlightStyle,
        ),
      );
      start = idx + keyword.length;
    }

    return RichText(text: TextSpan(children: spans));
  }
}
