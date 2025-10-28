import 'package:flutter/foundation.dart';
import '../models/app_models.dart';

/// 설정 데이터를 관리하는 서비스
class SettingsService extends ChangeNotifier {
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
    chargingCompleteNotificationEnabled: false,
    
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

  /// 알림 설정 토글
  void toggleNotifications() {
    _appSettings = _appSettings.copyWith(
      notificationsEnabled: !_appSettings.notificationsEnabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  /// 테마 설정 토글
  void toggleTheme() {
    _appSettings = _appSettings.copyWith(
      darkModeEnabled: !_appSettings.darkModeEnabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  /// 언어 설정 변경
  void updateLanguage(String language) {
    _appSettings = _appSettings.copyWith(
      selectedLanguage: language,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  /// 절전 모드 설정 변경
  void updatePowerSaveMode(bool enabled) {
    _appSettings = _appSettings.copyWith(
      powerSaveModeEnabled: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  /// 백그라운드 앱 제한 설정 변경
  void updateBackgroundAppRestriction(bool enabled) {
    _appSettings = _appSettings.copyWith(
      backgroundAppRestriction: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  /// 배터리 알림 설정 변경
  void updateBatteryNotifications(bool enabled) {
    _appSettings = _appSettings.copyWith(
      batteryNotificationsEnabled: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  /// 배터리 임계값 설정 변경
  void updateBatteryThreshold(double threshold) {
    _appSettings = _appSettings.copyWith(
      batteryThreshold: threshold,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  /// 충전 완료 알림 설정 변경
  void updateChargingCompleteNotification(bool enabled) {
    _appSettings = _appSettings.copyWith(
      chargingCompleteNotificationEnabled: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  /// 자동 최적화 설정 변경
  void updateAutoOptimization(bool enabled) {
    _appSettings = _appSettings.copyWith(
      autoOptimizationEnabled: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  /// 스마트 충전 설정 변경
  void updateSmartCharging(bool enabled) {
    _appSettings = _appSettings.copyWith(
      smartChargingEnabled: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  /// 배터리 보호 설정 변경
  void updateBatteryProtection(bool enabled) {
    _appSettings = _appSettings.copyWith(
      batteryProtectionEnabled: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
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
  }

  /// 충전 전류 표시 설정 변경
  void updateShowChargingCurrent(bool enabled) {
    _appSettings = _appSettings.copyWith(
      showChargingCurrent: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  /// 배터리 퍼센트 표시 설정 변경
  void updateShowBatteryPercentage(bool enabled) {
    _appSettings = _appSettings.copyWith(
      showBatteryPercentage: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  /// 배터리 온도 표시 설정 변경
  void updateShowBatteryTemperature(bool enabled) {
    _appSettings = _appSettings.copyWith(
      showBatteryTemperature: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  /// 탭으로 전환 설정 변경
  void updateEnableTapToSwitch(bool enabled) {
    _appSettings = _appSettings.copyWith(
      enableTapToSwitch: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  /// 스와이프로 전환 설정 변경
  void updateEnableSwipeToSwitch(bool enabled) {
    _appSettings = _appSettings.copyWith(
      enableSwipeToSwitch: enabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
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
      chargingCompleteNotificationEnabled: false,
      
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
  }
}
