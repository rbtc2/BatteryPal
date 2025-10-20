// 앱 상수 정의
// Phase 2에서 실제 구현 예정

/// 앱 기본 상수
class AppConstants {
  static const String appName = 'BatteryPal';
  static const String appVersion = '1.0.0';
  static const String developerName = 'BatteryPal Team';
  static const String license = 'MIT License';
  
  // Pro 모드 관련
  static const int freeUsageLimit = 3;
  static const double proMonthlyPrice = 4900.0;
  
  // 배터리 관련
  static const double batteryThresholdMin = 5.0;
  static const double batteryThresholdMax = 50.0;
  static const double batteryThresholdDefault = 20.0;
}

/// 색상 상수
class AppColors {
  static const int primaryColorValue = 0xFF4CAF50;
  static const int proColorValue = 0xFFFFD700;
  
  // 배터리 상태별 색상
  static const int batteryLowColor = 0xFFFF5722;
  static const int batteryMediumColor = 0xFFFF9800;
  static const int batteryHighColor = 0xFF4CAF50;
}

/// 텍스트 스타일 상수
class AppTextStyles {
  static const double titleLarge = 22.0;
  static const double titleMedium = 18.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}
