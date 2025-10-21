// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'battery_history_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BatteryHistoryDataPoint _$BatteryHistoryDataPointFromJson(
  Map<String, dynamic> json,
) => BatteryHistoryDataPoint(
  id: (json['id'] as num?)?.toInt(),
  timestamp: DateTime.parse(json['timestamp'] as String),
  level: (json['level'] as num).toDouble(),
  state: $enumDecode(_$BatteryStateEnumMap, json['state']),
  temperature: (json['temperature'] as num).toDouble(),
  voltage: (json['voltage'] as num).toInt(),
  capacity: (json['capacity'] as num).toInt(),
  health: (json['health'] as num).toInt(),
  chargingType: json['chargingType'] as String,
  chargingCurrent: (json['chargingCurrent'] as num).toInt(),
  isCharging: json['isCharging'] as bool,
  isAppInForeground: json['isAppInForeground'] as bool,
  collectionMethod: json['collectionMethod'] as String,
  dataQuality: (json['dataQuality'] as num).toDouble(),
);

Map<String, dynamic> _$BatteryHistoryDataPointToJson(
  BatteryHistoryDataPoint instance,
) => <String, dynamic>{
  'id': instance.id,
  'timestamp': instance.timestamp.toIso8601String(),
  'level': instance.level,
  'state': _$BatteryStateEnumMap[instance.state]!,
  'temperature': instance.temperature,
  'voltage': instance.voltage,
  'capacity': instance.capacity,
  'health': instance.health,
  'chargingType': instance.chargingType,
  'chargingCurrent': instance.chargingCurrent,
  'isCharging': instance.isCharging,
  'isAppInForeground': instance.isAppInForeground,
  'collectionMethod': instance.collectionMethod,
  'dataQuality': instance.dataQuality,
};

const _$BatteryStateEnumMap = {
  BatteryState.full: 'full',
  BatteryState.charging: 'charging',
  BatteryState.discharging: 'discharging',
  BatteryState.unknown: 'unknown',
};

BatteryHistoryAnalysis _$BatteryHistoryAnalysisFromJson(
  Map<String, dynamic> json,
) => BatteryHistoryAnalysis(
  analysisStartTime: DateTime.parse(json['analysisStartTime'] as String),
  analysisEndTime: DateTime.parse(json['analysisEndTime'] as String),
  dataPointCount: (json['dataPointCount'] as num).toInt(),
  analysisDurationHours: (json['analysisDurationHours'] as num).toDouble(),
  averageBatteryLevel: (json['averageBatteryLevel'] as num).toDouble(),
  minBatteryLevel: (json['minBatteryLevel'] as num).toDouble(),
  maxBatteryLevel: (json['maxBatteryLevel'] as num).toDouble(),
  batteryVariation: (json['batteryVariation'] as num).toDouble(),
  averageDischargeRate: (json['averageDischargeRate'] as num).toDouble(),
  averageChargeRate: (json['averageChargeRate'] as num).toDouble(),
  chargingSessions: (json['chargingSessions'] as num).toInt(),
  averageChargingSessionMinutes: (json['averageChargingSessionMinutes'] as num)
      .toDouble(),
  overallDataQuality: (json['overallDataQuality'] as num).toDouble(),
  insights: (json['insights'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  recommendations: (json['recommendations'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  patternAnalysis: json['patternAnalysis'] as Map<String, dynamic>,
  chargingEvents: (json['chargingEvents'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  dischargingEvents: (json['dischargingEvents'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  patternSummary: json['patternSummary'] as String,
);

Map<String, dynamic> _$BatteryHistoryAnalysisToJson(
  BatteryHistoryAnalysis instance,
) => <String, dynamic>{
  'analysisStartTime': instance.analysisStartTime.toIso8601String(),
  'analysisEndTime': instance.analysisEndTime.toIso8601String(),
  'dataPointCount': instance.dataPointCount,
  'analysisDurationHours': instance.analysisDurationHours,
  'averageBatteryLevel': instance.averageBatteryLevel,
  'minBatteryLevel': instance.minBatteryLevel,
  'maxBatteryLevel': instance.maxBatteryLevel,
  'batteryVariation': instance.batteryVariation,
  'averageDischargeRate': instance.averageDischargeRate,
  'averageChargeRate': instance.averageChargeRate,
  'chargingSessions': instance.chargingSessions,
  'averageChargingSessionMinutes': instance.averageChargingSessionMinutes,
  'overallDataQuality': instance.overallDataQuality,
  'insights': instance.insights,
  'recommendations': instance.recommendations,
  'patternAnalysis': instance.patternAnalysis,
  'chargingEvents': instance.chargingEvents,
  'dischargingEvents': instance.dischargingEvents,
  'patternSummary': instance.patternSummary,
};
