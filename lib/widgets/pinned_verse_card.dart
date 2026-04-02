import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/verse.dart';

class PinnedVerseCard extends StatelessWidget {
  final AsyncValue<Verse?> verseAsync;
  final String emptyMessage;
  final VoidCallback? onEmpty;
  final VoidCallback? onUnpin;

  const PinnedVerseCard({
    super.key,
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
