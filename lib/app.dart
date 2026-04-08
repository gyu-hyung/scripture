import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';

class ScriptureApp extends StatelessWidget {
  const ScriptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ko'),
        // 추후 언어 추가:
        // Locale('ja'),
        // Locale('zh', 'CN'),
        // Locale('zh', 'TW'),
        // Locale('es'),
        // Locale('pt'),
        // Locale('fr'),
        // Locale('de'),
        // Locale('id'),
        // Locale('vi'),
        // Locale('ru'),
        // Locale('ar'),
      ],
      home: const SplashScreen(),
    );
  }
}
