import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import '../utils/app_utils.dart';

// 데이터 모델 정의
// Phase 3에서 실제 구현

/// 배터리 정보 모델
class BatteryInfo {
  final double level; // 배터리 레벨 (0.0 ~ 100.0)
  final BatteryState state; // 배터리 상태
  final DateTime timestamp; // 정보 수집 시간
  final double temperature; // 배터리 온도 (섭씨)
  final int voltage; // 배터리 전압 (mV)
  final int capacity; // 배터리 용량
  final int health; // 배터리 건강도
  final String chargingType; // 충전 방식 (AC/USB/Wireless)
  final int chargingCurrent; // 충전 전류 (mA)
  final bool isCharging; // 충전 중 여부

  const BatteryInfo({
    required this.level,
    required this.state,
    required this.timestamp,
    required this.temperature,
    required this.voltage,
    required this.capacity,
    required this.health,
    required this.chargingType,
    required this.chargingCurrent,
    required this.isCharging,
  });

  /// 배터리 레벨을 정확하게 포맷팅 (소수점이 의미가 있을 때만 표시)
  String get formattedLevel {
    if (level == level.round()) {
      return '${level.round()}%'; // 정수인 경우 소수점 없이 표시
    } else {
      return '${level.toStringAsFixed(1)}%'; // 소수점이 있는 경우에만 표시
    }
  }
  
  /// 배터리 온도를 소숫점 한자리까지 포맷팅
  String get formattedTemperature => temperature >= 0 ? '${temperature.toStringAsFixed(1)}°C' : '--.-°C';
  
  /// 배터리 전압을 포맷팅
  String get formattedVoltage => voltage >= 0 ? '${voltage}mV' : '--mV';
  
  /// 배터리 용량을 포맷팅
  String get formattedCapacity => capacity >= 0 ? '${capacity}mAh' : '--mAh';
  
  /// 배터리 건강도를 텍스트로 변환
  String get healthText {
    switch (health) {
      case 1: return '알 수 없음';
      case 2: return '양호';
      case 3: return '과열';
      case 4: return '사망';
      case 5: return '과전압';
      case 6: return '지정되지 않은 오류';
      case 7: return '온도 저하';
      default: return '알 수 없음';
    }
  }
  
  /// 충전 방식 텍스트 변환
  String get chargingTypeText {
    switch (chargingType) {
      case 'AC': return 'AC 충전';
      case 'USB': return 'USB 충전';
      case 'Wireless': return '무선 충전';
      default: return '알 수 없음';
    }
  }
  
  /// 충전 전류 포맷팅
  String get formattedChargingCurrent {
    if (chargingCurrent < 0) return '--mA';
    return '${chargingCurrent}mA';
  }
  
  /// 충전 상태 요약
  String get chargingStatusText {
    if (!isCharging) return '방전 중';
    return '$chargingTypeText ($formattedChargingCurrent)';
  }
  
  /// 배터리 상태를 한국어로 변환
  String get stateText {
    switch (state) {
      case BatteryState.charging:
        return '충전 중';
      case BatteryState.discharging:
        return '방전 중';
      case BatteryState.full:
        return '충전 완료';
      default:
        return '알 수 없음';
    }
  }
  
  /// 배터리 레벨에 따른 색상 반환 (유틸리티 사용)
  Color get levelColor => ColorUtils.getBatteryLevelColor(level);
  
  /// 배터리 온도에 따른 색상 반환 (유틸리티 사용)
  Color get temperatureColor => ColorUtils.getTemperatureColor(temperature);
  
  /// 배터리 전압에 따른 색상 반환 (유틸리티 사용)
  Color get voltageColor => ColorUtils.getVoltageColor(voltage.toDouble());
  
  /// 배터리 건강도에 따른 색상 반환 (유틸리티 사용)
  Color get healthColor => ColorUtils.getHealthColor(healthText);
  
  /// 배터리 레벨에 따른 아이콘 반환 (유틸리티 사용)
  IconData get levelIcon => IconUtils.getBatteryLevelIcon(level);
  
  /// 배터리 상태에 따른 아이콘 반환 (유틸리티 사용)
  IconData get statusIcon => IconUtils.getBatteryStatusIcon(isCharging, level);
  
  /// 마지막 업데이트 시간을 상대적 시간으로 표시
  String get lastUpdateText => TimeUtils.formatRelativeTime(timestamp);
  
