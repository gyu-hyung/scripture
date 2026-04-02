import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

// ─── 장 선택 (그리드 5열) ─────────────────────────────────────────────────

class ChapterSelector extends StatefulWidget {
  final Future<int> Function() loadChapterCount;
  final String bookName;
  final void Function(int) onSelect;

  const ChapterSelector({
    super.key,
    required this.loadChapterCount,
    required this.bookName,
    required this.onSelect,
  });

  @override
  State<ChapterSelector> createState() => _ChapterSelectorState();
}

class _ChapterSelectorState extends State<ChapterSelector> {
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
