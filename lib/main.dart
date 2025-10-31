import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/battery_pal_app.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 알림 서비스 초기화
  try {
    await NotificationService().initialize();
    debugPrint('알림 서비스 초기화 완료');
  } catch (e) {
    debugPrint('알림 서비스 초기화 실패: $e');
  }
  
  // 화면 방향을 세로 모드로 고정 (선택사항)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const BatteryPalApp());
}