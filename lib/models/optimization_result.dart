import '../utils/app_utils.dart';

/// 배터리 최적화 결과 모델
class OptimizationResult {
  final double powerSaved; // 절약된 전력 (mW)
  final Duration timeExtended; // 연장된 시간
  final int appsOptimized; // 최적화된 앱 수
  final List<String> optimizedApps; // 최적화된 앱 목록
  final DateTime timestamp; // 최적화 시간
  
  const OptimizationResult({
    required this.powerSaved,
    required this.timeExtended,
    required this.appsOptimized,
    required this.optimizedApps,
    required this.timestamp,
  });
  
  /// 절약된 전력을 포맷팅된 문자열로 반환
  String get formattedPowerSaved => '${powerSaved.toStringAsFixed(0)}mW';
  
  /// 연장된 시간을 포맷팅된 문자열로 반환
  String get formattedTimeExtended => TimeUtils.formatDuration(timeExtended);
  
  /// 최적화 시간을 상대적 시간으로 표시
  String get optimizationTimeText => TimeUtils.formatRelativeTime(timestamp);
  
  /// 최적화 결과를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'powerSaved': powerSaved,
      'timeExtended': timeExtended.inMilliseconds,
      'appsOptimized': appsOptimized,
      'optimizedApps': optimizedApps,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  /// JSON에서 최적화 결과 생성
  factory OptimizationResult.fromJson(Map<String, dynamic> json) {
    return OptimizationResult(
      powerSaved: json['powerSaved']?.toDouble() ?? 0.0,
      timeExtended: Duration(milliseconds: json['timeExtended'] ?? 0),
      appsOptimized: json['appsOptimized'] ?? 0,
      optimizedApps: List<String>.from(json['optimizedApps'] ?? []),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
  
  @override
  String toString() {
    return 'OptimizationResult(powerSaved: $formattedPowerSaved, timeExtended: $formattedTimeExtended, appsOptimized: $appsOptimized)';
  }
}