  /// 배터리 정보를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'state': state.toString(),
      'timestamp': timestamp.toIso8601String(),
      'temperature': temperature,
      'voltage': voltage,
      'capacity': capacity,
      'health': health,
      'chargingType': chargingType,
      'chargingCurrent': chargingCurrent,
      'isCharging': isCharging,
    };
  }
  
  /// JSON에서 배터리 정보 생성
  factory BatteryInfo.fromJson(Map<String, dynamic> json) {
    return BatteryInfo(
      level: json['level']?.toDouble() ?? 0.0,
      state: BatteryState.values.firstWhere(
        (e) => e.toString() == json['state'],
        orElse: () => BatteryState.unknown,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      temperature: json['temperature']?.toDouble() ?? 0.0,
      voltage: json['voltage'] ?? 0,
      capacity: json['capacity'] ?? 0,
      health: json['health'] ?? 1,
      chargingType: json['chargingType'] ?? 'Unknown',
      chargingCurrent: json['chargingCurrent'] ?? -1,
      isCharging: json['isCharging'] ?? false,
    );
  }

  /// 네이티브 충전 정보에서 배터리 정보 생성
  factory BatteryInfo.fromChargingInfo(Map<String, dynamic> chargingInfo) {
    final isCharging = chargingInfo['isCharging'] ?? false;
    final chargingType = chargingInfo['chargingType'] ?? 'Unknown';
    final chargingCurrent = chargingInfo['chargingCurrent'] ?? -1;
    
    // 충전 상태에 따른 BatteryState 결정
    BatteryState state;
    if (isCharging) {
      state = BatteryState.charging;
    } else {
      state = BatteryState.discharging;
    }
    
    return BatteryInfo(
      level: 0.0, // 네이티브에서 레벨 정보가 없으므로 기본값
      state: state,
      timestamp: DateTime.now(),
      temperature: -1.0, // 네이티브에서 온도 정보가 없으므로 기본값
      voltage: -1, // 네이티브에서 전압 정보가 없으므로 기본값
      capacity: -1, // 네이티브에서 용량 정보가 없으므로 기본값
      health: -1, // 네이티브에서 건강도 정보가 없으므로 기본값
      chargingType: chargingType,
      chargingCurrent: chargingCurrent,
      isCharging: isCharging,
    );
  }

  /// 네이티브 충전 정보에서 배터리 정보 생성 (기존 데이터 유지)
  factory BatteryInfo.fromChargingInfoWithExistingData(
    Map<String, dynamic> chargingInfo, {
    required double level,
    required double temperature,
    required int voltage,
    required int capacity,
    required int health,
  }) {
    final isCharging = chargingInfo['isCharging'] ?? false;
    final chargingType = chargingInfo['chargingType'] ?? 'Unknown';
    final chargingCurrent = chargingInfo['chargingCurrent'] ?? -1;
    
    // 충전 상태에 따른 BatteryState 결정
    BatteryState state;
    if (isCharging) {
      state = BatteryState.charging;
    } else {
      state = BatteryState.discharging;
    }
    
    return BatteryInfo(
      level: level, // 기존 레벨 유지
      state: state,
      timestamp: DateTime.now(),
      temperature: temperature, // 기존 온도 유지
      voltage: voltage, // 기존 전압 유지
      capacity: capacity, // 기존 용량 유지
      health: health, // 기존 건강도 유지
      chargingType: chargingType,
      chargingCurrent: chargingCurrent,
      isCharging: isCharging,
    );
  }
  
  /// 배터리 정보 복사본 생성 (일부 필드 수정)
  BatteryInfo copyWith({
    double? level,
    BatteryState? state,
    DateTime? timestamp,
    double? temperature,
    int? voltage,
    int? capacity,
    int? health,
    String? chargingType,
    int? chargingCurrent,
    bool? isCharging,
  }) {
    return BatteryInfo(
      level: level ?? this.level,
      state: state ?? this.state,
      timestamp: timestamp ?? this.timestamp,
      temperature: temperature ?? this.temperature,
      voltage: voltage ?? this.voltage,
      capacity: capacity ?? this.capacity,
      health: health ?? this.health,
      chargingType: chargingType ?? this.chargingType,
      chargingCurrent: chargingCurrent ?? this.chargingCurrent,
      isCharging: isCharging ?? this.isCharging,
    );
  }
  
  @override
  String toString() {
    return 'BatteryInfo(level: $level%, state: $stateText, temperature: $formattedTemperature, voltage: $formattedVoltage, health: $healthText)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BatteryInfo &&
        other.level == level &&
        other.state == state &&
        other.timestamp == timestamp &&
        other.temperature == temperature &&
        other.voltage == voltage &&
        other.capacity == capacity &&
        other.health == health &&
        other.chargingType == chargingType &&
        other.chargingCurrent == chargingCurrent &&
        other.isCharging == isCharging;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      level,
      state,
      timestamp,
      temperature,
      voltage,
      capacity,
      health,
      chargingType,
      chargingCurrent,
      isCharging,
    );
  }
}

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

