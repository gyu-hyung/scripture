import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// DB에 저장된 영어 카테고리 키를 현재 locale에 맞는 문자열로 변환
String localizeCategory(BuildContext context, String key) {
  final l10n = AppLocalizations.of(context);
  return switch (key) {
    'all'          => l10n.categoryAll,
    'comfort'      => l10n.categoryComfort,
    'thanksgiving' => l10n.categoryThanksgiving,
    'hope'         => l10n.categoryHope,
    'love'         => l10n.categoryLove,
    'faith'        => l10n.categoryFaith,
    'peace'        => l10n.categoryPeace,
    'wisdom'       => l10n.categoryWisdom,
    _              => key,
  };
}
