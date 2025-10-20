import 'package:flutter/material.dart';

// 앱 상수 정의
// Phase 2에서 실제 구현

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
  
  // 시간 관련
  static const Duration snackBarDuration = Duration(seconds: 2);
  static const Duration dialogAnimationDuration = Duration(milliseconds: 300);
}

/// 색상 상수
class AppColors {
  static const int primaryColorValue = 0xFF4CAF50;
  static const int proColorValue = 0xFFFFD700;
  
  // 배터리 상태별 색상
  static const int batteryLowColor = 0xFFFF5722;
  static const int batteryMediumColor = 0xFFFF9800;
  static const int batteryHighColor = 0xFF4CAF50;
  
  // 알파 값
  static const double alphaLow = 0.1;
  static const double alphaMedium = 0.3;
  static const double alphaHigh = 0.7;
}

/// 텍스트 스타일 상수
class AppTextStyles {
  static const double titleLarge = 22.0;
  static const double titleMedium = 18.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
  
  // 폰트 웨이트
  static const FontWeight bold = FontWeight.bold;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight normal = FontWeight.normal;
}

/// 패딩 및 마진 상수
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  
  // 카드 패딩
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(20);
  
  // 섹션 간격
  static const double sectionSpacing = 24.0;
}

/// 아이콘 크기 상수
class AppIconSizes {
  static const double small = 16.0;
  static const double medium = 20.0;
  static const double large = 24.0;
  static const double xlarge = 32.0;
  static const double xxlarge = 48.0;
}

/// 애니메이션 상수
class AppAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  
  static const Curve defaultCurve = Curves.easeInOut;
}
