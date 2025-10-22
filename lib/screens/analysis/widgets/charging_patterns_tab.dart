import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// 충전 패턴 탭 - 완전히 새로 구현된 스켈레톤 UI
/// 
/// 주요 기능:
/// 1. InsightCard: 접을 수 있는 인사이트 카드
/// 2. ChargingCurrentChart: fl_chart를 사용한 실시간 충전 전류 그래프
/// 3. ChargingStatsCard: 향상된 통계 및 세션 기록 카드
/// 4. Pro 사용자 전용 고급 분석 기능
/// 
/// 애니메이션:
/// - 페이지 로드 시 순차적 슬라이드 애니메이션
/// - 각 섹션별 독립적인 타이밍으로 부드러운 전환
/// 
/// Pro 기능:
/// - 상세 분석 다이얼로그
/// - AI 충전 패턴 예측
/// - 실시간 최적화 제안

/// 충전 데이터 포인트 클래스
class _ChargingDataPoint {
  final double hour; // 0.0 ~ 24.0
  final double currentMa;
  
  _ChargingDataPoint(this.hour, this.currentMa);
}

/// 충전 패턴 탭 - 새로운 스켈레톤 UI 구현
class ChargingPatternsTab extends StatefulWidget {
  final bool isProUser;
  final VoidCallback? onProUpgrade;

  const ChargingPatternsTab({
    super.key,
    required this.isProUser,
    this.onProUpgrade,
  });

  @override
  State<ChargingPatternsTab> createState() => _ChargingPatternsTabState();
}

class _ChargingPatternsTabState extends State<ChargingPatternsTab>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
            // 섹션 1: 인사이트 카드
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
              )),
              child: InsightCard(),
            ),
            
            SizedBox(height: 16),
            
            // 섹션 2: 충전 전류 그래프 (메인)
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
              )),
              child: ChargingCurrentChart(
                isProUser: widget.isProUser,
                onProUpgrade: widget.onProUpgrade,
              ),
            ),
            
            SizedBox(height: 16),
            
            // 섹션 3: 통계 + 세션 기록
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
              )),
              child: ChargingStatsCard(),
            ),
            
            // Pro 사용자 전용 추가 섹션
            if (widget.isProUser) ...[
              SizedBox(height: 16),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                )),
                child: _buildProExclusiveSection(),
              ),
            ],
            
            // 하단 여백
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProExclusiveSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(
          children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.star,
                color: Colors.purple,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Pro 전용 고급 분석',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildProFeature('🔮 AI 충전 패턴 예측', '다음 주 충전 패턴을 예측합니다'),
          SizedBox(height: 8),
          _buildProFeature('📊 상세 효율성 분석', '충전 효율을 시간대별로 분석합니다'),
          SizedBox(height: 8),
          _buildProFeature('⚡ 실시간 최적화 제안', '현재 상황에 맞는 충전 최적화를 제안합니다'),
        ],
      ),
    );
  }
  
  Widget _buildProFeature(String title, String description) {
    return Row(
      children: [
            Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
          ),
        ),
        Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 16,
        ),
      ],
    );
  }
}

