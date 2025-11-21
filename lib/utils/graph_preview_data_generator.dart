import 'dart:math' as math;

/// 그래프 미리보기용 샘플 데이터 생성 유틸리티
/// 각 테마의 그래프를 미리보기로 보여주기 위한 샘플 데이터를 생성
class GraphPreviewDataGenerator {
  /// 애니메이션을 위한 시간 값 (0.0 ~ 1.0)
  /// 이 값을 변경하여 그래프가 움직이는 효과를 만들 수 있음
  static List<double> generateSampleData({
    required int pointCount,
    double animationValue = 0.0,
  }) {
    final data = <double>[];
    final baseAmplitude = 50.0; // 기본 진폭
    final baseOffset = 100.0; // 기본 오프셋
    
    for (int i = 0; i < pointCount; i++) {
      final x = i / (pointCount - 1); // 0.0 ~ 1.0
      
      // 여러 주파수의 사인파를 조합하여 자연스러운 파형 생성
      final wave1 = math.sin((x * 2 * math.pi * 2) + (animationValue * 2 * math.pi)) * baseAmplitude;
      final wave2 = math.sin((x * 2 * math.pi * 3.5) + (animationValue * 2 * math.pi * 1.3)) * (baseAmplitude * 0.6);
      final wave3 = math.sin((x * 2 * math.pi * 5) + (animationValue * 2 * math.pi * 0.7)) * (baseAmplitude * 0.3);
      
      // 노이즈 추가 (더 자연스러운 효과)
      final noise = (math.Random(i).nextDouble() - 0.5) * 10;
      
      final value = baseOffset + wave1 + wave2 + wave3 + noise;
      data.add(value);
    }
    
    return data;
  }
  
  /// 특정 테마에 최적화된 샘플 데이터 생성
  /// 각 테마의 특성을 잘 보여주는 데이터 생성
  static List<double> generateThemeSpecificData({
    required String themeName,
    required int pointCount,
    double animationValue = 0.0,
  }) {
    switch (themeName) {
      case 'ecg':
        // 심전도: 급격한 변화와 안정 구간
        return _generateECGStyleData(pointCount, animationValue);
      
      case 'spectrum':
        // 스펙트럼: 다양한 주파수 성분
        return _generateSpectrumStyleData(pointCount, animationValue);
      
      case 'wave':
        // 파도: 부드러운 파형
        return _generateWaveStyleData(pointCount, animationValue);
      
      default:
        return generateSampleData(pointCount: pointCount, animationValue: animationValue);
    }
  }
  
  /// ECG 스타일 데이터 생성 (급격한 변화)
  static List<double> _generateECGStyleData(int pointCount, double animationValue) {
    final data = <double>[];
    final baseOffset = 100.0;
    
    for (int i = 0; i < pointCount; i++) {
      final x = i / (pointCount - 1);
      double value = baseOffset;
      
      // 심전도 패턴: 안정 구간과 급격한 변화
      if ((i % 20) < 2) {
        // 급격한 상승 (QRS 복합체)
        value += 80 * math.sin(x * math.pi * 10);
      } else if ((i % 20) < 4) {
        // 급격한 하강
        value -= 40;
      } else {
        // 안정 구간
        value += math.sin((x * 2 * math.pi) + (animationValue * 2 * math.pi)) * 10;
      }
      
      data.add(value);
    }
    
    return data;
  }
  
  /// 스펙트럼 스타일 데이터 생성 (다양한 주파수)
  static List<double> _generateSpectrumStyleData(int pointCount, double animationValue) {
    final data = <double>[];
    final baseOffset = 50.0;
    
    for (int i = 0; i < pointCount; i++) {
      final x = i / (pointCount - 1);
      
      // 다양한 주파수 성분 조합
      final wave1 = math.sin((x * 2 * math.pi * 1) + (animationValue * 2 * math.pi)) * 30;
      final wave2 = math.sin((x * 2 * math.pi * 2.5) + (animationValue * 2 * math.pi * 1.2)) * 20;
      final wave3 = math.sin((x * 2 * math.pi * 4) + (animationValue * 2 * math.pi * 0.8)) * 15;
      
      final value = baseOffset + wave1 + wave2 + wave3;
      data.add(value.clamp(0, 200));
    }
    
    return data;
  }
  
  /// 파도 스타일 데이터 생성 (부드러운 파형)
  static List<double> _generateWaveStyleData(int pointCount, double animationValue) {
    final data = <double>[];
    final baseOffset = 100.0;
    final amplitude = 40.0;
    
    for (int i = 0; i < pointCount; i++) {
      final x = i / (pointCount - 1);
      
      // 부드러운 파도 효과
      final wave1 = math.sin((x * 2 * math.pi * 2) + (animationValue * 2 * math.pi)) * amplitude;
      final wave2 = math.cos((x * 2 * math.pi * 1.5) + (animationValue * 2 * math.pi * 1.3)) * (amplitude * 0.5);
      
      final value = baseOffset + wave1 + wave2;
      data.add(value);
    }
    
    return data;
  }
}

