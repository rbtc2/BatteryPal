import 'battery_display_cycle_speed.dart';
import 'charging_monitor_display_mode.dart';
import 'charging_graph_theme.dart';

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
  final bool autoBrightnessEnabled; // 화면 밝기 자동 조절 활성화
  final bool chargingCompleteNotificationEnabled; // 충전 완료 알림 활성화
  final bool backgroundDataCollectionEnabled; // Phase 4: 백그라운드 데이터 수집 활성화
  final bool developerModeChargingTestEnabled; // 개발자 모드: 백그라운드 충전 감지 테스트 알림
  
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
  
  // 실시간 충전 모니터 표시 설정
  final ChargingMonitorDisplayMode chargingMonitorDisplayMode; // 충전 모니터 표시 방식
  final ChargingGraphTheme chargingGraphTheme; // 충전 그래프 테마
  
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
    this.autoBrightnessEnabled = false, // 기본값: false
    this.chargingCompleteNotificationEnabled = false, // 기본값: false (Pro 기능)
    this.backgroundDataCollectionEnabled = true, // Phase 4: 기본값: true (백그라운드 수집 활성화)
    this.developerModeChargingTestEnabled = false, // 기본값: false (개발자 모드)
    
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
    
    // 실시간 충전 모니터 표시 설정 기본값
    this.chargingMonitorDisplayMode = ChargingMonitorDisplayMode.currentOnly,
    this.chargingGraphTheme = ChargingGraphTheme.ecg, // 기본값: 심전도
    
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
      'autoBrightnessEnabled': autoBrightnessEnabled,
      'chargingCompleteNotificationEnabled': chargingCompleteNotificationEnabled,
      'backgroundDataCollectionEnabled': backgroundDataCollectionEnabled, // Phase 4
      'developerModeChargingTestEnabled': developerModeChargingTestEnabled,
      
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
      
      // 실시간 충전 모니터 표시 설정
      'chargingMonitorDisplayMode': chargingMonitorDisplayMode.name,
      'chargingGraphTheme': chargingGraphTheme.name,
      
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
      autoBrightnessEnabled: json['autoBrightnessEnabled'] ?? false,
      chargingCompleteNotificationEnabled: json['chargingCompleteNotificationEnabled'] ?? false,
      backgroundDataCollectionEnabled: json['backgroundDataCollectionEnabled'] ?? true, // Phase 4
      developerModeChargingTestEnabled: json['developerModeChargingTestEnabled'] ?? false,
      
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
      
      // 실시간 충전 모니터 표시 설정
      chargingMonitorDisplayMode: ChargingMonitorDisplayMode.values.firstWhere(
        (e) => e.name == json['chargingMonitorDisplayMode'],
        orElse: () => ChargingMonitorDisplayMode.currentOnly,
      ),
      chargingGraphTheme: () {
        final themeName = json['chargingGraphTheme'];
        if (themeName == null) {
          return ChargingGraphTheme.ecg;
        }
        // 삭제된 테마들을 사용 중인 경우 ECG로 fallback
        if (themeName == 'oscilloscope' || themeName == 'bar' || themeName == 'electric' || themeName == 'particle' || themeName == 'dna') {
          return ChargingGraphTheme.ecg;
        }
        return ChargingGraphTheme.values.firstWhere(
          (e) => e.name == themeName,
          orElse: () => ChargingGraphTheme.ecg,
        );
      }(),
      
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
    bool? autoBrightnessEnabled,
    bool? chargingCompleteNotificationEnabled,
    bool? backgroundDataCollectionEnabled, // Phase 4
    bool? developerModeChargingTestEnabled,
    
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
    
    // 실시간 충전 모니터 표시 설정
    ChargingMonitorDisplayMode? chargingMonitorDisplayMode,
    ChargingGraphTheme? chargingGraphTheme,
    
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
      autoBrightnessEnabled: autoBrightnessEnabled ?? this.autoBrightnessEnabled,
      chargingCompleteNotificationEnabled: chargingCompleteNotificationEnabled ?? this.chargingCompleteNotificationEnabled,
      backgroundDataCollectionEnabled: backgroundDataCollectionEnabled ?? this.backgroundDataCollectionEnabled, // Phase 4
      developerModeChargingTestEnabled: developerModeChargingTestEnabled ?? this.developerModeChargingTestEnabled,
      
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
      
      // 실시간 충전 모니터 표시 설정
      chargingMonitorDisplayMode: chargingMonitorDisplayMode ?? this.chargingMonitorDisplayMode,
      chargingGraphTheme: chargingGraphTheme ?? this.chargingGraphTheme,
      
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
        other.autoBrightnessEnabled == autoBrightnessEnabled &&
        other.chargingCompleteNotificationEnabled == chargingCompleteNotificationEnabled &&
        other.batteryDisplayCycleSpeed == batteryDisplayCycleSpeed &&
        other.showChargingCurrent == showChargingCurrent &&
        other.showBatteryPercentage == showBatteryPercentage &&
        other.showBatteryTemperature == showBatteryTemperature &&
        other.enableTapToSwitch == enableTapToSwitch &&
        other.enableSwipeToSwitch == enableSwipeToSwitch &&
        other.chargingMonitorDisplayMode == chargingMonitorDisplayMode &&
        other.chargingGraphTheme == chargingGraphTheme &&
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
      chargingMonitorDisplayMode,
      chargingGraphTheme,
      lastUpdated,
    );
  }
}

