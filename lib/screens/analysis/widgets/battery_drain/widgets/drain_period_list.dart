import 'package:flutter/material.dart';

/// 소모 구간 리스트 - 배터리 소모 구간을 리스트로 표시하는 위젯
/// 
/// 배터리 소모 구간들을 카드 형태로 표시합니다.
class DrainPeriodList extends StatefulWidget {
  const DrainPeriodList({super.key});

  @override
  State<DrainPeriodList> createState() => _DrainPeriodListState();
}

class _DrainPeriodListState extends State<DrainPeriodList> {
  /// Pull-to-Refresh를 위한 public 메서드
  Future<void> refresh() async {
    // 더미 데이터이므로 실제 새로고침 로직은 없음
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// 시간대 태그 반환 (새벽/아침/낮/저녁/밤)
  String _getTimeSlotTag(int hour) {
    if (hour >= 0 && hour < 6) {
      return '새벽';
    } else if (hour >= 6 && hour < 12) {
      return '아침';
    } else if (hour >= 12 && hour < 18) {
      return '낮';
    } else if (hour >= 18 && hour < 22) {
      return '저녁';
    } else {
      return '밤';
    }
  }

  /// 시간대 색상 반환
  Color _getTimeSlotColor(String timeSlot) {
    switch (timeSlot) {
      case '새벽':
        return Colors.blue[400]!;
      case '아침':
        return Colors.orange[400]!;
      case '낮':
        return Colors.yellow[600]!;
      case '저녁':
        return Colors.purple[400]!;
      case '밤':
        return Colors.indigo[400]!;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // 더미 소모 구간 데이터 (3개)
    final dummyPeriods = [
      {
        'startHour': 8,
        'startMinute': 30,
        'endHour': 12,
        'endMinute': 15,
        'startLevel': 85,
        'endLevel': 65,
        'avgRate': 2.5,
        'screenOnHours': 2.5,
        'screenOffHours': 1.0,
        'pattern': '일반 사용',
      },
      {
        'startHour': 14,
        'startMinute': 0,
        'endHour': 18,
        'endMinute': 30,
        'startLevel': 60,
        'endLevel': 40,
        'avgRate': 3.2,
        'screenOnHours': 3.0,
        'screenOffHours': 1.5,
        'pattern': '활발한 사용',
      },
      {
        'startHour': 20,
        'startMinute': 0,
        'endHour': 23,
        'endMinute': 45,
        'startLevel': 35,
        'endLevel': 20,
        'avgRate': 1.8,
        'screenOnHours': 1.5,
        'screenOffHours': 2.3,
        'pattern': '저전력 사용',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '소모 구간',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          
          // 소모 구간 카드들
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: dummyPeriods.map((period) {
                final startHour = period['startHour'] as int;
                final timeSlot = _getTimeSlotTag(startHour);
                final color = _getTimeSlotColor(timeSlot);
                
                return _buildPeriodCard(
                  context,
                  period: period,
                  timeSlot: timeSlot,
                  color: color,
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 하단 안내 텍스트
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '데이터를 불러오는 중...',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 소모 구간 카드 빌드
  Widget _buildPeriodCard(
    BuildContext context, {
    required Map<String, dynamic> period,
    required String timeSlot,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final startHour = period['startHour'] as int;
    final startMinute = period['startMinute'] as int;
    final endHour = period['endHour'] as int;
    final endMinute = period['endMinute'] as int;
    final startLevel = period['startLevel'] as int;
    final endLevel = period['endLevel'] as int;
    final avgRate = period['avgRate'] as double;
    final screenOnHours = period['screenOnHours'] as double;
    final screenOffHours = period['screenOffHours'] as double;
    final pattern = period['pattern'] as String;
    
    // 시간 포맷팅
    final startTimeStr = '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
    final endTimeStr = '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
    final timeRange = '$startTimeStr - $endTimeStr';
    
    // 소모 시간 계산
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;
    final durationMinutes = endMinutes - startMinutes;
    final durationHours = (durationMinutes / 60).toStringAsFixed(1);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 배터리 범위 + 시간대 태그
          Row(
            children: [
              Text(
                '🔋',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$startLevel% → $endLevel%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '[$timeSlot]',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 구분선
          Container(
            height: 1,
            color: color.withValues(alpha: 0.2),
          ),
          
          const SizedBox(height: 8),
          
          // 시간 정보
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 4),
              Text(
                '$timeRange ($durationHours시간)',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          // 소모 속도
          Row(
            children: [
              Icon(Icons.trending_down, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 4),
              Text(
                '평균 ${avgRate.toStringAsFixed(1)}%/h',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 구분선
          Container(
            height: 1,
            color: color.withValues(alpha: 0.2),
          ),
          
          const SizedBox(height: 8),
          
          // 화면 켜짐/꺼짐 시간
          Row(
            children: [
              Icon(Icons.phone_android, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 4),
              Text(
                '화면 켜짐: ${screenOnHours.toStringAsFixed(1)}h',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.phone_disabled, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 4),
              Text(
                '꺼짐: ${screenOffHours.toStringAsFixed(1)}h',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 사용 패턴
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 4),
              Text(
                '💡 $pattern',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

