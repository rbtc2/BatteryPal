import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/charging_chart_service.dart';

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
    final data = ChargingChartService.generateDummyData();
    
    return LineChart(
      ChargingChartService.createChartData(data),
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
}
