import 'package:flutter/material.dart';

/// 유틸리티 함수들
/// Phase 2에서 실제 구현

/// 시간 포맷팅 유틸리티
class TimeUtils {
  /// 상대적 시간 표시 (예: "3분 전", "2시간 전")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}초 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
  
  /// 절대 시간 표시 (예: "2024-01-15 14:30")
  static String formatAbsoluteTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  /// 시간 간격 표시 (예: "2시간 30분")
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '$hours시간 $minutes분';
    } else {
      return '$minutes분';
    }
  }
}

/// 색상 유틸리티
class ColorUtils {
  /// 배터리 레벨에 따른 색상 반환
  static Color getBatteryLevelColor(double level) {
    if (level > 50) return Colors.green;
    if (level > 20) return Colors.orange;
    return Colors.red;
  }
  
  /// 배터리 온도에 따른 색상 반환
  static Color getTemperatureColor(double temperature) {
    if (temperature < 30) return Colors.blue;
    if (temperature < 40) return Colors.green;
    if (temperature < 50) return Colors.orange;
    return Colors.red;
  }
  
  /// 배터리 전압에 따른 색상 반환
  static Color getVoltageColor(double voltage) {
    // 일반적인 리튬이온 배터리 전압 범위 기준
    if (voltage > 3800) return Colors.green;
    if (voltage > 3600) return Colors.orange;
    return Colors.red;
  }
  
  /// 배터리 건강도에 따른 색상 반환
  static Color getHealthColor(String health) {
    switch (health.toLowerCase()) {
      case 'good':
      case '양호':
        return Colors.green;
      case 'fair':
      case '보통':
        return Colors.orange;
      case 'poor':
      case '나쁨':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  /// 사용량에 따른 색상 반환
  static Color getUsageColor(int usage) {
    if (usage > 20) return Colors.red;
    if (usage > 10) return Colors.orange;
    return Colors.green;
  }
}

/// 아이콘 유틸리티
class IconUtils {
  /// 배터리 레벨에 따른 아이콘 반환
  static IconData getBatteryLevelIcon(double level) {
    if (level > 75) return Icons.battery_full;
    if (level > 50) return Icons.battery_6_bar;
    if (level > 25) return Icons.battery_4_bar;
    if (level > 10) return Icons.battery_2_bar;
    return Icons.battery_1_bar;
  }
  
  /// 배터리 상태에 따른 아이콘 반환
  static IconData getBatteryStatusIcon(bool isCharging, double level) {
    if (isCharging) {
      if (level > 90) return Icons.battery_charging_full;
      return Icons.battery_charging_full;
    }
    return getBatteryLevelIcon(level);
  }
  
  /// 앱 카테고리에 따른 아이콘 반환
  static IconData getAppCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'social':
      case '소셜':
        return Icons.people;
      case 'entertainment':
      case '엔터테인먼트':
        return Icons.play_circle;
      case 'productivity':
      case '생산성':
        return Icons.work;
      case 'communication':
      case '통신':
        return Icons.message;
      case 'media':
      case '미디어':
        return Icons.music_note;
      default:
        return Icons.apps;
    }
  }
}

/// 텍스트 유틸리티
class TextUtils {
  /// 텍스트를 지정된 길이로 자르고 말줄임표 추가
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
  
  /// 숫자를 천 단위로 콤마 추가
  static String formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
  
  /// 파일 크기를 읽기 쉬운 형태로 변환
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// 퍼센트 값을 포맷팅
  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }
}

/// 스낵바 유틸리티
class SnackBarUtils {
  /// 성공 메시지 스낵바 표시
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  /// 에러 메시지 스낵바 표시
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  /// 정보 메시지 스낵바 표시
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  /// 경고 메시지 스낵바 표시
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
