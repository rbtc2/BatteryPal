import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';

/// 설정 데이터를 관리하는 서비스
class SettingsService extends ChangeNotifier {
  // 싱글톤 인스턴스
  static SettingsService? _instance;
  
  // 싱글톤 인스턴스 가져오기
  factory SettingsService() {
    _instance ??= SettingsService._internal();
    return _instance!;
  }
  
  // 내부 생성자
  SettingsService._internal();
  
  AppSettings _appSettings = AppSettings(
    notificationsEnabled: true,
    batteryNotificationsEnabled: true,
    darkModeEnabled: true,
    selectedLanguage: '한국어',
    powerSaveModeEnabled: false,
    autoOptimizationEnabled: true,
    batteryProtectionEnabled: true,
    batteryThreshold: 20.0,
    smartChargingEnabled: false,
    backgroundAppRestriction: false,
    autoBrightnessEnabled: false,
    chargingCompleteNotificationEnabled: false,
    
    // 충전 완료 알림 설정 기본값
    chargingCompleteNotifyOnFastCharging: true,
    chargingCompleteNotifyOnNormalCharging: true,
    
    // 충전 퍼센트 알림 설정 기본값
    chargingPercentNotificationEnabled: false,
    chargingPercentThresholds: const [],
    chargingPercentNotifyOnFastCharging: true,
    chargingPercentNotifyOnNormalCharging: true,
    
    // 화면 표시 설정 기본값
    batteryDisplayCycleSpeed: BatteryDisplayCycleSpeed.normal,
    showChargingCurrent: true,
    showBatteryPercentage: true,
    showBatteryTemperature: true,
    enableTapToSwitch: true,
    enableSwipeToSwitch: true,
    
    lastUpdated: DateTime.now(),
  );

  AppSettings get appSettings => _appSettings;

  /// 설정 초기화 및 로드
  Future<void> initialize() async {
    await loadSettings();
  }

  /// 설정 로드
  Future<void> loadSettings() async {
    await _loadSettingsFromPrefs();
  }

  /// 설정 저장
  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = _appSettings.toJson();
      
      // 각 설정을 개별적으로 저장 (더 간단하고 안전함)
      await prefs.setBool('notificationsEnabled', settingsJson['notificationsEnabled'] as bool);
      await prefs.setBool('batteryNotificationsEnabled', settingsJson['batteryNotificationsEnabled'] as bool);
      await prefs.setBool('darkModeEnabled', settingsJson['darkModeEnabled'] as bool);
      await prefs.setString('selectedLanguage', settingsJson['selectedLanguage'] as String);
      await prefs.setBool('powerSaveModeEnabled', settingsJson['powerSaveModeEnabled'] as bool);
      await prefs.setBool('autoOptimizationEnabled', settingsJson['autoOptimizationEnabled'] as bool);
      await prefs.setBool('batteryProtectionEnabled', settingsJson['batteryProtectionEnabled'] as bool);
      await prefs.setDouble('batteryThreshold', settingsJson['batteryThreshold'] as double);
      await prefs.setBool('smartChargingEnabled', settingsJson['smartChargingEnabled'] as bool);
      await prefs.setBool('backgroundAppRestriction', settingsJson['backgroundAppRestriction'] as bool);
      await prefs.setBool('autoBrightnessEnabled', settingsJson['autoBrightnessEnabled'] as bool);
      await prefs.setBool('chargingCompleteNotificationEnabled', settingsJson['chargingCompleteNotificationEnabled'] as bool);
      
      // 충전 완료 알림 설정
      await prefs.setBool('chargingCompleteNotifyOnFastCharging', settingsJson['chargingCompleteNotifyOnFastCharging'] as bool);
      await prefs.setBool('chargingCompleteNotifyOnNormalCharging', settingsJson['chargingCompleteNotifyOnNormalCharging'] as bool);
      
      // 네이티브 코드에서도 읽을 수 있도록 Flutter SharedPreferences에 저장됨
      // (네이티브 코드는 FlutterSharedPreferences 파일을 직접 읽음)
      
