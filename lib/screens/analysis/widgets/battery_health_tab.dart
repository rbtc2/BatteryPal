import 'package:flutter/material.dart';

/// 배터리 건강도 탭 - 완전히 새로 구현된 전문가 수준 UI
/// 
/// 🎯 주요 기능:
/// 1. HealthScoreCard: 배터리 건강도 점수 (89/100) - 메인 기능
/// 2. ChargingHabitsCard: 충전 습관 분석 (고속/온도/과충전)
/// 3. LifespanTipsCard: 수명 연장 팁 (우선순위별 개선 방법)
/// 
/// 📱 구현된 섹션:
/// - 건강도 점수: 큰 원형 점수 + 3개 세부 점수 진행바
/// - 충전 습관: 색상별 상태 표시 + 개선 방법 다이얼로그
/// - 수명 연장 팁: 우선순위별 팁 + 예상 효과 표시
/// 
/// 🎨 디자인 특징:
/// - 일관된 색상 시스템 (건강도/상태별 색상)
/// - 반응형 레이아웃 (오버플로우 방지)
/// - 직관적 인터랙션 (버튼, 다이얼로그)
/// - 다크모드/라이트모드 완벽 지원
/// 
/// ⚡ 성능 최적화:
/// - const 생성자 사용으로 불필요한 리빌드 방지
/// - StatelessWidget 활용으로 메모리 효율성
/// - 텍스트 줄바꿈 방지로 레이아웃 안정성
/// - 접근성 개선 (색상 대비, 텍스트 크기)

