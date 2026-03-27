import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';
import '../models/verse.dart';
import '../providers/providers.dart';

/// 하단 시트 형태의 성경 말씀 선택기
class BiblePickerSheet extends ConsumerStatefulWidget {
  const BiblePickerSheet({super.key});

  @override
  ConsumerState<BiblePickerSheet> createState() => _BiblePickerSheetState();
}

class _BiblePickerSheetState extends ConsumerState<BiblePickerSheet> {
  int _step = 0; // 0: 권, 1: 장, 2: 절
  Book? _selectedBook;
  int? _selectedChapter;

  Future<List<Book>> _loadBooks() =>
      ref.read(bibleServiceProvider).getBooks();

  Future<int> _loadChapterCount() =>
      ref.read(bibleServiceProvider).getChapterCount(_selectedBook!.id);

  Future<List<Verse>> _loadVerses() => ref
      .read(bibleServiceProvider)
      .getVersesByChapter(_selectedBook!.id, _selectedChapter!);

  void _back() {
    setState(() {
      _step--;
      if (_step == 0) {
        _selectedBook = null;
        _selectedChapter = null;
      } else if (_step == 1) {
        _selectedChapter = null;
      }
    });
  }

  String _getStepTitle(AppLocalizations l10n) {
    if (_step == 0) return l10n.selectBook;
    if (_step == 1) return l10n.bookSelectChapter(_selectedBook!.name);
    return l10n.bookChapterSelectVerse(_selectedBook!.name, _selectedChapter!);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 핸들바
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 단계 타이틀 + 브레드크럼
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                if (_step > 0) ...[
                  // 이전 단계들 브레드크럼
                  GestureDetector(
                    onTap: _back,
                    child: Text(
                      _step == 2
                          ? '${_selectedBook!.name} >'
                          : l10n.bookBreadcrumb,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  if (_step == 2) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => setState(() {
                        _step = 1;
                        _selectedChapter = null;
                      }),
                      child: Text(
                        l10n.chapterBreadcrumb(_selectedChapter!),
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    _getStepTitle(l10n),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 본문
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: _step == 0
                    ? _BookSelector(
                        loadBooks: _loadBooks,
                        onSelect: (book) => setState(() {
                          _selectedBook = book;
                          _step = 1;
                        }),
                      )
                    : _step == 1
                        ? _ChapterSelector(
                            loadChapterCount: _loadChapterCount,
                            bookName: _selectedBook!.name,
                            onSelect: (ch) => setState(() {
                              _selectedChapter = ch;
                              _step = 2;
                            }),
                          )
                        : _VerseSelector(
                            loadVerses: _loadVerses,
                            onSelect: (verse) async {
                              await ref
                                  .read(pinnedVerseProvider.notifier)
                                  .pinVerse(verse);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(context)
                                          .verseSet(verse.reference),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
              ),
            ),
          ),
          // 하단 뒤로가기 버튼 (손이 닿기 쉬운 위치)
          if (_step > 0)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _back,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(
                      _step == 1
                          ? l10n.backToBookSelect
                          : l10n.backToChapterSelect,
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            const SafeArea(top: false, child: SizedBox(height: 12)),
        ],
      ),
    );
  }
}

// ─── 권 선택 (세로 리스트, 구약/신약 색 구분) ──────────────────────────────

class _BookSelector extends StatefulWidget {
  final Future<List<Book>> Function() loadBooks;
  final void Function(Book) onSelect;

  const _BookSelector({required this.loadBooks, required this.onSelect});

  @override
  State<_BookSelector> createState() => _BookSelectorState();
}

class _BookSelectorState extends State<_BookSelector> {
  late final Future<List<Book>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loadBooks();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return FutureBuilder<List<Book>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(l10n.errorMsg(snapshot.error.toString())));
        }
        final books = snapshot.data ?? [];
        final oldT = books.where((b) => b.isOldTestament).toList();
        final newT = books.where((b) => b.isNewTestament).toList();

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            _BookGroupHeader(count: oldT.length, isOld: true),
            const SizedBox(height: 6),
            ...oldT.map((b) => _BookTile(
                  book: b,
                  isOld: true,
                  onTap: () => widget.onSelect(b),
                )),
            const SizedBox(height: 16),
            _BookGroupHeader(count: newT.length, isOld: false),
            const SizedBox(height: 6),
            ...newT.map((b) => _BookTile(
                  book: b,
                  isOld: false,
                  onTap: () => widget.onSelect(b),
                )),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

class _BookGroupHeader extends StatelessWidget {
  final int count;
  final bool isOld;

  const _BookGroupHeader({required this.count, required this.isOld});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = isOld ? l10n.oldTestament : l10n.newTestament;
    final color = isOld ? const Color(0xFFB45309) : const Color(0xFF1D4ED8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$title  ${l10n.booksCount(count)}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  final Book book;
  final bool isOld;
  final VoidCallback onTap;

  const _BookTile(
      {required this.book, required this.isOld, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isOld ? const Color(0xFFB45309) : const Color(0xFF1D4ED8);
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              book.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

// ─── 장 선택 (그리드 5열) ─────────────────────────────────────────────────

class _ChapterSelector extends StatefulWidget {
  final Future<int> Function() loadChapterCount;
  final String bookName;
  final void Function(int) onSelect;

  const _ChapterSelector({
    required this.loadChapterCount,
    required this.bookName,
    required this.onSelect,
  });

  @override
  State<_ChapterSelector> createState() => _ChapterSelectorState();
}

class _ChapterSelectorState extends State<_ChapterSelector> {
  late final Future<int> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loadChapterCount();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return FutureBuilder<int>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(l10n.errorMsg(snapshot.error.toString())));
        }
        final count = snapshot.data ?? 0;
        if (count == 0) {
          return Center(child: Text(l10n.noChapterInfo));
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemCount: count,
          itemBuilder: (context, index) {
            final chapter = index + 1;
            return InkWell(
              onTap: () => widget.onSelect(chapter),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.13),
                  ),
                ),
                child: Text(
                  '$chapter',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── 절 선택 (그리드 5열, 탭 시 미리보기) ────────────────────────────────

class _VerseSelector extends StatefulWidget {
  final Future<List<Verse>> Function() loadVerses;
  final Future<void> Function(Verse) onSelect;

  const _VerseSelector({required this.loadVerses, required this.onSelect});

  @override
  State<_VerseSelector> createState() => _VerseSelectorState();
}

class _VerseSelectorState extends State<_VerseSelector> {
  late final Future<List<Verse>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loadVerses();
  }

  void _showPreview(BuildContext context, Verse verse) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              verse.reference,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              verse.text,
              style: GoogleFonts.notoSerif(
                fontSize: 16,
                height: 1.8,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onSelect(verse);
                },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(l10n.setThisVerse),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return FutureBuilder<List<Verse>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(l10n.errorMsg(snapshot.error.toString())));
        }
        final verses = snapshot.data ?? [];
        if (verses.isEmpty) {
          return Center(child: Text(l10n.noVerseInfo));
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemCount: verses.length,
          itemBuilder: (context, index) {
            final verse = verses[index];
            return InkWell(
              onTap: () => _showPreview(context, verse),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.13),
                  ),
                ),
                child: Text(
                  '${verse.verse}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
