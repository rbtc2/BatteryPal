import 'package:flutter/material.dart';
import '../screens/main_navigation_screen.dart';
import '../services/settings_service.dart';
import 'app_theme_manager.dart';

/// BatteryPal 앱의 메인 설정 클래스
/// Phase 9에서 테마 관리 시스템 통합
class BatteryPalApp extends StatefulWidget {
  const BatteryPalApp({super.key});

  @override
  State<BatteryPalApp> createState() => _BatteryPalAppState();
}

class _BatteryPalAppState extends State<BatteryPalApp> {
  late final SettingsService _settingsService;

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService();
    // 설정 초기화 및 로드
    _settingsService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settingsService,
      builder: (context, child) {
        return MaterialApp(
          title: 'BatteryPal',
          theme: AppThemeManager.lightTheme,
          darkTheme: AppThemeManager.darkTheme,
          themeMode: _settingsService.appSettings.darkModeEnabled
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const MainNavigationScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