/// 배터리 건강도 탭 - 메인 위젯
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
          // 섹션 1: 건강도 점수
          const HealthScoreCard(),
          
          const SizedBox(height: 16),
          
          // 섹션 2: 충전 습관 분석
          const ChargingHabitsCard(),
          
          const SizedBox(height: 16),
          
          // 섹션 3: 수명 연장 팁
          const LifespanTipsCard(),
          
          // 하단 여백
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// 섹션 1: 배터리 건강도 점수 (메인 기능)
class HealthScoreCard extends StatelessWidget {
  const HealthScoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    final totalScore = 89;
    final speedScore = 85;
    final tempScore = 70;
    final overchargeScore = 95;
    
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
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('🏆', style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '배터리 건강도',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // 총점 표시 (큰 원)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withValues(alpha: 0.2),
                    Colors.green.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.green,
                  width: 4,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$totalScore',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    '/ 100',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '🟢 양호',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 세부 점수 (3개 항목)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildScoreItem(
                  context,
                  label: '충전 속도 관리',
                  score: speedScore,
                  maxScore: 35,
                  color: _getScoreColor(speedScore, 35),
                ),
                SizedBox(height: 12),
                _buildScoreItem(
                  context,
                  label: '온도 관리',
                  score: tempScore,
                  maxScore: 35,
                  color: _getScoreColor(tempScore, 35),
                ),
                SizedBox(height: 12),
                _buildScoreItem(
                  context,
                  label: '과충전 방지',
                  score: overchargeScore,
                  maxScore: 30,
                  color: _getScoreColor(overchargeScore, 30),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // 종합 평가
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Text('💡', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Expanded(
                    child:                   Text(
                    '배터리를 잘 관리하고 있어요!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildScoreItem(
    BuildContext context, {
    required String label,
    required int score,
    required int maxScore,
    required Color color,
  }) {
    final percentage = (score / maxScore).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$score',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
  
  Color _getScoreColor(int score, int maxScore) {
    final percentage = (score / maxScore);
    if (percentage >= 0.8) return Colors.green;
    if (percentage >= 0.6) return Colors.amber;
    return Colors.red;
  }
}

/// 충전 습관 상태 열거형
enum HabitStatus { good, warning, danger }

/// 섹션 2: 충전 습관 분석
class ChargingHabitsCard extends StatelessWidget {
  const ChargingHabitsCard({super.key});

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('🎯', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '충전 습관 분석',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '최근 7일',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          
          // 습관 항목들
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildHabitItem(
                  context,
                  icon: '⚡',
                  title: '고속 충전 사용',
                  current: '주 5회',
                  recommendation: '권장: 주 3회 이하',
                  status: HabitStatus.warning,
                  statusText: '⚠️ 배터리 수명 단축 위험',
                  showAction: true,
                ),
                SizedBox(height: 12),
                _buildHabitItem(
                  context,
                  icon: '🌡️',
                  title: '충전 온도',
                  current: '평균 28°C',
                  recommendation: '권장: 30°C 이하',
                  status: HabitStatus.good,
                  statusText: '✅ 좋은 습관입니다!',
                  showAction: false,
                ),
                SizedBox(height: 12),
                _buildHabitItem(
                  context,
                  icon: '🔋',
                  title: '과충전 방지',
                  current: '100% 유지: 하루 평균 2시간',
                  recommendation: '권장: 80-90%에서 분리',
                  status: HabitStatus.warning,
                  statusText: '⚠️ 80-90%에서 분리 권장',
                  showAction: true,
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildHabitItem(
    BuildContext context, {
    required String icon,
    required String title,
    required String current,
    required String recommendation,
    required HabitStatus status,
    required String statusText,
    required bool showAction,
  }) {
    final statusColor = status == HabitStatus.good 
        ? Colors.green 
        : status == HabitStatus.warning 
            ? Colors.orange 
            : Colors.red;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Row(
            children: [
              Text(icon, style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // 현재 상태
          Text(
            current,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: 4),
          
          // 권장사항
          Text(
            recommendation,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: 12),
          
          // 상태 메시지
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor.shade700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // 개선 방법 버튼
          if (showAction) ...[
            SizedBox(height: 12),
            InkWell(
              onTap: () {
                _showImprovementDialog(context, title);
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '개선 방법 보기',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  void _showImprovementDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.amber),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '$title 개선 방법',
                style: TextStyle(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💡 개선 방법:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8),
            if (title.contains('고속 충전')) ...[
              Text('• 밤에는 저속 충전기 사용', style: TextStyle(fontSize: 13)),
              Text('• 급한 경우에만 고속 충전', style: TextStyle(fontSize: 13)),
              Text('• 충전 완료 후 즉시 분리', style: TextStyle(fontSize: 13)),
            ] else if (title.contains('과충전')) ...[
              Text('• 80-90%에서 충전기 분리', style: TextStyle(fontSize: 13)),
              Text('• 알림 설정으로 도움받기', style: TextStyle(fontSize: 13)),
              Text('• Pro 기능으로 자동 제어', style: TextStyle(fontSize: 13)),
            ],
            SizedBox(height: 16),
            Text(
              '이 방법들을 실천하면 배터리 수명이 연장됩니다.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
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

/// 팁 데이터 모델
class _TipData {
  final int priority;
  final String emoji;
  final String title;
  final String impact;
  final String current;
  final String advice;
  final Color color;
  
  _TipData({
    required this.priority,
    required this.emoji,
    required this.title,
    required this.impact,
    required this.current,
    required this.advice,
    required this.color,
  });
}

/// 섹션 3: 수명 연장 팁
class LifespanTipsCard extends StatelessWidget {
  const LifespanTipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tips = _getDummyTips();
    
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
                Text('💡', style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '수명 연장 팁 (우선순위)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // 팁 리스트
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTipItem(context, tip),
              )).toList(),
            ),
          ),
          
          SizedBox(height: 4),
        ],
      ),
    );
  }
  
  Widget _buildTipItem(BuildContext context, _TipData tip) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tip.color.withValues(alpha: 0.15),
            tip.color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tip.color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 + 효과
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: tip.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${tip.priority}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: tip.color,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Text(tip.emoji, style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  tip.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tip.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tip.impact,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: tip.color,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // 구분선
          Container(
            height: 1,
            color: tip.color.withValues(alpha: 0.2),
          ),
          
          SizedBox(height: 12),
          
          // 현재 상태
          Text(
            tip.current,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: 8),
          
          // 조언
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tip.advice,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 더미 팁 데이터 생성
  List<_TipData> _getDummyTips() {
    return [
      _TipData(
        priority: 1,
        emoji: '🔴',
        title: '고속 충전 줄이기',
        impact: '+6개월',
        current: '현재: 주 5회 → 목표: 주 3회',
        advice: '💡 밤에는 저속 충전기 사용',
        color: Colors.red[400]!,
      ),
      _TipData(
        priority: 2,
        emoji: '🟡',
        title: '80% 충전 제한',
        impact: '+4개월',
        current: '80%에 도달하면 충전기 분리',
        advice: '💡 Pro: 자동 알림 기능',
        color: Colors.amber[400]!,
      ),
      _TipData(
        priority: 3,
        emoji: '🟢',
        title: '서늘한 곳에서 충전',
        impact: '+3개월',
        current: '케이스 제거 후 충전',
        advice: '💡 직사광선 피하기',
        color: Colors.green[400]!,
      ),
    ];
  }
}