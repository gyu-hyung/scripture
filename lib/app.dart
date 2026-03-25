import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';

class ScriptureApp extends StatelessWidget {
  const ScriptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '말씀위젯',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
