import 'package:flutter/material.dart';
import '../screens/main_navigation_screen.dart';

/// BatteryPal 앱의 메인 설정 클래스
/// 테마, 라우팅 등 앱 레벨 설정을 담당
class BatteryPalApp extends StatelessWidget {
  const BatteryPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BatteryPal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50), // 배터리 테마 그린
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}
