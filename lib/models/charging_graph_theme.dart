/// 충전 그래프 테마
enum ChargingGraphTheme {
  /// 심전도 스타일 (기본)
  ecg('심전도', '심전도 스타일 그래프'),
  
  /// 파도/웨이브 애니메이션
  wave('파도/웨이브', '파도 애니메이션'),
  
  /// 에너지 나무 (방사형 입자 흐름 + 나무 가지형 분기)
  particle('에너지 나무', '에너지가 나무처럼 뻗어나가는 형태'),
  
  /// 스펙트럼 분석기
  spectrum('스펙트럼 분석기', '스펙트럼 분석기 스타일'),
  
  /// DNA 나선 구조
  dna('DNA 나선', 'DNA 나선 구조');

  const ChargingGraphTheme(this.displayName, this.description);
  
  final String displayName;
  final String description;
}

