/// 실시간 충전 모니터 표시 방식
enum ChargingMonitorDisplayMode {
  /// 충전 속도만 표시
  currentOnly('충전 속도만'),
  
  /// 충전 속도 + 지속 시간 표시
  currentWithDuration('충전 속도 + 지속 시간');

  const ChargingMonitorDisplayMode(this.displayName);
  
  final String displayName;
}