/// 설정 데이터 모델
class AppSettings {
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final String selectedLanguage;
  final bool powerSaveModeEnabled;
  final bool batteryNotificationsEnabled;
  final bool autoOptimizationEnabled;
  final bool batteryProtectionEnabled;
  final double batteryThreshold;
  final bool smartChargingEnabled;
  final bool backgroundAppRestriction;
  final bool chargingCompleteNotificationEnabled; // 충전 완료 알림 활성화
  
  // 충전 완료 알림 설정
  final bool chargingCompleteNotifyOnFastCharging; // 고속 충전(AC) 시에만 알림
  final bool chargingCompleteNotifyOnNormalCharging; // 일반 충전(USB/Wireless) 시에만 알림
  
  // 충전 퍼센트 알림 설정
  final bool chargingPercentNotificationEnabled; // 충전 퍼센트 알림 활성화
  final List<double> chargingPercentThresholds; // 알림 받을 퍼센트 목록 [70, 80, 90, 100]
  final bool chargingPercentNotifyOnFastCharging; // 고속 충전 시에만 알림
  final bool chargingPercentNotifyOnNormalCharging; // 일반 충전 시에만 알림
  
  // 화면 표시 설정
  final BatteryDisplayCycleSpeed batteryDisplayCycleSpeed; // 자동 순환 속도
  final bool showChargingCurrent; // 충전 전류 표시 여부
  final bool showBatteryPercentage; // 배터리 퍼센트 표시 여부
  final bool showBatteryTemperature; // 배터리 온도 표시 여부
  final bool enableTapToSwitch; // 탭으로 전환 여부
  final bool enableSwipeToSwitch; // 스와이프로 전환 여부
  
  final DateTime lastUpdated;
  
  const AppSettings({
    this.notificationsEnabled = true,
    this.darkModeEnabled = true,
    this.selectedLanguage = '한국어',
    this.powerSaveModeEnabled = false,
    this.batteryNotificationsEnabled = true,
    this.autoOptimizationEnabled = true,
    this.batteryProtectionEnabled = true,
    this.batteryThreshold = 20.0,
    this.smartChargingEnabled = false,
    this.backgroundAppRestriction = false,
    this.chargingCompleteNotificationEnabled = false, // 기본값: false (Pro 기능)
    
    // 충전 완료 알림 설정 기본값
    this.chargingCompleteNotifyOnFastCharging = true,
    this.chargingCompleteNotifyOnNormalCharging = true,
    
    // 충전 퍼센트 알림 설정 기본값
    this.chargingPercentNotificationEnabled = false,
    this.chargingPercentThresholds = const [],
    this.chargingPercentNotifyOnFastCharging = true,
    this.chargingPercentNotifyOnNormalCharging = true,
    
    // 화면 표시 설정 기본값
    this.batteryDisplayCycleSpeed = BatteryDisplayCycleSpeed.normal,
    this.showChargingCurrent = true,
    this.showBatteryPercentage = true,
    this.showBatteryTemperature = true,
    this.enableTapToSwitch = true,
    this.enableSwipeToSwitch = true,
    
    required this.lastUpdated,
  });
  
  /// 배터리 임계값을 포맷팅된 문자열로 반환
  String get formattedBatteryThreshold => '${batteryThreshold.toStringAsFixed(0)}%';
  
  /// 설정 데이터를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'darkModeEnabled': darkModeEnabled,
      'selectedLanguage': selectedLanguage,
      'powerSaveModeEnabled': powerSaveModeEnabled,
      'batteryNotificationsEnabled': batteryNotificationsEnabled,
      'autoOptimizationEnabled': autoOptimizationEnabled,
      'batteryProtectionEnabled': batteryProtectionEnabled,
      'batteryThreshold': batteryThreshold,
      'smartChargingEnabled': smartChargingEnabled,
      'backgroundAppRestriction': backgroundAppRestriction,
      'chargingCompleteNotificationEnabled': chargingCompleteNotificationEnabled,
      
