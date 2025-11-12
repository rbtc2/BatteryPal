import '../models/charging_session_models.dart';
import 'time_slot_utils.dart';

/// 충전 세션 통계 계산 결과
class ChargingStats {
  /// 평균 충전 전류 (mA)
  final double avgCurrent;
  
  /// 세션 개수
  final int sessionCount;
  
  /// 주 시간대 이름 (예: "아침", "저녁")
  final String mainTimeSlot;
  
  /// 주 시간대 (TimeSlot enum)
  final TimeSlot? mainTimeSlotEnum;

  const ChargingStats({
    required this.avgCurrent,
    required this.sessionCount,
    required this.mainTimeSlot,
    this.mainTimeSlotEnum,
  });

  /// 빈 통계 (데이터가 없을 때)
  factory ChargingStats.empty() {
    return const ChargingStats(
      avgCurrent: 0.0,
      sessionCount: 0,
      mainTimeSlot: '-',
      mainTimeSlotEnum: null,
    );
  }
}

/// 충전 세션 통계를 계산하는 유틸리티 클래스
/// 
/// 충전 세션 리스트로부터 통계 정보를 계산합니다.
/// - 평균 충전 전류
/// - 세션 개수
/// - 주 시간대
class ChargingStatsCalculator {
  /// 통계 계산
  /// 
  /// [sessions]: 계산할 충전 세션 리스트
  /// 
  /// Returns: 계산된 통계 정보
  static ChargingStats calculate(List<ChargingSessionRecord> sessions) {
    if (sessions.isEmpty) {
      return ChargingStats.empty();
    }
    
    // 유효한 세션만 필터링 (5분 이상 충전된 세션만 포함)
    // validate() 메서드를 호출하여 실제로 5분 이상인 세션만 필터링
    final validSessions = sessions.where((s) => s.validate()).toList();
    
    if (validSessions.isEmpty) {
      return ChargingStats.empty();
    }
    
    // 평균 전류 계산 (유효한 세션만)
    final totalCurrent = validSessions.fold<double>(
      0.0,
      (sum, session) => sum + (session.avgCurrent.isFinite ? session.avgCurrent : 0.0),
    );
    final avgCurrent = totalCurrent > 0 ? (totalCurrent / validSessions.length) : 0.0;
    
    // 세션 개수 (유효한 세션만)
    final sessionCount = validSessions.length;
    
    // 주 시간대 계산 (가장 많은 세션이 있는 시간대)
    final timeSlotCounts = <TimeSlot, int>{};
    for (final session in validSessions) {
      timeSlotCounts[session.timeSlot] = 
          (timeSlotCounts[session.timeSlot] ?? 0) + 1;
    }
    
    TimeSlot? mainTimeSlotEnum;
    String mainTimeSlot = '-';
    
    if (timeSlotCounts.isNotEmpty) {
      final mainSlot = timeSlotCounts.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      ).key;
      mainTimeSlotEnum = mainSlot;
      mainTimeSlot = TimeSlotUtils.getTimeSlotName(mainSlot);
    }
    
    return ChargingStats(
      avgCurrent: avgCurrent,
      sessionCount: sessionCount,
      mainTimeSlot: mainTimeSlot,
      mainTimeSlotEnum: mainTimeSlotEnum,
    );
  }
  
  /// 주 시간대만 계산 (TimeSlot enum 반환)
  /// 
  /// [sessions]: 계산할 충전 세션 리스트
  /// 
  /// Returns: 주 시간대 (TimeSlot enum), 없으면 null
  static TimeSlot? calculateMainTimeSlot(List<ChargingSessionRecord> sessions) {
    final validSessions = sessions.where((s) => s.validate()).toList();
    if (validSessions.isEmpty) {
      return null;
    }
    
    final timeSlotCounts = <TimeSlot, int>{};
    for (final session in validSessions) {
      timeSlotCounts[session.timeSlot] = 
          (timeSlotCounts[session.timeSlot] ?? 0) + 1;
    }
    
    if (timeSlotCounts.isNotEmpty) {
      return timeSlotCounts.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      ).key;
    }
    
    return null;
  }
}

