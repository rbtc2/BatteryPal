/// 충전 모니터 전용 포맷팅 유틸리티
/// 충전 시간 및 지속 시간 포맷팅 함수들
class ChargingFormatUtils {
  /// 지속 시간 포맷팅
  /// Duration을 "X시간 Y분 Z초", "Y분 Z초", 또는 "Z초" 형식으로 변환
  /// 음수 duration은 "0초"로 반환
  static String formatDuration(Duration duration) {
    // 음수 duration 방지
    if (duration.isNegative) {
      return '0초';
    }
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    // 모든 값이 0일 때 처리
    if (hours == 0 && minutes == 0 && seconds == 0) {
      return '0초';
    }
    
    // 시간, 분, 초를 조합하여 표시
    final List<String> parts = [];
    
    if (hours > 0) {
      parts.add('$hours시간');
    }
    if (minutes > 0) {
      parts.add('$minutes분');
    }
    if (seconds > 0 || parts.isEmpty) {
      parts.add('$seconds초');
    }
    
    return parts.join(' ');
  }

  /// 충전 시간 포맷팅
  /// DateTime을 "오늘 오전/오후 HH:mm", "어제 오전/오후 HH:mm", 
  /// 또는 "M월 D일 오전/오후 HH:mm" 형식으로 변환
  /// null인 경우 "--" 반환
  static String formatChargingTime(DateTime? endTime) {
    if (endTime == null) {
      return '--';
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final endDate = DateTime(endTime.year, endTime.month, endTime.day);
    
    String timeStr;
    if (endDate == today) {
      // 오늘
      final hour = endTime.hour;
      final minute = endTime.minute.toString().padLeft(2, '0');
      
      if (hour < 12) {
        timeStr = '오늘 오전 $hour:$minute';
      } else if (hour == 12) {
        timeStr = '오늘 오후 12:$minute';
      } else {
        timeStr = '오늘 오후 ${hour - 12}:$minute';
      }
    } else if (endDate == yesterday) {
      // 어제
      final hour = endTime.hour;
      final minute = endTime.minute.toString().padLeft(2, '0');
      
      if (hour < 12) {
        timeStr = '어제 오전 $hour:$minute';
      } else if (hour == 12) {
        timeStr = '어제 오후 12:$minute';
      } else {
        timeStr = '어제 오후 ${hour - 12}:$minute';
      }
    } else {
      // 그 이전
      final month = endTime.month;
      final day = endTime.day;
      final hour = endTime.hour;
      final minute = endTime.minute.toString().padLeft(2, '0');
      
      String period;
      if (hour < 12) {
        period = '오전 $hour:$minute';
      } else if (hour == 12) {
        period = '오후 12:$minute';
      } else {
        period = '오후 ${hour - 12}:$minute';
      }
      
      timeStr = '$month월 $day일 $period';
    }
    
    return timeStr;
  }
}

