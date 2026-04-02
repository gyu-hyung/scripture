import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/translation.dart';
import '../services/bible_service.dart';


// ─── 번역본 선택 ──────────────────────────────────────────────────────────

final selectedTranslationProvider =
    AsyncNotifierProvider<SelectedTranslationNotifier, Translation>(
  SelectedTranslationNotifier.new,
);

class SelectedTranslationNotifier extends AsyncNotifier<Translation> {
  static const _key = 'selected_translation_id';

  @override
  Future<Translation> build() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_key);

    if (savedId != null) {
      final found = Translation.bundled.where((t) => t.id == savedId).firstOrNull;
      if (found != null) return found;
    }

    // 저장된 값 없으면 기기 locale 기반 기본값
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    return Translation.defaultFor(locale.languageCode);
  }

  Future<void> setTranslation(Translation translation) async {
    state = AsyncValue.data(translation);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, translation.id);

    // 번역본 바뀌면 DB 캐시 초기화 (구절은 ref.watch에 의해 자동 갱신됨)
    BibleService.clearAllCache();
  }
}
