import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../models/battery_display_models.dart';

/// 배터리 표시 정보 관리 클래스
/// 배터리 정보와 설정을 기반으로 표시할 정보를 생성하는 로직을 담당
class BatteryDisplayInfoManager {
  final BatteryInfo? batteryInfo;
  final AppSettings? settings;

  BatteryDisplayInfoManager({
    required this.batteryInfo,
    required this.settings,
  });

  /// 현재 표시할 정보 가져오기
  DisplayInfo getCurrentDisplayInfo(
    int currentIndex,
    List<DisplayInfoType> availableInfoTypes,
  ) {
    if (batteryInfo == null) {
      return DisplayInfo(
        title: '배터리',
        value: '--%',
        subtitle: '정보 없음',
        color: Colors.grey,
      );
    }

    // 표시할 정보가 없으면 기본 배터리 정보
    if (availableInfoTypes.isEmpty) {
      return DisplayInfo(
        title: '배터리',
        value: '${batteryInfo!.level.toInt()}%',
        subtitle: batteryInfo!.isCharging ? '충전 중' : '방전 중',
        color: getLevelColor(batteryInfo!.level),
        icon: batteryInfo!.isCharging ? Icons.bolt : Icons.battery_std,
      );
    }

    // 현재 인덱스를 사용 가능한 정보 범위로 조정
    final adjustedIndex = currentIndex % availableInfoTypes.length;
    final infoType = availableInfoTypes[adjustedIndex];

    switch (infoType) {
      case DisplayInfoType.batteryLevel:
        return DisplayInfo(
          title: '배터리',
          value: '${batteryInfo!.level.toInt()}%',
          subtitle: batteryInfo!.isCharging ? '충전 중' : '방전 중',
          color: getLevelColor(batteryInfo!.level),
          icon: batteryInfo!.isCharging ? Icons.bolt : Icons.battery_std,
        );

      case DisplayInfoType.chargingCurrent:
        if (batteryInfo!.isCharging) {
          final current = batteryInfo!.chargingCurrent.abs();
          final speedType = getChargingSpeedType(current);
          return DisplayInfo(
            title: '충전 속도',
            value: '${current}mA',
            subtitle: speedType.label,
            color: speedType.color,
            icon: speedType.icon,
          );
        } else {
          return DisplayInfo(
            title: '배터리',
            value: '${batteryInfo!.level.toInt()}%',
            subtitle: '방전 중',
            color: getLevelColor(batteryInfo!.level),
            icon: Icons.battery_std,
          );
        }

      case DisplayInfoType.batteryTemp:
        return DisplayInfo(
          title: '배터리 온도',
          value: batteryInfo!.formattedTemperature,
          subtitle: getTemperatureStatus(batteryInfo!.temperature),
          color: getTemperatureColor(batteryInfo!.temperature),
          icon: Icons.thermostat,
        );
    }
  }

  /// 설정에 따라 사용 가능한 정보 타입 목록 반환
  List<DisplayInfoType> getAvailableInfoTypes(bool isCharging) {
    final List<DisplayInfoType> availableTypes = [];

    // 자동 순환이 꺼져 있으면 항상 배터리 퍼센트만 표시
    if (settings?.batteryDisplayCycleSpeed == BatteryDisplayCycleSpeed.off) {
      availableTypes.add(DisplayInfoType.batteryLevel);
      return availableTypes;
    }

    // 배터리 퍼센트 표시 설정 확인
    if (settings?.showBatteryPercentage != false) {
      availableTypes.add(DisplayInfoType.batteryLevel);
    }

    // 충전 전류 표시 설정 확인 (충전 중일 때만)
    if (settings?.showChargingCurrent != false && isCharging) {
      availableTypes.add(DisplayInfoType.chargingCurrent);
    }

    // 배터리 온도 표시 설정 확인
    if (settings?.showBatteryTemperature != false) {
      availableTypes.add(DisplayInfoType.batteryTemp);
    }

    return availableTypes;
  }

  /// 충전 속도 타입 정보
  ChargingSpeedType getChargingSpeedType(int current) {
    if (current >= 2000) {
      return ChargingSpeedType(
        label: '고속 충전',
        icon: Icons.flash_on,
        color: Colors.red[400]!,
      );
    } else if (current >= 1000) {
      return ChargingSpeedType(
        label: '일반 충전',
        icon: Icons.battery_charging_full,
        color: Colors.blue[400]!,
      );
    } else {
      return ChargingSpeedType(
        label: '저속 충전',
        icon: Icons.battery_6_bar,
        color: Colors.green[400]!,
      );
    }
  }

  /// 온도 상태 텍스트
  String getTemperatureStatus(double temp) {
    if (temp < 30) return '냉각 상태';
    if (temp < 40) return '정상 온도';
    if (temp < 45) return '약간 높음';
    return '고온 주의';
  }

  /// 레벨에 따른 색상 반환
  Color getLevelColor(double level) {
    if (level > 50) return Colors.green;
    if (level > 20) return Colors.orange;
    return Colors.red;
  }

  /// 온도에 따른 색상 반환
  Color getTemperatureColor(double temp) {
    if (temp < 30) return Colors.blue;
    if (temp < 40) return Colors.green;
    if (temp < 45) return Colors.orange;
    return Colors.red;
  }
}

