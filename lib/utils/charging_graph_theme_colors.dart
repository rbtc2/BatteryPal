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
      
      case ChargingGraphTheme.aurora:
        // 오로라는 매우 어두운 보라/남색 배경
        return const Color(0xFF0A0E27); // 매우 어두운 보라/남색
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
      
      case ChargingGraphTheme.aurora:
        // 오로라는 어두운 보라에서 남색으로 그라데이션
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0E27), // 매우 어두운 보라/남색
            Color(0xFF1A1F3A), // 약간 밝은 보라/남색
            Color(0xFF0F1419), // 거의 검정
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
      
      case ChargingGraphTheme.aurora:
        // 오로라는 보라색 테두리
        return Colors.purple.withValues(alpha: 0.3);
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
      
      case ChargingGraphTheme.aurora:
        // 오로라는 보라색 (기본 색상, 실제로는 그라데이션 사용)
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
      
      case ChargingGraphTheme.aurora:
        // 오로라는 보라→핑크→청록 그라데이션
        return [
          const Color(0xFF9D4EDD), // 보라색
          const Color(0xFFE6399F), // 핑크색
          const Color(0xFF06D6A0), // 청록색
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
      
      case ChargingGraphTheme.aurora:
        // 오로라는 보라색 그리드
        return Colors.purple.withValues(alpha: 0.1);
    }
  }
}

