import 'package:flutter/material.dart';
import '../widgets/analysis_tab_widgets.dart';

/// 배터리 건강도 탭 - 배터리 용량, 건강도, 온도 분석
class BatteryHealthTab extends StatelessWidget {
  final bool isProUser;
  final VoidCallback? onProUpgrade;

  const BatteryHealthTab({
    super.key,
    required this.isProUser,
    this.onProUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 현재 건강도 카드
          AnalysisCard(
            title: '현재 배터리 건강도',
            child: _buildCurrentHealth(),
          ),
          const SizedBox(height: 24),

          // 건강도 변화 추이 카드
          AnalysisCard(
            title: '건강도 변화 추이',
            showProUpgrade: !isProUser,
            onProUpgrade: onProUpgrade,
            child: _buildHealthTrend(),
          ),
          const SizedBox(height: 24),

          // 온도 패턴 분석 카드
          AnalysisCard(
            title: '온도 패턴 분석',
            showProUpgrade: !isProUser,
            onProUpgrade: onProUpgrade,
            child: _buildTemperatureAnalysis(),
          ),
          const SizedBox(height: 24),

          // 수명 예측 카드
          AnalysisCard(
            title: '배터리 수명 예측',
            showProUpgrade: !isProUser,
            onProUpgrade: onProUpgrade,
            child: _buildLifespanPrediction(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentHealth() {
    return Column(
      children: [
        // 현재 상태 정보
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.withValues(alpha: 0.1),
                Colors.amber.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber[700],
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '현재 상태',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatusItem('실제 용량', '3,560 mAh / 4,000 mAh'),
              const SizedBox(height: 8),
              _buildStatusItem('배터리 수명', '89% 🟡'),
              const SizedBox(height: 8),
              _buildStatusItem('충전 사이클', '312회'),
              const SizedBox(height: 8),
              _buildStatusItem('제조일', '2023년 3월 (1년 8개월)'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem(String label, String value) {
    return Builder(
      builder: (context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTrend() {
    return Builder(
      builder: (context) => Column(
        children: [
          // 성능 저하 그래프
          Container(
            height: 200,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '성능 저하 그래프',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'X축: 월별, Y축: 배터리 용량 %',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                // 간단한 차트 시각화
                Expanded(
                  child: _buildPerformanceChart(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildLegendItem(context, '실제 데이터', Colors.blue, false),
                    const SizedBox(width: 16),
                    _buildLegendItem(context, '예측선 (미래 6개월)', Colors.red, true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return CustomPaint(
      painter: PerformanceChartPainter(),
      size: const Size(double.infinity, 100),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color, bool isDashed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        if (isDashed) ...[
          const SizedBox(width: 2),
          Container(
            width: 4,
            height: 2,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTemperatureAnalysis() {
    return Column(
      children: [
        // 건강 요소별 점수
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withValues(alpha: 0.1),
                Colors.blue.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.blue.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics,
                    color: Colors.blue[700],
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '건강 요소별 점수',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildHealthScoreItem('온도 관리', 80, Colors.green),
              const SizedBox(height: 12),
              _buildHealthScoreItem('충전 습관', 60, Colors.orange),
              const SizedBox(height: 12),
              _buildHealthScoreItem('방전 깊이', 90, Colors.green),
              const SizedBox(height: 12),
              _buildHealthScoreItem('충전 속도', 40, Colors.red),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthScoreItem(String label, int score, Color color) {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '$score/100',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: score / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifespanPrediction() {
    return Column(
      children: [
        // 수명 연장 팁
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withValues(alpha: 0.1),
                Colors.green.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.green[700],
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '수명 연장 팁 (우선순위)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTipItem(
                priority: 1,
                icon: '🔴',
                title: '고속충전 줄이기',
                benefit: '+6개월',
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              _buildTipItem(
                priority: 2,
                icon: '🟡',
                title: '80% 충전 제한',
                benefit: '+4개월',
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildTipItem(
                priority: 3,
                icon: '🟢',
                title: '야간 저속충전',
                benefit: '+3개월',
                color: Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem({
    required int priority,
    required String icon,
    required String title,
    required String benefit,
    required Color color,
  }) {
    return Builder(
      builder: (context) => Row(
        children: [
          Text(
            '$priority. $icon',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              benefit,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 성능 저하 그래프를 그리는 CustomPainter
class PerformanceChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill;

    // 실제 데이터 포인트 (월별 배터리 용량 %)
    final actualData = [100.0, 98.0, 95.0, 92.0, 89.0, 87.0, 85.0];
    final predictedData = [85.0, 82.0, 78.0, 74.0, 70.0, 66.0]; // 미래 6개월 예측

    final width = size.width;
    final height = size.height;
    final padding = 20.0;

    // Y축 범위 (60% ~ 100%)
    final minValue = 60.0;
    final maxValue = 100.0;
    final valueRange = maxValue - minValue;

    // 실제 데이터 그리기
    paint.color = Colors.blue;
    final actualPath = Path();
    for (int i = 0; i < actualData.length; i++) {
      final x = padding + (i * (width - 2 * padding) / (actualData.length - 1));
      final y = height - padding - ((actualData[i] - minValue) / valueRange) * (height - 2 * padding);
      
      if (i == 0) {
        actualPath.moveTo(x, y);
      } else {
        actualPath.lineTo(x, y);
      }
    }
    canvas.drawPath(actualPath, paint);

    // 실제 데이터 포인트 그리기
    fillPaint.color = Colors.blue;
    for (int i = 0; i < actualData.length; i++) {
      final x = padding + (i * (width - 2 * padding) / (actualData.length - 1));
      final y = height - padding - ((actualData[i] - minValue) / valueRange) * (height - 2 * padding);
      canvas.drawCircle(Offset(x, y), 3, fillPaint);
    }

    // 예측선 그리기 (점선)
    paint.color = Colors.red;
    paint.strokeWidth = 1.5;
    final predictedPath = Path();
    final startIndex = actualData.length - 1;
    final startX = padding + (startIndex * (width - 2 * padding) / (actualData.length - 1));
    final startY = height - padding - ((actualData[startIndex] - minValue) / valueRange) * (height - 2 * padding);
    
    predictedPath.moveTo(startX, startY);
    
    for (int i = 0; i < predictedData.length; i++) {
      final x = startX + ((i + 1) * (width - 2 * padding) / (actualData.length + predictedData.length - 1));
      final y = height - padding - ((predictedData[i] - minValue) / valueRange) * (height - 2 * padding);
      predictedPath.lineTo(x, y);
    }
    
    // 점선 효과를 위한 패스 분할
    final dashWidth = 4.0;
    final dashSpace = 2.0;
    final pathMetrics = predictedPath.computeMetrics();
    
    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final extractPath = pathMetric.extractPath(distance, distance + dashWidth);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }

    // 예측 데이터 포인트 그리기
    fillPaint.color = Colors.red;
    for (int i = 0; i < predictedData.length; i++) {
      final x = startX + ((i + 1) * (width - 2 * padding) / (actualData.length + predictedData.length - 1));
      final y = height - padding - ((predictedData[i] - minValue) / valueRange) * (height - 2 * padding);
      canvas.drawCircle(Offset(x, y), 2, fillPaint);
    }

    // 그리드 라인 그리기
    paint.color = Colors.grey.withValues(alpha: 0.3);
    paint.strokeWidth = 0.5;
    
    // 수평 그리드 라인
    for (int i = 0; i <= 4; i++) {
      final y = padding + (i * (height - 2 * padding) / 4);
      canvas.drawLine(
        Offset(padding, y),
        Offset(width - padding, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