/// 섹션 1: 오늘의 인사이트 카드 (접을 수 있음)
class InsightCard extends StatefulWidget {
  @override
  State<InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<InsightCard> {
  bool _isExpanded = true; // 기본값: 펼쳐진 상태
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (항상 표시, 탭하면 접기/펼치기)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
            children: [
                  Text('💡', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 12),
            Expanded(
                    child: Text(
                      '배터리 수명을 위한 오늘의 팁',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
                ),
                  Icon(
                    _isExpanded 
                        ? Icons.keyboard_arrow_up 
                        : Icons.keyboard_arrow_down,
                    color: Colors.blue,
              ),
            ],
          ),
            ),
          ),
          
          // 내용 (접혔을 때 숨김)
          if (_isExpanded) ...[
            Divider(height: 1, color: Colors.blue.withValues(alpha: 0.3)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  // 메인 인사이트 (더 강조)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🌙', style: TextStyle(fontSize: 22)),
                        SizedBox(width: 10),
              Expanded(
                          child: Text(
                            '밤 10시-새벽 6시에 충전하면\n배터리 건강도가 15% 더 유지돼요',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // 오늘 충전 현황 & 권장사항
                  _buildInfoRow(
                    context,
                    '오늘 충전',
                    '⚡급속 3회 (주의!)',
                    Colors.orange,
                  ),
                  SizedBox(height: 10),
                  _buildInfoRow(
                    context,
                    '권장사항',
                    '저속 충전 전환 추천',
                    Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
      children: [
          // 라벨 (고정 너비 제거)
        Text(
            '$label:',
            style: TextStyle(
            fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(width: 8),
          
          // 값 (자동 확장)
          Expanded(
            child: Text(
          value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
      ),
    );
  }
}

/// 섹션 2: 충전 전류 그래프 (메인)
class ChargingCurrentChart extends StatefulWidget {
  final bool isProUser;
  final VoidCallback? onProUpgrade;

  const ChargingCurrentChart({
    super.key,
    this.isProUser = false,
    this.onProUpgrade,
  });

  @override
  State<ChargingCurrentChart> createState() => _ChargingCurrentChartState();
}

class _ChargingCurrentChartState extends State<ChargingCurrentChart> {
  String _selectedTab = '오늘'; // '오늘', '어제', '이번 주'
  
  @override
  Widget build(BuildContext context) {
    return Container(
          decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
            border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('📊', style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '충전 전류 패턴',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.isProUser)
                  // Pro 사용자: 상세 분석 버튼
                  TextButton(
                    onPressed: _showDetailedAnalysis,
                    child: Text(
                      '상세 분석',
                      style: TextStyle(fontSize: 13),
                      maxLines: 1,
                    ),
                  )
                else
                  // 무료 사용자: Pro 딱지
                  InkWell(
                    onTap: widget.onProUpgrade,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Pro',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // 탭 선택 + 날짜
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTabButton('오늘'),
                SizedBox(width: 8),
                _buildTabButton('어제'),
                SizedBox(width: 8),
                _buildTabButton('이번 주'),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
          children: [
                      Icon(Icons.calendar_today, size: 14),
                      SizedBox(width: 6),
                Text(
                        '2024.01.15',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // 그래프 영역
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 250,
              child: _buildChart(),
            ),
          ),
          
          SizedBox(height: 16),
          
          // 범례
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem('저속 (0-500mA)', Colors.blue[400]!),
                _buildLegendItem('일반 (500-1500mA)', Colors.orange[400]!),
                _buildLegendItem('급속 (1500mA+)', Colors.red[400]!),
              ],
            ),
          ),
          
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label) {
    final isSelected = _selectedTab == label;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = label;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
                  style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
          children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
    );
  }
  
  Widget _buildChart() {
    final data = _generateDummyData();
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 500,
          verticalInterval: 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: Text(
              '시간 (Hour)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 4,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: Text(
              'mA',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              interval: 500,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        minX: 0,
        maxX: 24,
        minY: 0,
        maxY: 2500,
        lineBarsData: _buildLineChartBars(data),
      ),
    );
  }
  
  void _showDetailedAnalysis() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
      children: [
            Icon(Icons.analytics, color: Colors.purple),
            SizedBox(width: 8),
            Text('상세 충전 분석'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔍 고급 분석 기능:'),
            SizedBox(height: 8),
            Text('• 시간대별 충전 효율 분석'),
            Text('• 온도 변화 패턴 추적'),
            Text('• 충전 속도 최적화 제안'),
            Text('• 배터리 수명 예측'),
            SizedBox(height: 16),
            Text('이 기능은 Pro 사용자 전용입니다.', 
                 style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }
  
  /// 더미 데이터 생성 함수
  List<_ChargingDataPoint> _generateDummyData() {
    return [
      _ChargingDataPoint(0, 0),
      _ChargingDataPoint(2, 0),
      _ChargingDataPoint(2.25, 500),  // 02:15 충전 시작
      _ChargingDataPoint(4.5, 500),
      _ChargingDataPoint(4.5, 2100),  // 04:30 급속 전환
      _ChargingDataPoint(6, 2100),
      _ChargingDataPoint(6, 500),     // 06:00 저속 전환
      _ChargingDataPoint(7, 500),
      _ChargingDataPoint(7, 0),       // 07:00 충전 종료
      _ChargingDataPoint(9, 0),
      _ChargingDataPoint(9, 2100),    // 09:00 급속 충전
      _ChargingDataPoint(10.25, 2100),
      _ChargingDataPoint(10.25, 0),   // 10:15 종료
      _ChargingDataPoint(18.5, 0),
      _ChargingDataPoint(18.5, 1000), // 18:30 일반 충전
      _ChargingDataPoint(19, 1000),
      _ChargingDataPoint(19, 0),      // 19:00 종료
      _ChargingDataPoint(24, 0),
    ];
  }
  
  List<LineChartBarData> _buildLineChartBars(List<_ChargingDataPoint> data) {
    // 속도별로 분리된 세그먼트 생성
    List<LineChartBarData> bars = [];
    
    // 저속 세그먼트 (파란색)
    bars.add(_createSegment(data, 0, 500, Colors.blue[400]!));
    
    // 일반 세그먼트 (주황색)
    bars.add(_createSegment(data, 500, 1500, Colors.orange[400]!));
    
    // 급속 세그먼트 (빨간색)
    bars.add(_createSegment(data, 1500, 2500, Colors.red[400]!));
    
    return bars;
  }
  
  LineChartBarData _createSegment(
    List<_ChargingDataPoint> data,
    double minCurrent,
    double maxCurrent,
    Color color,
  ) {
    final spots = <FlSpot>[];
    
    for (var point in data) {
      if (point.currentMa >= minCurrent && point.currentMa < maxCurrent) {
        spots.add(FlSpot(point.hour, point.currentMa));
      }
    }
    
    return LineChartBarData(
      spots: spots.isEmpty ? [FlSpot(0, 0)] : spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.3),
            color.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

/// 섹션 3: 통계 + 세션 기록 카드
class ChargingStatsCard extends StatefulWidget {
  @override
  State<ChargingStatsCard> createState() => _ChargingStatsCardState();
}

class _ChargingStatsCardState extends State<ChargingStatsCard> {
  bool _isSessionsExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
          children: [
                Text('📈', style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
                Text(
                  '주간 충전 분석',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
          ),
          
          // 통계 카드 3개 (가로 배치)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                  child: _buildEnhancedStatCard(
                    context,
                    title: '평균속도',
                    mainValue: '1,350',
                    unit: 'mA',
                    subValue: '🟧 일반',
                    trend: '+12%',
                    trendColor: Colors.green,
                icon: Icons.speed,
                  ),
                ),
                SizedBox(width: 8),
            Expanded(
                  child: _buildEnhancedStatCard(
                    context,
                    title: '충전횟수',
                    mainValue: '16회',
                    unit: '(주간)',
                    subValue: '일 2.3회',
                    trend: '-2회',
                    trendColor: Colors.red,
                icon: Icons.battery_charging_full,
              ),
            ),
                SizedBox(width: 8),
            Expanded(
                  child: _buildEnhancedStatCard(
                    context,
                    title: '주시간대',
                    mainValue: '저녁9시',
                    unit: '',
                    subValue: '18-22시',
                    trend: '안정',
                    trendColor: Colors.blue,
                    icon: Icons.access_time,
              ),
            ),
          ],
        ),
          ),
          
          SizedBox(height: 16),
          
          // 세션 기록 펼치기 버튼
          InkWell(
            onTap: () {
              setState(() {
                _isSessionsExpanded = !_isSessionsExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
          children: [
                  Icon(
                    _isSessionsExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 8),
            Expanded(
                    child: Text(
                      '충전 세션 기록 (오늘) ${_isSessionsExpanded ? '' : '보기'}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  if (!_isSessionsExpanded)
        Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '3건',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
              ),
            ),
          ],
        ),
            ),
          ),
          
          // 세션 기록 리스트 (펼쳤을 때만 표시)
          if (_isSessionsExpanded) ...[
            Padding(
          padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildEnhancedSessionItem(
                    context,
                    icon: '🌙',
                    title: '새벽 충전',
                    timeRange: '02:15 - 07:00',
                    batteryChange: '15% → 100%',
                    duration: '4시간 45분',
                    avgCurrent: '650mA',
                    efficiency: '85%',
                    temperature: '28°C',
                    speedChanges: [
                      '02:15 저속 시작',
                      '04:30 급속 전환 ⚡',
                      '06:00 트리클 모드',
                    ],
                    color: Colors.blue[400]!,
                    isExpanded: false,
                  ),
                  SizedBox(height: 12),
                  _buildEnhancedSessionItem(
                    context,
                    icon: '⚡',
                    title: '아침 급속 충전',
                    timeRange: '09:00 - 10:15',
                    batteryChange: '25% → 85%',
                    duration: '1시간 15분',
                    avgCurrent: '2,100mA',
                    efficiency: '92%',
                    temperature: '32°C',
                    speedChanges: [],
                    color: Colors.red[400]!,
                    isExpanded: false,
                  ),
                  SizedBox(height: 12),
                  _buildEnhancedSessionItem(
                    context,
                    icon: '🔌',
                    title: '저녁 보충 충전',
                    timeRange: '18:30 - 19:00',
                    batteryChange: '45% → 75%',
                    duration: '30분',
                    avgCurrent: '1,000mA',
                    efficiency: '88%',
                    temperature: '26°C',
                    speedChanges: [],
                    color: Colors.orange[400]!,
                    isExpanded: false,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildEnhancedStatCard(
    BuildContext context, {
    required String title,
    required String mainValue,
    required String unit,
    required String subValue,
    required String trend,
    required Color trendColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHighest,
            Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
          ),
          child: Column(
        mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // 헤더: 아이콘 + 제목
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: trendColor,
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8),
          
          // 메인 값 + 단위 (가로로 배치, 줄바꿈 방지)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  mainValue,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                ),
              ],
            ],
          ),
          
          SizedBox(height: 4),
          
          // 서브 값과 트렌드
          Row(
            children: [
              Expanded(
                child: Text(
                  subValue,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
      child: Row(
                  mainAxisSize: MainAxisSize.min,
        children: [
                    Icon(
                      _getTrendIcon(trend),
                      size: 8,
                      color: trendColor,
                    ),
                    SizedBox(width: 2),
          Text(
                      trend,
            style: TextStyle(
                        fontSize: 9,
              fontWeight: FontWeight.bold,
                        color: trendColor,
            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getTrendIcon(String trend) {
    if (trend.startsWith('+')) return Icons.trending_up;
    if (trend.startsWith('-')) return Icons.trending_down;
    return Icons.trending_flat;
  }

  Widget _buildEnhancedSessionItem(
    BuildContext context, {
    required String icon,
    required String title,
    required String timeRange,
    required String batteryChange,
    required String duration,
    required String avgCurrent,
    required String efficiency,
    required String temperature,
    required List<String> speedChanges,
    required Color color,
    required bool isExpanded,
  }) {
    return Container(
      constraints: BoxConstraints(
        minHeight: 180, // 최소 높이 지정
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
              color: color,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 아이콘 + 제목 + 시간 + 효율성
          Row(
      children: [
        Container(
                padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(icon, style: TextStyle(fontSize: 20)),
              ),
              SizedBox(width: 12),
              Expanded(
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                      title,
                  style: TextStyle(
                    fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                    SizedBox(height: 4),
                Text(
                      timeRange,
                  style: TextStyle(
                    fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getEfficiencyColor(efficiency).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '효율 $efficiency',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getEfficiencyColor(efficiency),
                  ),
              ),
            ),
          ],
        ),
          
          SizedBox(height: 16),
          
          // 주요 정보 그리드 (고정 높이로 일관성 확보)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
                  child: _buildEnhancedInfoItem(context, batteryChange, '배터리 변화', Colors.green),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildEnhancedInfoItem(context, duration, '충전 시간', Colors.blue),
                ),
                SizedBox(width: 8),
            Expanded(
                  child: _buildEnhancedInfoItem(context, avgCurrent, '평균 전류', color),
            ),
          ],
        ),
          ),
          
          SizedBox(height: 12),
          
          // 온도 정보
        Row(
          children: [
              Icon(Icons.thermostat, size: 16, color: Colors.orange),
              SizedBox(width: 4),
            Expanded(
                child: Text(
                  '평균 온도: $temperature',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (speedChanges.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${speedChanges.length}회 변경',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          
          // 속도 변경 이력 (있을 경우)
          if (speedChanges.isNotEmpty) ...[
            SizedBox(height: 12),
          Container(
              padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: color.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timeline, size: 14, color: color),
                      SizedBox(width: 6),
                      Text(
                        '속도 변경 이력',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ...speedChanges.map((change) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8),
                Expanded(
                  child: Text(
                            change,
                    style: TextStyle(
                      fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                      ],
                    ),
                  )),
              ],
            ),
          ),
        ],
      ],
      ),
    );
  }
  
  Color _getEfficiencyColor(String efficiency) {
    final value = int.parse(efficiency.replaceAll('%', ''));
    if (value >= 90) return Colors.green;
    if (value >= 80) return Colors.orange;
    return Colors.red;
  }
  
  Widget _buildEnhancedInfoItem(BuildContext context, String value, String label, Color color) {
    return Container(
      height: 60, // 고정 높이 설정
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
      children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
          color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

