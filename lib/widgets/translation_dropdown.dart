import 'package:flutter/material.dart';
import '../models/translation.dart';

class TranslationDropdown extends StatelessWidget {
  final Translation current;
  final void Function(Translation) onChanged;

  const TranslationDropdown({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allTranslations = Translation.all;

    // 언어별로 그룹핑
    final grouped = <String, List<Translation>>{};
    for (final t in allTranslations) {
      grouped.putIfAbsent(t.language, () => []).add(t);
    }

    // 헤더를 포함한 전체 아이템 리스트 생성 (인덱스 동기화용)
    final displayItems = <Translation>[];
    for (final entry in grouped.entries) {
      final langCode = entry.key;
      final langTranslations = entry.value;
      if (langTranslations.length > 1 || grouped.length > 1) {
        final langName = Translation.languageNames[langCode] ?? langCode.toUpperCase();
        displayItems.add(Translation(
          id: '__header_$langCode',
          language: langCode,
          name: langName,
          shortName: langName,
          dbFileName: '',
        ));
      }
      displayItems.addAll(langTranslations);
    }

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
          // AppBar에 표시할 선택된 값 (인덱스 일치 필수)
          selectedItemBuilder: (_) => displayItems.map((t) {
            return Center(child: Text(t.shortName));
          }).toList(),
          items: displayItems.map((t) {
            final isHeader = t.id.startsWith('__header_');
            if (isHeader) {
              return DropdownMenuItem<Translation>(
                enabled: false,
                value: t,
                child: Text(
                  t.name,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            }

            final isSelected = t.id == current.id;
            return DropdownMenuItem<Translation>(
              value: t,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 8),
                  Icon(
                    isSelected ? Icons.check_rounded : Icons.circle_outlined,
                    size: 14,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          t.shortName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.45),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
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
            );
          }).toList(),
          onChanged: (t) {
            if (t != null && t != current) onChanged(t);
          },
        ),
      ),
    );
  }
}