      // 충전 퍼센트 알림 설정
      await prefs.setBool('chargingPercentNotificationEnabled', settingsJson['chargingPercentNotificationEnabled'] as bool);
      await prefs.setStringList('chargingPercentThresholds', (settingsJson['chargingPercentThresholds'] as List<dynamic>).map((e) => e.toString()).toList());
      await prefs.setBool('chargingPercentNotifyOnFastCharging', settingsJson['chargingPercentNotifyOnFastCharging'] as bool);
      await prefs.setBool('chargingPercentNotifyOnNormalCharging', settingsJson['chargingPercentNotifyOnNormalCharging'] as bool);
      
      // 화면 표시 설정
      await prefs.setString('batteryDisplayCycleSpeed', settingsJson['batteryDisplayCycleSpeed'] as String);
      await prefs.setBool('showChargingCurrent', settingsJson['showChargingCurrent'] as bool);
      await prefs.setBool('showBatteryPercentage', settingsJson['showBatteryPercentage'] as bool);
      await prefs.setBool('showBatteryTemperature', settingsJson['showBatteryTemperature'] as bool);
      await prefs.setBool('enableTapToSwitch', settingsJson['enableTapToSwitch'] as bool);
      await prefs.setBool('enableSwipeToSwitch', settingsJson['enableSwipeToSwitch'] as bool);
      
    } catch (e) {
      debugPrint('설정 저장 실패: $e');
    }
  }

  /// 설정 로드 (개별 키 방식)
  Future<void> _loadSettingsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _appSettings = AppSettings(
        notificationsEnabled: prefs.getBool('notificationsEnabled') ?? true,
        batteryNotificationsEnabled: prefs.getBool('batteryNotificationsEnabled') ?? true,
        darkModeEnabled: prefs.getBool('darkModeEnabled') ?? true,
        selectedLanguage: prefs.getString('selectedLanguage') ?? '한국어',
        powerSaveModeEnabled: prefs.getBool('powerSaveModeEnabled') ?? false,
        autoOptimizationEnabled: prefs.getBool('autoOptimizationEnabled') ?? true,
        batteryProtectionEnabled: prefs.getBool('batteryProtectionEnabled') ?? true,
        batteryThreshold: prefs.getDouble('batteryThreshold') ?? 20.0,
        smartChargingEnabled: prefs.getBool('smartChargingEnabled') ?? false,
        backgroundAppRestriction: prefs.getBool('backgroundAppRestriction') ?? false,
        autoBrightnessEnabled: prefs.getBool('autoBrightnessEnabled') ?? false,
        chargingCompleteNotificationEnabled: prefs.getBool('chargingCompleteNotificationEnabled') ?? false,
        
        // 충전 완료 알림 설정
        chargingCompleteNotifyOnFastCharging: prefs.getBool('chargingCompleteNotifyOnFastCharging') ?? true,
        chargingCompleteNotifyOnNormalCharging: prefs.getBool('chargingCompleteNotifyOnNormalCharging') ?? true,
        
        // 충전 퍼센트 알림 설정
        chargingPercentNotificationEnabled: prefs.getBool('chargingPercentNotificationEnabled') ?? false,
        chargingPercentThresholds: (prefs.getStringList('chargingPercentThresholds') ?? [])
            .map((e) => double.tryParse(e) ?? 0.0)
            .where((e) => e > 0)
            .toList(),
        chargingPercentNotifyOnFastCharging: prefs.getBool('chargingPercentNotifyOnFastCharging') ?? true,
        chargingPercentNotifyOnNormalCharging: prefs.getBool('chargingPercentNotifyOnNormalCharging') ?? true,
        
        batteryDisplayCycleSpeed: BatteryDisplayCycleSpeed.values.firstWhere(
          (e) => e.name == prefs.getString('batteryDisplayCycleSpeed'),
          orElse: () => BatteryDisplayCycleSpeed.normal,
        ),
        showChargingCurrent: prefs.getBool('showChargingCurrent') ?? true,
        showBatteryPercentage: prefs.getBool('showBatteryPercentage') ?? true,
        showBatteryTemperature: prefs.getBool('showBatteryTemperature') ?? true,
        enableTapToSwitch: prefs.getBool('enableTapToSwitch') ?? true,
        enableSwipeToSwitch: prefs.getBool('enableSwipeToSwitch') ?? true,
        
        lastUpdated: DateTime.now(),
      );
      
      notifyListeners();
    } catch (e) {
      debugPrint('설정 로드 실패: $e');
    }
  }

  /// 알림 설정 토글
  void toggleNotifications() {
    _appSettings = _appSettings.copyWith(
      notificationsEnabled: !_appSettings.notificationsEnabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 테마 설정 토글
  void toggleTheme() {
    _appSettings = _appSettings.copyWith(
      darkModeEnabled: !_appSettings.darkModeEnabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 언어 설정 변경
  void updateLanguage(String language) {
    _appSettings = _appSettings.copyWith(
      selectedLanguage: language,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 절전 모드 설정 변경
  void updatePowerSaveMode(bool enabled) {
    _appSettings = _appSettings.copyWith(
      powerSaveModeEnabled: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 백그라운드 앱 제한 설정 변경
  void updateBackgroundAppRestriction(bool enabled) {
    _appSettings = _appSettings.copyWith(
      backgroundAppRestriction: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 화면 밝기 자동 조절 설정 변경
  void updateAutoBrightness(bool enabled) {
    _appSettings = _appSettings.copyWith(
      autoBrightnessEnabled: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 배터리 알림 설정 변경
  void updateBatteryNotifications(bool enabled) {
    _appSettings = _appSettings.copyWith(
      batteryNotificationsEnabled: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 배터리 임계값 설정 변경
  void updateBatteryThreshold(double threshold) {
    _appSettings = _appSettings.copyWith(
      batteryThreshold: threshold,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 충전 완료 알림 설정 변경
  void updateChargingCompleteNotification(bool enabled) {
    _appSettings = _appSettings.copyWith(
      chargingCompleteNotificationEnabled: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 충전 완료 알림 - 고속 충전 설정 변경
  void updateChargingCompleteNotifyOnFastCharging(bool enabled) {
    _appSettings = _appSettings.copyWith(
      chargingCompleteNotifyOnFastCharging: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 충전 완료 알림 - 일반 충전 설정 변경
  void updateChargingCompleteNotifyOnNormalCharging(bool enabled) {
    _appSettings = _appSettings.copyWith(
      chargingCompleteNotifyOnNormalCharging: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 충전 퍼센트 알림 활성화 설정 변경
  void updateChargingPercentNotification(bool enabled) {
    _appSettings = _appSettings.copyWith(
      chargingPercentNotificationEnabled: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 충전 퍼센트 알림 - 고속 충전 설정 변경
  void updateChargingPercentNotifyOnFastCharging(bool enabled) {
    _appSettings = _appSettings.copyWith(
      chargingPercentNotifyOnFastCharging: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 충전 퍼센트 알림 - 일반 충전 설정 변경
  void updateChargingPercentNotifyOnNormalCharging(bool enabled) {
    _appSettings = _appSettings.copyWith(
      chargingPercentNotifyOnNormalCharging: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 충전 퍼센트 알림 임계값 추가
  void addChargingPercentThreshold(double threshold) {
    final thresholds = List<double>.from(_appSettings.chargingPercentThresholds);
    if (!thresholds.contains(threshold)) {
      thresholds.add(threshold);
      thresholds.sort((a, b) => b.compareTo(a)); // 내림차순 정렬
      _appSettings = _appSettings.copyWith(
        chargingPercentThresholds: thresholds,
        lastUpdated: DateTime.now(),
      );
      notifyListeners();
      _autoSave();
    }
  }

  /// 충전 퍼센트 알림 임계값 제거
  void removeChargingPercentThreshold(double threshold) {
    final thresholds = List<double>.from(_appSettings.chargingPercentThresholds);
    thresholds.remove(threshold);
    _appSettings = _appSettings.copyWith(
      chargingPercentThresholds: thresholds,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 자동 최적화 설정 변경
  void updateAutoOptimization(bool enabled) {
    _appSettings = _appSettings.copyWith(
      autoOptimizationEnabled: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 스마트 충전 설정 변경
  void updateSmartCharging(bool enabled) {
    _appSettings = _appSettings.copyWith(
      smartChargingEnabled: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 배터리 보호 설정 변경
  void updateBatteryProtection(bool enabled) {
    _appSettings = _appSettings.copyWith(
      batteryProtectionEnabled: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 배터리 표시 순환 속도 설정 변경
  void updateBatteryDisplayCycleSpeed(BatteryDisplayCycleSpeed speed) {
    _appSettings = _appSettings.copyWith(
      batteryDisplayCycleSpeed: speed,
      lastUpdated: DateTime.now(),
    );
    
    // 자동 순환이 꺼지면 모든 관련 설정도 비활성화
    if (speed == BatteryDisplayCycleSpeed.off) {
      _appSettings = _appSettings.copyWith(
        showChargingCurrent: false,
        showBatteryPercentage: false,
        enableTapToSwitch: false,
        enableSwipeToSwitch: false,
        lastUpdated: DateTime.now(),
      );
    }
    
    notifyListeners();
    _autoSave();
  }

  /// 충전 전류 표시 설정 변경
  void updateShowChargingCurrent(bool enabled) {
    _appSettings = _appSettings.copyWith(
      showChargingCurrent: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 배터리 퍼센트 표시 설정 변경
  void updateShowBatteryPercentage(bool enabled) {
    _appSettings = _appSettings.copyWith(
      showBatteryPercentage: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 배터리 온도 표시 설정 변경
  void updateShowBatteryTemperature(bool enabled) {
    _appSettings = _appSettings.copyWith(
      showBatteryTemperature: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 탭으로 전환 설정 변경
  void updateEnableTapToSwitch(bool enabled) {
    _appSettings = _appSettings.copyWith(
      enableTapToSwitch: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 스와이프로 전환 설정 변경
  void updateEnableSwipeToSwitch(bool enabled) {
    _appSettings = _appSettings.copyWith(
      enableSwipeToSwitch: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 설정 초기화
  void resetToDefaults() {
    _appSettings = AppSettings(
      notificationsEnabled: true,
      batteryNotificationsEnabled: true,
      darkModeEnabled: true,
      selectedLanguage: '한국어',
      powerSaveModeEnabled: false,
      autoOptimizationEnabled: true,
      batteryProtectionEnabled: true,
      batteryThreshold: 20.0,
      smartChargingEnabled: false,
      backgroundAppRestriction: false,
      autoBrightnessEnabled: false,
      chargingCompleteNotificationEnabled: false,
      
      // 충전 완료 알림 설정 기본값
      chargingCompleteNotifyOnFastCharging: true,
      chargingCompleteNotifyOnNormalCharging: true,
      
      // 충전 퍼센트 알림 설정 기본값
      chargingPercentNotificationEnabled: false,
      chargingPercentThresholds: const [],
      chargingPercentNotifyOnFastCharging: true,
      chargingPercentNotifyOnNormalCharging: true,
      
      // 화면 표시 설정 기본값
      batteryDisplayCycleSpeed: BatteryDisplayCycleSpeed.normal,
      showChargingCurrent: true,
      showBatteryPercentage: true,
      showBatteryTemperature: true,
      enableTapToSwitch: true,
      enableSwipeToSwitch: true,
      
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  /// 자동 저장 (비동기, 에러 무시)
  void _autoSave() {
    saveSettings().catchError((e) => debugPrint('자동 저장 실패: $e'));
  }

  /// dispose 오버라이드 - 싱글톤이므로 아무것도 하지 않음
  /// 각 화면에서 dispose를 호출해도 인스턴스와 리스너는 유지됨
  @override
  // ignore: must_call_super
  void dispose() {
    // 싱글톤이므로 dispose를 호출해도 인스턴스와 리스너를 유지
    // 앱이 종료될 때까지 설정 서비스는 유지되어야 함
    // super.dispose()를 호출하지 않음 (의도적으로 무시)
  }
}