      // 충전 완료 알림 설정
      'chargingCompleteNotifyOnFastCharging': chargingCompleteNotifyOnFastCharging,
      'chargingCompleteNotifyOnNormalCharging': chargingCompleteNotifyOnNormalCharging,
      
      // 충전 퍼센트 알림 설정
      'chargingPercentNotificationEnabled': chargingPercentNotificationEnabled,
      'chargingPercentThresholds': chargingPercentThresholds,
      'chargingPercentNotifyOnFastCharging': chargingPercentNotifyOnFastCharging,
      'chargingPercentNotifyOnNormalCharging': chargingPercentNotifyOnNormalCharging,
      
      // 화면 표시 설정
      'batteryDisplayCycleSpeed': batteryDisplayCycleSpeed.name,
      'showChargingCurrent': showChargingCurrent,
      'showBatteryPercentage': showBatteryPercentage,
      'showBatteryTemperature': showBatteryTemperature,
      'enableTapToSwitch': enableTapToSwitch,
      'enableSwipeToSwitch': enableSwipeToSwitch,
      
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
  
  /// JSON에서 설정 데이터 생성
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      darkModeEnabled: json['darkModeEnabled'] ?? true,
      selectedLanguage: json['selectedLanguage'] ?? '한국어',
      powerSaveModeEnabled: json['powerSaveModeEnabled'] ?? false,
      batteryNotificationsEnabled: json['batteryNotificationsEnabled'] ?? true,
      autoOptimizationEnabled: json['autoOptimizationEnabled'] ?? true,
      batteryProtectionEnabled: json['batteryProtectionEnabled'] ?? true,
      batteryThreshold: json['batteryThreshold']?.toDouble() ?? 20.0,
      smartChargingEnabled: json['smartChargingEnabled'] ?? false,
      backgroundAppRestriction: json['backgroundAppRestriction'] ?? false,
      chargingCompleteNotificationEnabled: json['chargingCompleteNotificationEnabled'] ?? false,
      
      // 충전 완료 알림 설정
      chargingCompleteNotifyOnFastCharging: json['chargingCompleteNotifyOnFastCharging'] ?? true,
      chargingCompleteNotifyOnNormalCharging: json['chargingCompleteNotifyOnNormalCharging'] ?? true,
      
