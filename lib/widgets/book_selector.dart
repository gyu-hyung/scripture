import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/book.dart';

/// Testament color constants
const Color oldTestamentColor = Color(0xFFB45309);
const Color newTestamentColor = Color(0xFF1D4ED8);

// ─── 권 선택 (세로 리스트, 구약/신약 색 구분) ──────────────────────────────

class BookSelector extends StatefulWidget {
  final Future<List<Book>> Function() loadBooks;
  final void Function(Book) onSelect;

  const BookSelector({super.key, required this.loadBooks, required this.onSelect});

  @override
  State<BookSelector> createState() => _BookSelectorState();
}

class _BookSelectorState extends State<BookSelector> {
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
            BookGroupHeader(count: oldT.length, isOld: true),
            const SizedBox(height: 6),
            ...oldT.map((b) => BookTile(
                  book: b,
                  isOld: true,
                  onTap: () => widget.onSelect(b),
                )),
            const SizedBox(height: 16),
            BookGroupHeader(count: newT.length, isOld: false),
            const SizedBox(height: 6),
            ...newT.map((b) => BookTile(
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

class BookGroupHeader extends StatelessWidget {
  final int count;
  final bool isOld;

  const BookGroupHeader({super.key, required this.count, required this.isOld});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = isOld ? l10n.oldTestament : l10n.newTestament;
    final color = isOld ? oldTestamentColor : newTestamentColor;

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

class BookTile extends StatelessWidget {
  final Book book;
  final bool isOld;
  final VoidCallback onTap;

  const BookTile(
      {super.key, required this.book, required this.isOld, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isOld ? oldTestamentColor : newTestamentColor;
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
