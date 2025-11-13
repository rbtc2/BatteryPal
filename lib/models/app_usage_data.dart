import 'package:flutter/material.dart';
import '../utils/app_utils.dart';

/// 앱 사용량 데이터 모델
class AppUsageData {
  final String name;
  final int usage; // 배터리 사용량 (%)
  final IconData icon;
  final String category; // 앱 카테고리
  final Duration usageTime; // 사용 시간
  final double powerConsumption; // 전력 소비량 (mW)
  final DateTime lastUsed; // 마지막 사용 시간
  
  const AppUsageData({
    required this.name,
    required this.usage,
    required this.icon,
    required this.category,
    required this.usageTime,
    required this.powerConsumption,
    required this.lastUsed,
  });
  
  /// 사용량을 포맷팅된 문자열로 반환
  String get formattedUsage => '$usage%';
  
  /// 사용 시간을 포맷팅된 문자열로 반환
  String get formattedUsageTime => TimeUtils.formatDuration(usageTime);
  
  /// 전력 소비량을 포맷팅된 문자열로 반환
  String get formattedPowerConsumption => '${powerConsumption.toStringAsFixed(0)}mW';
  
  /// 마지막 사용 시간을 상대적 시간으로 표시
  String get lastUsedText => TimeUtils.formatRelativeTime(lastUsed);
  
  /// 사용량에 따른 색상 반환
  Color get usageColor => ColorUtils.getUsageColor(usage);
  
  /// 카테고리에 따른 아이콘 반환
  IconData get categoryIcon => IconUtils.getAppCategoryIcon(category);
  
  /// 앱 사용량 데이터를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'usage': usage,
      'icon': icon.codePoint,
      'category': category,
      'usageTime': usageTime.inMilliseconds,
      'powerConsumption': powerConsumption,
      'lastUsed': lastUsed.toIso8601String(),
    };
  }
  
  /// JSON에서 앱 사용량 데이터 생성
  factory AppUsageData.fromJson(Map<String, dynamic> json) {
    return AppUsageData(
      name: json['name'] ?? '',
      usage: json['usage'] ?? 0,
      icon: IconData(json['icon'] ?? Icons.apps.codePoint),
      category: json['category'] ?? '기타',
      usageTime: Duration(milliseconds: json['usageTime'] ?? 0),
      powerConsumption: json['powerConsumption']?.toDouble() ?? 0.0,
      lastUsed: DateTime.parse(json['lastUsed']),
    );
  }
  
  /// 앱 사용량 데이터 복사본 생성
  AppUsageData copyWith({
    String? name,
    int? usage,
    IconData? icon,
    String? category,
    Duration? usageTime,
    double? powerConsumption,
    DateTime? lastUsed,
  }) {
    return AppUsageData(
      name: name ?? this.name,
      usage: usage ?? this.usage,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      usageTime: usageTime ?? this.usageTime,
      powerConsumption: powerConsumption ?? this.powerConsumption,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
  
  @override
  String toString() {
    return 'AppUsageData(name: $name, usage: $usage%, category: $category, powerConsumption: $formattedPowerConsumption)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUsageData &&
        other.name == name &&
        other.usage == usage &&
        other.icon.codePoint == icon.codePoint &&
        other.category == category &&
        other.usageTime == usageTime &&
        other.powerConsumption == powerConsumption &&
        other.lastUsed == lastUsed;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      name,
      usage,
      icon.codePoint,
      category,
      usageTime,
      powerConsumption,
      lastUsed,
    );
  }
}

