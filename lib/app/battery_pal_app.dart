import 'package:flutter/material.dart';
import '../screens/main_navigation_screen.dart';
import 'app_theme_manager.dart';

/// BatteryPal 앱의 메인 설정 클래스
/// Phase 9에서 테마 관리 시스템 통합
class BatteryPalApp extends StatelessWidget {
  const BatteryPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BatteryPal',
      theme: AppThemeManager.lightTheme,
      darkTheme: AppThemeManager.darkTheme,
      themeMode: ThemeMode.dark, // 기본값: 다크 모드
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
