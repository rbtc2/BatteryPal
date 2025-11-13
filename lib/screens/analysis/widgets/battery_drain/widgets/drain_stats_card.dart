import 'package:flutter/material.dart';
import '../../charging_patterns/widgets/stat_card.dart';

/// 소모 통계 카드 - 배터리 소모량 통계를 표시하는 위젯
/// 
/// 날짜별 소모 통계를 표시합니다.
/// - 총 소모량, 소모 전류
/// - 평균 속도, 최대 속도
/// - 화면 켜짐 시간, 1% 평균 시간
class DrainStatsCard extends StatefulWidget {
  const DrainStatsCard({super.key});

  @override
  State<DrainStatsCard> createState() => _DrainStatsCardState();
}

class _DrainStatsCardState extends State<DrainStatsCard> {
  /// 선택된 날짜 탭 (0: 오늘, 1: 어제, 2: 2일 전, 3: 커스텀)
  int _selectedDateTab = 0;
  
  /// 수동으로 선택한 날짜 (커스텀 탭일 때 사용)
  DateTime? _selectedDate;

  /// Pull-to-Refresh를 위한 public 메서드
  Future<void> refresh() async {
    // 더미 데이터이므로 실제 새로고침 로직은 없음
    await Future.delayed(const Duration(milliseconds: 500));
  }
  
  /// 날짜 선택 다이얼로그 표시
  Future<void> _showDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDate = today.subtract(const Duration(days: 7)); // 7일 전
    final lastDate = today; // 오늘
    
    final initialDate = _selectedDate ?? today;
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: '날짜 선택 (최근 7일)',
      cancelText: '취소',
      confirmText: '확인',
      selectableDayPredicate: (date) {
        final dateOnly = DateTime(date.year, date.month, date.day);
        final daysDiff = today.difference(dateOnly).inDays;
        return daysDiff >= 0 && daysDiff <= 7;
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (selectedDate != null) {
      final selectedDateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      setState(() {
        _selectedDate = selectedDateOnly;
        _selectedDateTab = 3; // 커스텀 탭으로 변경
      });
    }
  }

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
            child: Text(
              '소모 통계',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          
          // 날짜 선택 탭
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildDateTab(context, '오늘', 0),
                const SizedBox(width: 8),
                _buildDateTab(context, '어제', 1),
                const SizedBox(width: 8),
                _buildDateTab(context, '2일 전', 2),
                const Spacer(),
                InkWell(
                  onTap: () async {
                    await _showDatePicker(context);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          _selectedDate != null
                              ? '${_selectedDate!.year}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.day.toString().padLeft(2, '0')}'
                              : DateTime.now().toString().split(' ')[0].replaceAll('-', '.'),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 통계 카드 그리드 (2x3)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // 총 소모량
                StatCard(
                  title: '총 소모량',
                  mainValue: '--',
                  unit: '%',
                  subValue: '알 수 없음',
                  trend: '--',
                  trendColor: Colors.orange,
                  icon: Icons.battery_std,
                ),
                
                // 소모 전류
                StatCard(
                  title: '소모 전류',
                  mainValue: '--',
                  unit: 'mAh',
                  subValue: '알 수 없음',
                  trend: '--',
                  trendColor: Colors.red,
                  icon: Icons.bolt,
                ),
                
                // 평균 속도
                StatCard(
                  title: '평균 속도',
                  mainValue: '--',
                  unit: '%/h',
                  subValue: '알 수 없음',
                  trend: '--',
                  trendColor: Colors.blue,
                  icon: Icons.trending_down,
                ),
                
                // 최대 속도
                StatCard(
                  title: '최대 속도',
                  mainValue: '--',
                  unit: '%/h',
                  subValue: '알 수 없음',
                  trend: '--',
                  trendColor: Colors.purple,
                  icon: Icons.speed,
                ),
                
                // 화면 켜짐
                StatCard(
                  title: '화면 켜짐',
                  mainValue: '--',
                  unit: 'h',
                  subValue: '알 수 없음',
                  trend: '--',
                  trendColor: Colors.green,
                  icon: Icons.phone_android,
                ),
                
                // 1% 소모 평균 시간
                StatCard(
                  title: '1% 소모 평균 시간',
                  mainValue: '--',
                  unit: '분',
                  subValue: '알 수 없음',
                  trend: '--',
                  trendColor: Colors.teal,
                  icon: Icons.timer,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 날짜 탭 버튼 빌드
  Widget _buildDateTab(BuildContext context, String label, int index) {
    final isSelected = _selectedDateTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDateTab = index;
          if (index != 3) {
            _selectedDate = null; // 탭 선택 시 커스텀 날짜 초기화
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
}

