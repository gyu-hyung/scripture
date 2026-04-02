import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../models/verse.dart';
import '../providers/providers.dart';
import '../widgets/book_selector.dart';
import '../widgets/chapter_selector.dart';
import '../widgets/verse_selector.dart';

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
                    ? BookSelector(
                        loadBooks: _loadBooks,
                        onSelect: (book) => setState(() {
                          _selectedBook = book;
                          _step = 1;
                        }),
                      )
                    : _step == 1
                        ? ChapterSelector(
                            loadChapterCount: _loadChapterCount,
                            bookName: _selectedBook!.name,
                            onSelect: (ch) => setState(() {
                              _selectedChapter = ch;
                              _step = 2;
                            }),
                          )
                        : VerseSelector(
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
