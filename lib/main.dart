import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/battery_pal_app.dart';
import 'services/notification_service.dart';
import 'services/background_data_recovery_service.dart';
import 'services/charging_current_history_service.dart';
import 'screens/analysis/widgets/charging_patterns/services/charging_session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 알림 서비스 초기화
  try {
    await NotificationService().initialize();
    debugPrint('알림 서비스 초기화 완료');
  } catch (e) {
    debugPrint('알림 서비스 초기화 실패: $e');
  }
  
  // 데이터베이스 및 충전 전류 히스토리 서비스 초기화
  try {
    await ChargingCurrentHistoryService().initialize();
    debugPrint('충전 전류 히스토리 서비스 초기화 완료');
  } catch (e) {
    debugPrint('충전 전류 히스토리 서비스 초기화 실패: $e');
  }
  
  // 충전 세션 서비스 초기화
  try {
    await ChargingSessionService().initialize();
    debugPrint('충전 세션 서비스 초기화 완료');
  } catch (e) {
    debugPrint('충전 세션 서비스 초기화 실패: $e');
  }
  
  // Phase 2: 백그라운드 데이터 복구
  try {
    await BackgroundDataRecoveryService().recoverBackgroundData();
    debugPrint('백그라운드 데이터 복구 완료');
  } catch (e) {
    debugPrint('백그라운드 데이터 복구 실패: $e');
  }
  
  // 화면 방향을 세로 모드로 고정 (선택사항)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const BatteryPalApp());
}