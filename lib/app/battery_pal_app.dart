import 'package:flutter/material.dart';
import '../screens/main_navigation_screen.dart';
import '../services/settings_service.dart';
import '../services/background_data_recovery_service.dart';
import '../utils/app_utils.dart';
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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService();
    // 설정 초기화 및 로드
    _settingsService.initialize();
    
    // Phase 4: 앱 시작 후 백그라운드 데이터 복구 결과 확인 및 알림
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowRecoveryNotification();
    });
  }
  
  /// Phase 4: 백그라운드 데이터 복구 결과 확인 및 알림 표시
  Future<void> _checkAndShowRecoveryNotification() async {
    // 앱이 완전히 로드될 때까지 대기
    await Future.delayed(const Duration(seconds: 2));
    
    try {
      final recoveryService = BackgroundDataRecoveryService();
      final result = recoveryService.lastRecoveryResult;
      
      if (result != null && result.hasRecoveredData) {
        // 복구된 데이터가 있으면 알림 표시
        final context = _navigatorKey.currentContext;
        if (context != null && context.mounted) {
          final message = _buildRecoveryMessage(result);
          SnackBarUtils.showInfo(context, message);
        }
      }
    } catch (e) {
      debugPrint('복구 알림 표시 실패: $e');
    }
  }
  
  /// Phase 4: 복구 메시지 생성
  String _buildRecoveryMessage(BackgroundDataRecoveryResult result) {
    final parts = <String>[];
    
    if (result.dataCount > 0) {
      parts.add('${result.dataCount}개의 충전 데이터');
    }
    
    if (result.sessionCount > 0) {
      parts.add('${result.sessionCount}개의 충전 세션');
    }
    
    if (parts.isEmpty) {
      return '백그라운드 데이터가 복구되었습니다.';
    }
    
    return '백그라운드에서 ${parts.join(' 및 ')}이(가) 복구되었습니다.';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settingsService,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
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
