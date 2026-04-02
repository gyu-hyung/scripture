import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';
import '../providers/bible_provider.dart';

/// 책 | 장 | 절 3컬럼 네비게이터 결과
class BibleNavResult {
  final Book book;
  final int chapter;
  final int verse;
  const BibleNavResult({
    required this.book,
    required this.chapter,
    required this.verse,
  });
}

/// [bookId], [chapter] 로 초기 선택을 지정할 수 있다.
class BibleNavigatorSheet extends ConsumerStatefulWidget {
  final int initialBookId;
  final int initialChapter;
  final int initialVerse;

  const BibleNavigatorSheet({
    super.key,
    required this.initialBookId,
    required this.initialChapter,
    this.initialVerse = 1,
  });

  @override
  ConsumerState<BibleNavigatorSheet> createState() =>
      _BibleNavigatorSheetState();
}

class _BibleNavigatorSheetState extends ConsumerState<BibleNavigatorSheet> {
  // ── 데이터 ───────────────────────────────────────────────────────
  List<Book> _books = [];
  int _chapterCount = 0;
  int _verseCount = 0;

  // ── 선택 상태 ────────────────────────────────────────────────────
  late Book _selectedBook;
  late int _selectedChapter;
  int? _selectedVerse;

  // ── 스크롤 컨트롤러 ──────────────────────────────────────────────
  final _bookScroll = ScrollController();
  final _chapScroll = ScrollController();
  final _verseScroll = ScrollController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedChapter = widget.initialChapter;
    _selectedVerse = null; // 초기 열릴 때부터 선택 해제
    _init();
  }

  Future<void> _init() async {
    final svc = ref.read(bibleServiceProvider);
    final books = await svc.getBooks();
    if (!mounted || books.isEmpty) return;

    final book = books.firstWhere(
      (b) => b.id == widget.initialBookId,
      orElse: () => books.first,
    );
    final chapCount = await svc.getChapterCount(book.id);
    final verseCount = chapCount > 0
        ? await svc.getVerseCount(book.id, _selectedChapter)
        : 0;

    if (!mounted) return;
    setState(() {
      _books = books;
      _selectedBook = book;
      _chapterCount = chapCount;
      _verseCount = verseCount;
      _loading = false;
    });

    // 초기 선택 항목으로 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected();
    });
  }

  void _scrollToSelected() {
    final bookIdx = _books.indexWhere((b) => b.id == _selectedBook.id);
    if (bookIdx >= 0 && _bookScroll.hasClients) {
      _bookScroll.animateTo(
        (bookIdx * 52.0).clamp(0.0, _bookScroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    if (_chapScroll.hasClients && _selectedChapter > 1) {
      _chapScroll.animateTo(
        ((_selectedChapter - 1) * 44.0).clamp(
          0.0,
          _chapScroll.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    if (_verseScroll.hasClients &&
        _selectedVerse != null &&
        _selectedVerse! > 1) {
      _verseScroll.animateTo(
        ((_selectedVerse! - 1) * 44.0).clamp(
          0.0,
          _verseScroll.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _onBookSelected(Book book) async {
    final svc = ref.read(bibleServiceProvider);
    final chapCount = await svc.getChapterCount(book.id);
    final newChap = 1;
    final verseCount = chapCount > 0
        ? await svc.getVerseCount(book.id, newChap)
        : 0;
    if (!mounted) return;
    setState(() {
      _selectedBook = book;
      _chapterCount = chapCount;
      _selectedChapter = newChap;
      _verseCount = verseCount;
      _selectedVerse = null; // 책 바꿀 땐 절 선택 해제
    });
    // 장·절 리스트를 맨 위로
    if (_chapScroll.hasClients) _chapScroll.jumpTo(0);
    if (_verseScroll.hasClients) _verseScroll.jumpTo(0);
  }

  Future<void> _onChapterSelected(int chapter) async {
    final svc = ref.read(bibleServiceProvider);
    final verseCount = await svc.getVerseCount(_selectedBook.id, chapter);
    if (!mounted) return;
    setState(() {
      _selectedChapter = chapter;
      _verseCount = verseCount;
      _selectedVerse = null; // 장 바꿀 땐 절 선택 해제
    });
    if (_verseScroll.hasClients) _verseScroll.jumpTo(0);
  }

  void _onVerseSelected(int verse) {
    Navigator.of(context).pop(
      BibleNavResult(
        book: _selectedBook,
        chapter: _selectedChapter,
        verse: verse,
      ),
    );
  }

  @override
  void dispose() {
    _bookScroll.dispose();
    _chapScroll.dispose();
    _verseScroll.dispose();
    super.dispose();
  }

  // ── 구약/신약 섹션 구분 정보 ─────────────────────────────────────
  static const _sections = <String, List<int>>{
    '모세오경': [1, 2, 3, 4, 5],
    '역사서': [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
    '시가서': [18, 19, 20, 21, 22],
    '대선지서': [23, 24, 25, 26, 27],
    '소선지서': [28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39],
    '복음서': [40, 41, 42, 43],
    '역사서(신)': [44],
    '바울서신': [45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57],
    '공동서신': [58, 59, 60, 61, 62, 63, 64, 65],
    '예언서(신)': [66],
  };

  String? _sectionForBook(int bookId) {
    for (final entry in _sections.entries) {
      if (entry.value.contains(bookId)) return entry.key;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── 핸들바 ──────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // ── 헤더 ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
            child: Row(
              children: [
                Text(
                  '성경 이동',
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── 컬럼 헤더 ────────────────────────────────────────────
          Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _ColHeader('책', color: color),
                _vertDivider(theme),
                _ColHeader('장', flex: 1, color: color),
                _vertDivider(theme),
                _ColHeader('절', flex: 1, color: color),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── 3컬럼 리스트 ─────────────────────────────────────────
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: color,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 책 컬럼 (flex 3)
                      Expanded(flex: 3, child: _buildBookColumn(theme, color)),
                      _vertDivider(theme),
                      // 장 컬럼 (flex 2)
                      Expanded(
                        flex: 2,
                        child: _buildChapterColumn(theme, color),
                      ),
                      _vertDivider(theme),
                      // 절 컬럼 (flex 2)
                      Expanded(flex: 2, child: _buildVerseColumn(theme, color)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _vertDivider(ThemeData theme) => Container(
    width: 1,
    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
  );

  // ── 책 컬럼 ──────────────────────────────────────────────────────
  Widget _buildBookColumn(ThemeData theme, Color color) {
    final items = <Widget>[];
    String? currentSection;

    for (final book in _books) {
      final section = _sectionForBook(book.id);
      if (section != currentSection) {
        currentSection = section;
        items.add(_SectionHeader(label: section ?? '', theme: theme));
      }
      final isSelected = book.id == _selectedBook.id;
      final isNewTestament = book.id >= 40;
      final abbreviationColor = isNewTestament 
          ? Colors.red.withValues(alpha: 0.6) 
          : Colors.blue.withValues(alpha: 0.6);

      items.add(
        InkWell(
          onTap: () => _onBookSelected(book),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: isSelected
                ? color.withValues(alpha: 0.10)
                : Colors.transparent,
            child: Row(
              children: [
                // 약자
                SizedBox(
                  width: 24,
                  child: Text(
                    book.abbreviation,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.red
                          : abbreviationColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    book.name,
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected ? color : theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.chevron_right_rounded, size: 16, color: color),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(controller: _bookScroll, children: items);
  }

  // ── 장 컬럼 ──────────────────────────────────────────────────────
  Widget _buildChapterColumn(ThemeData theme, Color color) {
    if (_chapterCount == 0) {
      return Center(
        child: Text(
          '데이터 없음',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _chapScroll,
      itemCount: _chapterCount,
      itemBuilder: (_, i) {
        final ch = i + 1;
        final isSelected = ch == _selectedChapter;
        return InkWell(
          onTap: () => _onChapterSelected(ch),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 44,
            alignment: Alignment.center,
            color: isSelected
                ? color.withValues(alpha: 0.10)
                : Colors.transparent,
            child: Text(
              '$ch장',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? color : theme.colorScheme.onSurface,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── 절 컬럼 ──────────────────────────────────────────────────────
  Widget _buildVerseColumn(ThemeData theme, Color color) {
    if (_verseCount == 0) {
      return Center(
        child: Text(
          '—',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _verseScroll,
      itemCount: _verseCount,
      itemBuilder: (_, i) {
        final v = i + 1;
        final isSelected = v == _selectedVerse;
        return InkWell(
          onTap: () => _onVerseSelected(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 44,
            alignment: Alignment.center,
            color: isSelected
                ? color.withValues(alpha: 0.10)
                : Colors.transparent,
            child: Text(
              '$v절',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? color : theme.colorScheme.onSurface,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── 헬퍼 위젯들 ─────────────────────────────────────────────────────────────

class _ColHeader extends StatelessWidget {
  final String label;
  final int flex;
  final Color color;
  const _ColHeader(this.label, {this.flex = 3, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final ThemeData theme;
  const _SectionHeader({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
