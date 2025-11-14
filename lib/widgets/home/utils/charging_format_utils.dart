/// 충전 모니터 전용 포맷팅 유틸리티
/// 충전 시간 및 지속 시간 포맷팅 함수들
class ChargingFormatUtils {
  /// 지속 시간 포맷팅
  /// Duration을 "X시간 Y분" 또는 "Y분" 형식으로 변환
  /// 음수 duration은 "0분"으로 반환
  static String formatDuration(Duration duration) {
    // 음수 duration 방지
    if (duration.isNegative) {
      return '0분';
    }
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    // 0분일 때 처리
    if (hours == 0 && minutes == 0) {
      return '0분';
    }
    
    if (hours > 0) {
      return '$hours시간 $minutes분';
    } else {
      return '$minutes분';
    }
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