      // 충전 퍼센트 알림 설정
      chargingPercentNotificationEnabled: json['chargingPercentNotificationEnabled'] ?? false,
      chargingPercentThresholds: (json['chargingPercentThresholds'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList() ?? const [],
      chargingPercentNotifyOnFastCharging: json['chargingPercentNotifyOnFastCharging'] ?? true,
      chargingPercentNotifyOnNormalCharging: json['chargingPercentNotifyOnNormalCharging'] ?? true,
      
      // 화면 표시 설정
      batteryDisplayCycleSpeed: BatteryDisplayCycleSpeed.values.firstWhere(
        (e) => e.name == json['batteryDisplayCycleSpeed'],
        orElse: () => BatteryDisplayCycleSpeed.normal,
      ),
      showChargingCurrent: json['showChargingCurrent'] ?? true,
      showBatteryPercentage: json['showBatteryPercentage'] ?? true,
      showBatteryTemperature: json['showBatteryTemperature'] ?? true,
      enableTapToSwitch: json['enableTapToSwitch'] ?? true,
      enableSwipeToSwitch: json['enableSwipeToSwitch'] ?? true,
      
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
  
  /// 설정 데이터 복사본 생성
  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? darkModeEnabled,
    String? selectedLanguage,
    bool? powerSaveModeEnabled,
    bool? batteryNotificationsEnabled,
    bool? autoOptimizationEnabled,
    bool? batteryProtectionEnabled,
    double? batteryThreshold,
    bool? smartChargingEnabled,
    bool? backgroundAppRestriction,
    bool? chargingCompleteNotificationEnabled,
    
    // 충전 완료 알림 설정
    bool? chargingCompleteNotifyOnFastCharging,
    bool? chargingCompleteNotifyOnNormalCharging,
    
    // 충전 퍼센트 알림 설정
    bool? chargingPercentNotificationEnabled,
    List<double>? chargingPercentThresholds,
    bool? chargingPercentNotifyOnFastCharging,
    bool? chargingPercentNotifyOnNormalCharging,
    
    // 화면 표시 설정
    BatteryDisplayCycleSpeed? batteryDisplayCycleSpeed,
    bool? showChargingCurrent,
    bool? showBatteryPercentage,
    bool? showBatteryTemperature,
    bool? enableTapToSwitch,
    bool? enableSwipeToSwitch,
    
    DateTime? lastUpdated,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      powerSaveModeEnabled: powerSaveModeEnabled ?? this.powerSaveModeEnabled,
      batteryNotificationsEnabled: batteryNotificationsEnabled ?? this.batteryNotificationsEnabled,
      autoOptimizationEnabled: autoOptimizationEnabled ?? this.autoOptimizationEnabled,
      batteryProtectionEnabled: batteryProtectionEnabled ?? this.batteryProtectionEnabled,
      batteryThreshold: batteryThreshold ?? this.batteryThreshold,
      smartChargingEnabled: smartChargingEnabled ?? this.smartChargingEnabled,
      backgroundAppRestriction: backgroundAppRestriction ?? this.backgroundAppRestriction,
      chargingCompleteNotificationEnabled: chargingCompleteNotificationEnabled ?? this.chargingCompleteNotificationEnabled,
      
      // 충전 완료 알림 설정
      chargingCompleteNotifyOnFastCharging: chargingCompleteNotifyOnFastCharging ?? this.chargingCompleteNotifyOnFastCharging,
      chargingCompleteNotifyOnNormalCharging: chargingCompleteNotifyOnNormalCharging ?? this.chargingCompleteNotifyOnNormalCharging,
      
      // 충전 퍼센트 알림 설정
      chargingPercentNotificationEnabled: chargingPercentNotificationEnabled ?? this.chargingPercentNotificationEnabled,
      chargingPercentThresholds: chargingPercentThresholds ?? this.chargingPercentThresholds,
      chargingPercentNotifyOnFastCharging: chargingPercentNotifyOnFastCharging ?? this.chargingPercentNotifyOnFastCharging,
      chargingPercentNotifyOnNormalCharging: chargingPercentNotifyOnNormalCharging ?? this.chargingPercentNotifyOnNormalCharging,
      
      // 화면 표시 설정
      batteryDisplayCycleSpeed: batteryDisplayCycleSpeed ?? this.batteryDisplayCycleSpeed,
      showChargingCurrent: showChargingCurrent ?? this.showChargingCurrent,
      showBatteryPercentage: showBatteryPercentage ?? this.showBatteryPercentage,
      showBatteryTemperature: showBatteryTemperature ?? this.showBatteryTemperature,
      enableTapToSwitch: enableTapToSwitch ?? this.enableTapToSwitch,
      enableSwipeToSwitch: enableSwipeToSwitch ?? this.enableSwipeToSwitch,
      
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  @override
  String toString() {
    return 'AppSettings(notifications: $notificationsEnabled, darkMode: $darkModeEnabled, language: $selectedLanguage, batteryThreshold: $formattedBatteryThreshold)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.notificationsEnabled == notificationsEnabled &&
        other.darkModeEnabled == darkModeEnabled &&
        other.selectedLanguage == selectedLanguage &&
        other.powerSaveModeEnabled == powerSaveModeEnabled &&
        other.batteryNotificationsEnabled == batteryNotificationsEnabled &&
        other.autoOptimizationEnabled == autoOptimizationEnabled &&
        other.batteryProtectionEnabled == batteryProtectionEnabled &&
        other.batteryThreshold == batteryThreshold &&
        other.smartChargingEnabled == smartChargingEnabled &&
        other.backgroundAppRestriction == backgroundAppRestriction &&
        other.chargingCompleteNotificationEnabled == chargingCompleteNotificationEnabled &&
        other.batteryDisplayCycleSpeed == batteryDisplayCycleSpeed &&
        other.showChargingCurrent == showChargingCurrent &&
        other.showBatteryPercentage == showBatteryPercentage &&
        other.showBatteryTemperature == showBatteryTemperature &&
        other.enableTapToSwitch == enableTapToSwitch &&
        other.enableSwipeToSwitch == enableSwipeToSwitch &&
        other.lastUpdated == lastUpdated;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      notificationsEnabled,
      darkModeEnabled,
      selectedLanguage,
      powerSaveModeEnabled,
      batteryNotificationsEnabled,
      autoOptimizationEnabled,
      batteryProtectionEnabled,
      batteryThreshold,
      smartChargingEnabled,
      backgroundAppRestriction,
      chargingCompleteNotificationEnabled,
      batteryDisplayCycleSpeed,
      showChargingCurrent,
      showBatteryPercentage,
      showBatteryTemperature,
      enableTapToSwitch,
      enableSwipeToSwitch,
      lastUpdated,
    );
  }
}

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
