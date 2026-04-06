import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/translation.dart';
import '../services/bible_service.dart';
import '../services/widget_service.dart';
import 'translation_provider.dart';

// ─── 서비스 ───────────────────────────────────────────────────────────────

final bibleServiceProvider = Provider<BibleService>((ref) {
  final translationAsync = ref.watch(selectedTranslationProvider);
  final translation = translationAsync.when(
    data: (t) => t,
    loading: () => Translation.bundled[0],
    error: (e, st) => Translation.bundled[0],
  );
  return BibleService(translation);
});

final widgetServiceProvider = Provider<WidgetService>((ref) {
  return WidgetService(ref.watch(bibleServiceProvider));
});
