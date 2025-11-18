import '../../../services/settings_service.dart';
import '../../../models/models.dart';

/// 기능 설정 탭의 subtitle 생성 헬퍼 클래스
class FeaturesSettingsSubtitleHelper {
  final SettingsService settingsService;

  FeaturesSettingsSubtitleHelper(this.settingsService);

  String getBatteryDisplaySubtitle() {
    final speed = settingsService.appSettings.batteryDisplayCycleSpeed;
    if (speed == BatteryDisplayCycleSpeed.off) {
      return '자동 순환 끄기';
    }
    final speedText = speed.displayName;
    final enabledCount = [
      settingsService.appSettings.showChargingCurrent,
      settingsService.appSettings.showBatteryPercentage,
      settingsService.appSettings.showBatteryTemperature,
    ].where((e) => e).length;
    return '$speedText 속도, $enabledCount개 정보 표시';
  }

  String getChargingMonitorDisplaySubtitle() {
    return settingsService.appSettings.chargingMonitorDisplayMode.displayName;
  }

  String getChargingCompleteNotificationSubtitle() {
    final enabled = settingsService.appSettings.chargingCompleteNotificationEnabled;
    if (!enabled) return '비활성화';
    
    final fast = settingsService.appSettings.chargingCompleteNotifyOnFastCharging;
    final normal = settingsService.appSettings.chargingCompleteNotifyOnNormalCharging;
    
    if (fast && normal) return '모든 충전 타입';
    if (fast) return '고속 충전만';
    if (normal) return '일반 충전만';
    return '설정 필요';
  }

  String getChargingPercentNotificationSubtitle() {
    final enabled = settingsService.appSettings.chargingPercentNotificationEnabled;
    if (!enabled) return '비활성화';
    
    final thresholds = settingsService.appSettings.chargingPercentThresholds;
    if (thresholds.isEmpty) return '알림 퍼센트 없음';
    if (thresholds.length == 1) return '${thresholds.first.toInt()}% 알림';
    return '${thresholds.length}개 퍼센트 알림';
  }

  String getBatteryOptimizationSubtitle() {
    return '배터리 최적화에서 제외 설정';
  }
}

