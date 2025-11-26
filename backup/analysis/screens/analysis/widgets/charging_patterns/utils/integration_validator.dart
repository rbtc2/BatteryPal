// 통합 테스트 및 검증 유틸리티
// PHASE 6.4: 충전 세션 서비스의 통합 상태를 검증하는 유틸리티

import 'package:flutter/foundation.dart';
import '../services/charging_session_service.dart';
import '../services/charging_session_storage.dart';
import '../config/charging_session_config.dart';

/// 통합 검증 결과 모델
class IntegrationValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final Map<String, dynamic> details;

  IntegrationValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.details = const {},
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('통합 검증 결과: ${isValid ? "✅ 통과" : "❌ 실패"}');
    if (errors.isNotEmpty) {
      buffer.writeln('에러:');
      for (final error in errors) {
        buffer.writeln('  - $error');
      }
    }
    if (warnings.isNotEmpty) {
      buffer.writeln('경고:');
      for (final warning in warnings) {
        buffer.writeln('  - $warning');
      }
    }
    if (details.isNotEmpty) {
      buffer.writeln('상세 정보:');
      details.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }
    return buffer.toString();
  }
}

/// 통합 검증 유틸리티 클래스
class IntegrationValidator {
  IntegrationValidator._(); // private constructor

  /// 전체 통합 상태 검증
  static Future<IntegrationValidationResult> validateIntegration() async {
    final errors = <String>[];
    final warnings = <String>[];
    final details = <String, dynamic>{};

    try {
      // 1. 서비스 초기화 상태 검증
      final sessionService = ChargingSessionService();
      final storageService = ChargingSessionStorage();

      if (!sessionService.isInitialized) {
        errors.add('ChargingSessionService가 초기화되지 않았습니다');
      } else {
        details['sessionServiceInitialized'] = true;
      }

      if (!storageService.isInitialized) {
        errors.add('ChargingSessionStorage가 초기화되지 않았습니다');
      } else {
        details['storageServiceInitialized'] = true;
      }

      // 2. 데이터 일관성 검증 (메모리 vs DB)
      final consistencyResult = await _validateDataConsistency();
      if (!consistencyResult.isValid) {
        errors.addAll(consistencyResult.errors);
        warnings.addAll(consistencyResult.warnings);
      }
      details['dataConsistency'] = consistencyResult.details;

      // 3. 세션 유효성 검증
      final validityResult = await _validateSessionValidity();
      if (!validityResult.isValid) {
        warnings.addAll(validityResult.warnings);
      }
      details['sessionValidity'] = validityResult.details;

      // 4. 메모리 사용량 검증
      final memoryResult = _validateMemoryUsage();
      if (!memoryResult.isValid) {
        warnings.addAll(memoryResult.warnings);
      }
      details['memoryUsage'] = memoryResult.details;

      // 5. 날짜 변경 감지 검증
      final dateChangeResult = _validateDateChangeDetection();
      if (!dateChangeResult.isValid) {
        warnings.addAll(dateChangeResult.warnings);
      }
      details['dateChangeDetection'] = dateChangeResult.details;

    } catch (e, stackTrace) {
      errors.add('통합 검증 중 예외 발생: $e');
      debugPrint('통합 검증 예외 스택 트레이스: $stackTrace');
    }

    return IntegrationValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      details: details,
    );
  }

  /// 데이터 일관성 검증 (메모리 vs DB)
  static Future<IntegrationValidationResult> _validateDataConsistency() async {
    final errors = <String>[];
    final warnings = <String>[];
    final details = <String, dynamic>{};

    try {
      final sessionService = ChargingSessionService();
      final storageService = ChargingSessionStorage();

      // 메모리의 세션 목록
      final memorySessions = sessionService.getTodaySessions();
      details['memorySessionCount'] = memorySessions.length;

      // DB의 세션 목록
      final dbSessions = await storageService.getTodaySessions();
      details['dbSessionCount'] = dbSessions.length;

      // 세션 ID 비교
      final memoryIds = memorySessions.map((s) => s.id).toSet();
      final dbIds = dbSessions.map((s) => s.id).toSet();

      // 메모리에만 있는 세션
      final onlyInMemory = memoryIds.difference(dbIds);
      if (onlyInMemory.isNotEmpty) {
        warnings.add('메모리에만 있는 세션 ${onlyInMemory.length}개 (아직 DB에 저장되지 않음)');
        details['onlyInMemorySessions'] = onlyInMemory.length;
      }

      // DB에만 있는 세션
      final onlyInDb = dbIds.difference(memoryIds);
      if (onlyInDb.isNotEmpty) {
        warnings.add('DB에만 있는 세션 ${onlyInDb.length}개 (메모리 동기화 필요)');
        details['onlyInDbSessions'] = onlyInDb.length;
      }

      // 공통 세션의 데이터 일관성 검증
      final commonIds = memoryIds.intersection(dbIds);
      int inconsistentCount = 0;
      for (final id in commonIds) {
        final memorySession = memorySessions.firstWhere((s) => s.id == id);
        final dbSession = dbSessions.firstWhere((s) => s.id == id);

        // 주요 필드 비교
        if (memorySession.startTime != dbSession.startTime ||
            memorySession.endTime != dbSession.endTime ||
            (memorySession.batteryChange - dbSession.batteryChange).abs() > 0.1) {
          inconsistentCount++;
        }
      }

      if (inconsistentCount > 0) {
        errors.add('데이터 불일치: $inconsistentCount개 세션의 데이터가 메모리와 DB 간 불일치');
        details['inconsistentSessions'] = inconsistentCount;
      } else {
        details['consistentSessions'] = commonIds.length;
      }

    } catch (e, stackTrace) {
      errors.add('데이터 일관성 검증 실패: $e');
      debugPrint('데이터 일관성 검증 스택 트레이스: $stackTrace');
    }

    return IntegrationValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      details: details,
    );
  }

  /// 세션 유효성 검증
  static Future<IntegrationValidationResult> _validateSessionValidity() async {
    final warnings = <String>[];
    final details = <String, dynamic>{};

    try {
      final sessionService = ChargingSessionService();
      final sessions = await sessionService.getTodaySessionsAsync();

      int invalidCount = 0;
      int validCount = 0;

      for (final session in sessions) {
        if (!session.validate()) {
          invalidCount++;
        } else {
          validCount++;
        }
      }

      details['totalSessions'] = sessions.length;
      details['validSessions'] = validCount;
      details['invalidSessions'] = invalidCount;

      if (invalidCount > 0) {
        warnings.add('유효하지 않은 세션 $invalidCount개 발견');
      }

    } catch (e, stackTrace) {
      warnings.add('세션 유효성 검증 실패: $e');
      debugPrint('세션 유효성 검증 스택 트레이스: $stackTrace');
    }

    return IntegrationValidationResult(
      isValid: true,
      warnings: warnings,
      details: details,
    );
  }

  /// 메모리 사용량 검증
  static IntegrationValidationResult _validateMemoryUsage() {
    final warnings = <String>[];
    final details = <String, dynamic>{};

    try {
      final storageService = ChargingSessionStorage();
      final storedDateKeys = storageService.getStoredDateKeys();
      final todaySessionCount = storageService.todaySessionCount;

      details['storedDateCount'] = storedDateKeys.length;
      details['todaySessionCount'] = todaySessionCount;

      // 7일 이상 된 데이터가 메모리에 있는지 확인
      final now = DateTime.now();
      final cutoffDate = now.subtract(Duration(days: ChargingSessionConfig.sessionRetentionDays));
      int oldDataCount = 0;

      for (final dateKey in storedDateKeys) {
        try {
          final date = DateTime.parse(dateKey);
          if (date.isBefore(cutoffDate)) {
            oldDataCount++;
          }
        } catch (e) {
          // 날짜 파싱 실패는 무시
        }
      }

      if (oldDataCount > 0) {
        warnings.add('7일 이상 된 데이터가 메모리에 $oldDataCount개 날짜 남아있음 (정리 필요)');
        details['oldDataCount'] = oldDataCount;
      }

      // 오늘 세션 개수가 너무 많으면 경고
      if (todaySessionCount > 50) {
        warnings.add('오늘 세션 개수가 많음 ($todaySessionCount개) - 메모리 사용량 주의');
      }

    } catch (e, stackTrace) {
      warnings.add('메모리 사용량 검증 실패: $e');
      debugPrint('메모리 사용량 검증 스택 트레이스: $stackTrace');
    }

    return IntegrationValidationResult(
      isValid: true,
      warnings: warnings,
      details: details,
    );
  }

  /// 날짜 변경 감지 검증
  static IntegrationValidationResult _validateDateChangeDetection() {
    final warnings = <String>[];
    final details = <String, dynamic>{};

    try {
      final sessionService = ChargingSessionService();
      final storageService = ChargingSessionStorage();

      // 서비스가 초기화되어 있는지 확인
      if (!sessionService.isInitialized || !storageService.isInitialized) {
        warnings.add('서비스가 초기화되지 않아 날짜 변경 감지 검증 불가');
        return IntegrationValidationResult(
          isValid: false,
          warnings: warnings,
          details: details,
        );
      }

      // 현재 날짜 확인
      final now = DateTime.now();
      final todayKey = _getDateKey(now);
      details['todayKey'] = todayKey;

      // 메모리에 저장된 날짜 목록 확인
      final storedDateKeys = storageService.getStoredDateKeys();
      details['storedDateKeys'] = storedDateKeys;

      // 오늘 날짜가 메모리에 있는지 확인
      if (!storedDateKeys.contains(todayKey)) {
        warnings.add('오늘 날짜의 데이터가 메모리에 없음');
      }

    } catch (e, stackTrace) {
      warnings.add('날짜 변경 감지 검증 실패: $e');
      debugPrint('날짜 변경 감지 검증 스택 트레이스: $stackTrace');
    }

    return IntegrationValidationResult(
      isValid: true,
      warnings: warnings,
      details: details,
    );
  }

  /// 날짜 키 생성 (내부 유틸리티)
  static String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 빠른 검증 (에러만 확인)
  static Future<bool> quickValidate() async {
    try {
      final sessionService = ChargingSessionService();
      final storageService = ChargingSessionStorage();

      if (!sessionService.isInitialized || !storageService.isInitialized) {
        return false;
      }

      // 기본적인 데이터 일관성만 빠르게 확인
      final memorySessions = sessionService.getTodaySessions();
      final dbSessions = await storageService.getTodaySessions();

      // 세션 개수가 크게 다르면 문제
      final diff = (memorySessions.length - dbSessions.length).abs();
      if (diff > 10) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('빠른 검증 실패: $e');
      return false;
    }
  }
}

