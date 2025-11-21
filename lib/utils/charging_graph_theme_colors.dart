import 'package:flutter/material.dart';
import '../models/charging_graph_theme.dart';

/// 충전 그래프 테마별 색상 스키마
/// 각 테마에 맞는 독창적인 색상 조합을 제공
class ChargingGraphThemeColors {
  /// 테마별 배경색 반환
  static Color getBackgroundColor(ChargingGraphTheme theme) {
    switch (theme) {
      case ChargingGraphTheme.ecg:
      case ChargingGraphTheme.spectrum:
        // ECG와 스펙트럼은 검정 배경 유지
        return Colors.black;
      
      case ChargingGraphTheme.wave:
        // 파도/웨이브는 어두운 파란색 배경
        return const Color(0xFF0A1A2E); // 어두운 네이비 블루
      
      case ChargingGraphTheme.particle:
        // 에너지 나무는 어두운 갈색/검정 배경
        return const Color(0xFF0F0A05); // 어두운 갈색 계열
      
      case ChargingGraphTheme.dna:
        // DNA 나선은 어두운 보라색 배경
        return const Color(0xFF0A050F); // 어두운 보라색 계열
    }
  }

  /// 테마별 배경 그라데이션 반환 (선택적)
  static LinearGradient? getBackgroundGradient(ChargingGraphTheme theme) {
    switch (theme) {
      case ChargingGraphTheme.wave:
        // 파도/웨이브는 검정에서 어두운 파란색으로 그라데이션
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A1A2E), // 어두운 네이비 블루
            Color(0xFF16213E), // 약간 밝은 네이비 블루
            Color(0xFF0F1419), // 거의 검정
          ],
          stops: [0.0, 0.5, 1.0],
        );
      
      case ChargingGraphTheme.particle:
        // 에너지 나무는 어두운 갈색에서 검정으로 그라데이션
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F0A05), // 어두운 갈색 계열
            Color(0xFF1A0F0A), // 약간 밝은 갈색 계열
            Color(0xFF0A0502), // 거의 검정
          ],
          stops: [0.0, 0.5, 1.0],
        );
      
      case ChargingGraphTheme.dna:
        // DNA 나선은 어두운 보라색에서 검정으로 그라데이션
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A050F), // 어두운 보라색 계열
            Color(0xFF1A0F1A), // 약간 밝은 보라색 계열
            Color(0xFF05020A), // 거의 검정
          ],
          stops: [0.0, 0.5, 1.0],
        );
      
      default:
        return null; // 그라데이션 없음
    }
  }

  /// 테마별 테두리 색상 반환
  static Color getBorderColor(ChargingGraphTheme theme) {
    switch (theme) {
      case ChargingGraphTheme.ecg:
      case ChargingGraphTheme.spectrum:
        // ECG와 스펙트럼은 초록색 테두리
        return Colors.green.withValues(alpha: 0.3);
      
      case ChargingGraphTheme.wave:
        // 파도/웨이브는 청록색/하늘색 테두리
        return Colors.cyan.withValues(alpha: 0.4);
      
      case ChargingGraphTheme.particle:
        // 에너지 나무는 황금색 테두리
        return Colors.amber.withValues(alpha: 0.5);
      
      case ChargingGraphTheme.dna:
        // DNA 나선은 보라색/핑크색 테두리
        return Colors.purple.withValues(alpha: 0.5);
    }
  }

  /// 테마별 그래프 색상 반환
  static Color getGraphColor(ChargingGraphTheme theme) {
    switch (theme) {
      case ChargingGraphTheme.ecg:
      case ChargingGraphTheme.spectrum:
        // ECG와 스펙트럼은 초록색
        return Colors.green;
      
      case ChargingGraphTheme.wave:
        // 파도/웨이브는 청록색
        return Colors.cyan;
      
      case ChargingGraphTheme.particle:
        // 에너지 나무는 황금색
        return Colors.amber;
      
      case ChargingGraphTheme.dna:
        // DNA 나선은 보라색
        return Colors.purple;
    }
  }

  /// 테마별 그래프 그라데이션 색상 리스트 반환 (파도 등에 사용)
  static List<Color>? getGraphGradientColors(ChargingGraphTheme theme) {
    switch (theme) {
      case ChargingGraphTheme.wave:
        // 파도/웨이브는 청록색에서 하늘색으로 그라데이션
        return [
          Colors.cyan,
          Colors.lightBlue,
          Colors.blue.shade300,
        ];
      
      case ChargingGraphTheme.particle:
        // 에너지 나무는 황금색에서 노란색으로 그라데이션
        return [
          Colors.amber,
          Colors.yellow,
          Colors.yellow.shade100,
        ];
      
      case ChargingGraphTheme.dna:
        // DNA 나선은 보라색에서 핑크색으로 그라데이션
        return [
          Colors.purple,
          Colors.purple.shade300,
          Colors.pink,
          Colors.pink.shade300,
        ];
      
      default:
        return null; // 그라데이션 없음
    }
  }

  /// 테마별 그리드 색상 반환
  static Color getGridColor(ChargingGraphTheme theme) {
    switch (theme) {
      case ChargingGraphTheme.ecg:
      case ChargingGraphTheme.spectrum:
        // ECG와 스펙트럼은 초록색 그리드
        return Colors.green.withValues(alpha: 0.1);
      
      case ChargingGraphTheme.wave:
        // 파도/웨이브는 청록색 그리드
        return Colors.cyan.withValues(alpha: 0.15);
      
      case ChargingGraphTheme.particle:
        // 에너지 나무는 황금색 그리드
        return Colors.amber.withValues(alpha: 0.15);
      
      case ChargingGraphTheme.dna:
        // DNA 나선은 보라색 그리드
        return Colors.purple.withValues(alpha: 0.15);
    }
  }
}

