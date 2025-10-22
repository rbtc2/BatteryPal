import 'package:flutter/material.dart';

/// 섹션 3: 통계 + 세션 기록 카드
class ChargingStatsCard extends StatefulWidget {
  const ChargingStatsCard({super.key});

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
