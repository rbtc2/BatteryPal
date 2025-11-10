// 시간대 분류 유틸리티
// 충전 세션을 시간대별로 분류하고, 제목을 생성하는 유틸리티 클래스

import 'package:flutter/material.dart';
import '../models/charging_session_models.dart';

/// 시간대 분류 및 제목 생성 유틸리티
class TimeSlotUtils {
  TimeSlotUtils._(); // private constructor (정적 클래스)

  /// 시간대 분류
  /// 주어진 시간을 기반으로 시간대를 반환
  /// 
  /// 시간대 구분:
  /// - 새벽: 00:00 ~ 06:00
  /// - 아침: 06:00 ~ 12:00
  /// - 점심: 12:00 ~ 15:00
  /// - 늦은 오후: 15:00 ~ 18:00
  /// - 저녁: 18:00 ~ 22:00
  /// - 밤: 22:00 ~ 24:00
  static TimeSlot getTimeSlot(DateTime time) {
    final hour = time.hour;
    
    if (hour >= 0 && hour < 6) {
      return TimeSlot.dawn;
    } else if (hour >= 6 && hour < 12) {
      return TimeSlot.morning;
    } else if (hour >= 12 && hour < 15) {
      return TimeSlot.afternoon;
    } else if (hour >= 15 && hour < 18) {
      return TimeSlot.lateAfternoon;
    } else if (hour >= 18 && hour < 22) {
      return TimeSlot.evening;
    } else {
      return TimeSlot.night;
    }
  }

  /// 시간대별 한글 이름 반환
  static String getTimeSlotName(TimeSlot timeSlot) {
    switch (timeSlot) {
      case TimeSlot.dawn:
        return '새벽';
      case TimeSlot.morning:
        return '아침';
      case TimeSlot.afternoon:
        return '점심';
      case TimeSlot.lateAfternoon:
        return '늦은 오후';
      case TimeSlot.evening:
        return '저녁';
      case TimeSlot.night:
        return '밤';
    }
  }

  /// 시간대별 아이콘 반환 (이모지)
  static String getTimeSlotIcon(TimeSlot timeSlot) {
    switch (timeSlot) {
      case TimeSlot.dawn:
        return '🌙';
      case TimeSlot.morning:
        return '☀️';
      case TimeSlot.afternoon:
        return '🌤️';
      case TimeSlot.lateAfternoon:
        return '⛅';
      case TimeSlot.evening:
        return '🌆';
      case TimeSlot.night:
        return '🌃';
    }
  }

  /// 시간대별 색상 반환
  static Color getTimeSlotColor(TimeSlot timeSlot) {
    switch (timeSlot) {
      case TimeSlot.dawn:
        return Colors.blue[400]!;
      case TimeSlot.morning:
        return Colors.orange[400]!;
      case TimeSlot.afternoon:
        return Colors.yellow[600]!;
      case TimeSlot.lateAfternoon:
        return Colors.orange[600]!;
      case TimeSlot.evening:
        return Colors.purple[400]!;
      case TimeSlot.night:
        return Colors.indigo[400]!;
    }
  }

  /// 시간대별 기본 제목 생성
  /// 예: "아침 충전", "점심 충전"
  static String getDefaultTitle(TimeSlot timeSlot) {
    final name = getTimeSlotName(timeSlot);
    return '$name 충전';
  }

  /// 중복 시간대 제목 생성
  /// 같은 시간대에 여러 세션이 있을 때 번호를 붙여서 구분
  /// 
  /// 예:
  /// - 첫 번째: "아침 충전"
  /// - 두 번째: "아침 충전 2"
  /// - 세 번째: "아침 충전 3"
  /// 
  /// [existingTitles] 같은 시간대의 기존 세션 제목 목록
  /// [timeSlot] 시간대
  /// 
  /// 반환: 새로운 세션 제목
  static String generateSessionTitle(
    TimeSlot timeSlot,
    List<String> existingTitles,
  ) {
    final baseTitle = getDefaultTitle(timeSlot);
    
    // 기존 제목이 없으면 기본 제목 반환
    if (existingTitles.isEmpty) {
      return baseTitle;
    }
    
    // 같은 시간대의 제목만 필터링
    final sameTimeSlotTitles = existingTitles
        .where((title) => title.startsWith(getTimeSlotName(timeSlot)))
        .toList();
    
    // 기본 제목과 정확히 일치하는 제목이 없으면 기본 제목 반환
    if (!sameTimeSlotTitles.contains(baseTitle)) {
      return baseTitle;
    }
    
    // 번호가 붙은 제목들에서 최대 번호 찾기
    int maxNumber = 1;
    for (final title in sameTimeSlotTitles) {
      // "아침 충전 2" 형식에서 숫자 추출
      final match = RegExp(r'(\d+)$').firstMatch(title);
      if (match != null) {
        final number = int.tryParse(match.group(1) ?? '');
        if (number != null && number > maxNumber) {
          maxNumber = number;
        }
      }
    }
    
    // 다음 번호 생성
    final nextNumber = maxNumber + 1;
    return '$baseTitle $nextNumber';
  }

  /// 시간대별 상세 설명 반환
  static String getTimeSlotDescription(TimeSlot timeSlot) {
    switch (timeSlot) {
      case TimeSlot.dawn:
        return '새벽 시간대 (00:00 ~ 06:00)';
      case TimeSlot.morning:
        return '아침 시간대 (06:00 ~ 12:00)';
      case TimeSlot.afternoon:
        return '점심 시간대 (12:00 ~ 15:00)';
      case TimeSlot.lateAfternoon:
        return '늦은 오후 시간대 (15:00 ~ 18:00)';
      case TimeSlot.evening:
        return '저녁 시간대 (18:00 ~ 22:00)';
      case TimeSlot.night:
        return '밤 시간대 (22:00 ~ 24:00)';
    }
  }

  /// 시간대 범위 문자열 반환
  /// 예: "06:00 ~ 12:00"
  static String getTimeSlotRange(TimeSlot timeSlot) {
    switch (timeSlot) {
      case TimeSlot.dawn:
        return '00:00 ~ 06:00';
      case TimeSlot.morning:
        return '06:00 ~ 12:00';
      case TimeSlot.afternoon:
        return '12:00 ~ 15:00';
      case TimeSlot.lateAfternoon:
        return '15:00 ~ 18:00';
      case TimeSlot.evening:
        return '18:00 ~ 22:00';
      case TimeSlot.night:
        return '22:00 ~ 24:00';
    }
  }

  /// 시간이 특정 시간대에 속하는지 확인
  static bool isInTimeSlot(DateTime time, TimeSlot timeSlot) {
    return getTimeSlot(time) == timeSlot;
  }

  /// 두 시간이 같은 시간대에 속하는지 확인
  static bool isSameTimeSlot(DateTime time1, DateTime time2) {
    return getTimeSlot(time1) == getTimeSlot(time2);
  }
  
  /// 효율 등급에 따른 색상 반환
  static Color getEfficiencyColor(double efficiency) {
    if (efficiency >= 90.0) {
      return Colors.green;
    } else if (efficiency >= 80.0) {
      return Colors.orange;
    } else if (efficiency >= 70.0) {
      return Colors.yellow.shade700;
    } else {
      return Colors.red;
    }
  }
}

