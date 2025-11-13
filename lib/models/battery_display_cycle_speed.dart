/// 배터리 정보 표시 설정
enum BatteryDisplayCycleSpeed {
  off('끄기', 0),
  fast('빠름', 2),
  normal('보통', 3),
  slow('느림', 5);

  const BatteryDisplayCycleSpeed(this.displayName, this.durationSeconds);
  
  final String displayName;
  final int durationSeconds;
}

