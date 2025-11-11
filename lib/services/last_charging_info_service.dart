// 마지막 충전 정보 저장 및 조회 서비스
// 홈 화면의 "마지막 충전 정보" 카드에 표시할 데이터를 관리

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 충전 속도 분류
enum ChargingSpeed {
  /// 저속 충전: 0 ~ 999mA
  slow,
  
  /// 일반 충전: 1000 ~ 1999mA
  normal,
  
  /// 고속 충전: 2000 ~ 2999mA
  fast,
  
  /// 초고속 충전: 3000mA 이상
  superFast,
}

/// 마지막 충전 정보 모델
class LastChargingInfo {
  /// 충전 종료 시간
  final DateTime endTime;
  
  /// 충전 속도 분류
  final ChargingSpeed speed;
  
  /// 충전 종료 시 배터리 레벨 (%)
  final double batteryLevel;
  
  /// 평균 충전 전류 (mA)
  final int avgCurrent;

  LastChargingInfo({
    required this.endTime,
    required this.speed,
    required this.batteryLevel,
    required this.avgCurrent,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'endTime': endTime.toIso8601String(),
      'speed': speed.name,
      'batteryLevel': batteryLevel,
      'avgCurrent': avgCurrent,
    };
  }

  /// JSON에서 생성
  factory LastChargingInfo.fromJson(Map<String, dynamic> json) {
    return LastChargingInfo(
      endTime: DateTime.parse(json['endTime'] as String),
      speed: ChargingSpeed.values.firstWhere(
        (e) => e.name == json['speed'],
        orElse: () => ChargingSpeed.normal,
      ),
      batteryLevel: (json['batteryLevel'] as num).toDouble(),
      avgCurrent: json['avgCurrent'] as int,
    );
  }
}

/// 마지막 충전 정보 서비스 (싱글톤)
class LastChargingInfoService {
  // 싱글톤 인스턴스
  static final LastChargingInfoService _instance = 
      LastChargingInfoService._internal();
  factory LastChargingInfoService() => _instance;
  LastChargingInfoService._internal();

  static const String _prefsKey = 'last_charging_info';

  /// 마지막 충전 정보 저장
  Future<void> saveLastChargingInfo({
    required DateTime endTime,
    required int avgCurrent,
    required double batteryLevel,
  }) async {
    try {
      final speed = _classifyChargingSpeed(avgCurrent);
      
      final info = LastChargingInfo(
        endTime: endTime,
        speed: speed,
        batteryLevel: batteryLevel,
        avgCurrent: avgCurrent,
      );

      final prefs = await SharedPreferences.getInstance();
      final jsonMap = info.toJson();
      
      // JSON을 문자열로 변환하여 저장
      final jsonString = jsonEncode(jsonMap);
      await prefs.setString(_prefsKey, jsonString);
      
      debugPrint('LastChargingInfoService: 마지막 충전 정보 저장 완료 - '
          '종료 시간: ${endTime.toString()}, '
          '속도: ${speed.name}, '
          '배터리: ${batteryLevel.toStringAsFixed(1)}%, '
          '평균 전류: ${avgCurrent}mA');
    } catch (e) {
      debugPrint('LastChargingInfoService: 마지막 충전 정보 저장 실패 - $e');
    }
  }

  /// 마지막 충전 정보 조회
  Future<LastChargingInfo?> getLastChargingInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      
      if (jsonString == null) {
        return null;
      }
      
      // JSON 파싱
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return LastChargingInfo.fromJson(json);
    } catch (e) {
      debugPrint('LastChargingInfoService: 마지막 충전 정보 조회 실패 - $e');
      return null;
    }
  }

  /// 충전 속도 분류
  ChargingSpeed _classifyChargingSpeed(int avgCurrent) {
    if (avgCurrent >= 3000) {
      return ChargingSpeed.superFast;
    } else if (avgCurrent >= 2000) {
      return ChargingSpeed.fast;
    } else if (avgCurrent >= 1000) {
      return ChargingSpeed.normal;
    } else {
      return ChargingSpeed.slow;
    }
  }

  /// 충전 속도 분류 텍스트
  String getSpeedText(ChargingSpeed speed) {
    switch (speed) {
      case ChargingSpeed.slow:
        return '저속 충전';
      case ChargingSpeed.normal:
        return '일반 충전';
      case ChargingSpeed.fast:
        return '고속 충전';
      case ChargingSpeed.superFast:
        return '초고속 충전';
    }
  }
}

