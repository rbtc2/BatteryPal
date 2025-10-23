import 'package:flutter/material.dart';

/// 최적화 탭 - 완전히 새로 구현된 전문가 수준 UI
/// 
/// 🎯 주요 기능:
/// 1. QuickOptimizationsCard: 5개 체크박스로 즉시 최적화 적용
/// 2. SavingsDashboardCard: 절약 현황 및 통계 표시
/// 
/// 📱 구현된 섹션:
/// - 빠른 최적화: 체크박스로 즉시 적용 가능한 5개 항목
/// - 절약 현황: 오늘/이번 주 절약 통계 + 활성화된 최적화 추적
/// 
/// 🎨 디자인 특징:
/// - 직관적 체크박스 인터페이스
/// - 색상별 상태 표시 (활성화/비활성화)
/// - 실시간 예상 효과 계산
/// - 인터랙티브 피드백 (스낵바, 다이얼로그)
/// 
/// ⚡ 성능 최적화:
/// - StatefulWidget으로 상태 관리
/// - const 생성자 사용으로 불필요한 리빌드 방지
/// - 텍스트 줄바꿈 방지로 레이아웃 안정성
/// - 접근성 개선 (색상 대비, 텍스트 크기)

/// 최적화 탭 - 메인 위젯
class OptimizationTab extends StatelessWidget {
  final bool isProUser;
  final VoidCallback? onProUpgrade;

  const OptimizationTab({
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
          // 섹션 1: 빠른 최적화 (메인 기능)
          const QuickOptimizationsCard(),
          
          const SizedBox(height: 16),
          
          // 섹션 2: 절약 현황
          const SavingsDashboardCard(),
          
          // 하단 여백
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// 최적화 항목 데이터 모델
class _OptimizationItem {
  final String id;
  final String title;
  final String description;
  final String effect; // "+20분"
  final IconData icon;
  final Color color;
  bool isEnabled;
  
  _OptimizationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.effect,
    required this.icon,
    required this.color,
    this.isEnabled = false,
  });
}

/// 섹션 1: 빠른 최적화 (메인 기능)
class QuickOptimizationsCard extends StatefulWidget {
  const QuickOptimizationsCard({super.key});

  @override
  State<QuickOptimizationsCard> createState() => _QuickOptimizationsCardState();
}

class _QuickOptimizationsCardState extends State<QuickOptimizationsCard> {
  late List<_OptimizationItem> _optimizations;
  
  @override
  void initState() {
    super.initState();
    _optimizations = _getDummyOptimizations();
  }
  
  // 활성화된 항목 수 계산
  int get _enabledCount => _optimizations.where((item) => item.isEnabled).length;
  
  // 현재 예상 효과 계산 (분)
  int get _currentEffect {
    return _optimizations
        .where((item) => item.isEnabled)
        .map((item) => int.parse(item.effect.replaceAll(RegExp(r'[^0-9]'), '')))
        .fold(0, (sum, value) => sum + value);
  }
  
  // 전체 예상 효과 계산 (분)
  int get _totalEffect {
    return _optimizations
        .map((item) => int.parse(item.effect.replaceAll(RegExp(r'[^0-9]'), '')))
        .fold(0, (sum, value) => sum + value);
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
                Text('⚡', style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '빠른 최적화',
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
          
          // 최적화 항목 리스트
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: _optimizations.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildOptimizationItem(item),
              )).toList(),
            ),
          ),
          
          SizedBox(height: 8),
          
          // 구분선
          Divider(height: 1, thickness: 1),
          
          // 예상 효과 요약
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 예상 총 효과',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '현재: +$_currentEffect분',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _enabledCount > 0 
                                  ? Colors.green[700]
                                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '($_enabledCount개 활성화)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(width: 16),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '모두 적용 시: +$_totalEffect분',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '(${_optimizations.length}개)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // 모두 적용하기 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _enabledCount == _optimizations.length 
                        ? null 
                        : _applyAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _enabledCount == _optimizations.length 
                          ? '모두 적용됨 ✓'
                          : '모두 적용하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOptimizationItem(_OptimizationItem item) {
    return InkWell(
      onTap: () => _toggleOptimization(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.isEnabled 
              ? item.color.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isEnabled
                ? item.color.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: item.isEnabled ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 체크박스
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: item.isEnabled 
                    ? item.color
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: item.isEnabled 
                      ? item.color
                      : Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
              ),
              child: item.isEnabled
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            
            SizedBox(width: 12),
            
            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.isEnabled
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '예상 효과: ${item.effect}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: item.isEnabled
                            ? Colors.green[700]
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(width: 8),
            
            // 아이콘
            Icon(
              item.icon,
              color: item.isEnabled 
                  ? item.color
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
  
  void _toggleOptimization(_OptimizationItem item) {
    setState(() {
      item.isEnabled = !item.isEnabled;
    });
    
    // 피드백 (스낵바)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          item.isEnabled 
              ? '✓ ${item.title} 활성화' 
              : '${item.title} 비활성화',
        ),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _applyAll() {
    setState(() {
      for (var item in _optimizations) {
        item.isEnabled = true;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ 모든 최적화가 적용되었습니다!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }
  
  /// 더미 최적화 데이터 생성
  List<_OptimizationItem> _getDummyOptimizations() {
    return [
      _OptimizationItem(
        id: 'brightness',
        title: '화면 밝기 30% 낮추기',
        description: '현재: 80% → 목표: 50%',
        effect: '+20분',
        icon: Icons.brightness_6,
        color: Colors.orange[400]!,
        isEnabled: false,
      ),
      _OptimizationItem(
        id: 'network',
        title: '모바일 데이터 → Wi-Fi만 사용',
        description: '5G 연결 끄기',
        effect: '+30분',
        icon: Icons.signal_cellular_alt,
        color: Colors.blue[400]!,
        isEnabled: false,
      ),
      _OptimizationItem(
        id: 'darkmode',
        title: '다크 모드 활성화',
        description: 'OLED 디스플레이 절약',
        effect: '+15분',
        icon: Icons.dark_mode,
        color: Colors.purple[400]!,
        isEnabled: false,
      ),
      _OptimizationItem(
        id: 'background',
        title: '백그라운드 앱 제한',
        description: '사용하지 않는 앱 일시정지',
        effect: '+25분',
        icon: Icons.apps,
        color: Colors.green[400]!,
        isEnabled: false,
      ),
      _OptimizationItem(
        id: 'location',
        title: '위치 서비스 절약 모드',
        description: 'GPS → 네트워크 기반',
        effect: '+10분',
        icon: Icons.location_on,
        color: Colors.red[400]!,
        isEnabled: false,
      ),
    ];
  }
}

/// 섹션 2: 절약 현황
class SavingsDashboardCard extends StatelessWidget {
  const SavingsDashboardCard({super.key});

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
                    '배터리 절약 현황',
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
          
          // 통계 카드 2개 (오늘 / 이번 주)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: '오늘 절약',
                    mainValue: '35분',
                    subValue: '+18% 증가',
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: '이번 주',
                    mainValue: '3.2시간',
                    subValue: '평균 27분',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          Divider(height: 1, thickness: 1),
          SizedBox(height: 16),
          
          // 활성화된 최적화 리스트
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '활성화된 최적화 (2개)',
                        style: TextStyle(
                          fontSize: 16,
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
                
                _buildActiveOptimizationItem(
                  context,
                  '화면 밝기 낮추기',
                  '활성 2시간',
                  Colors.orange,
                ),
                SizedBox(height: 8),
                _buildActiveOptimizationItem(
                  context,
                  '다크 모드',
                  '활성 3일',
                  Colors.purple,
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          Divider(height: 1, thickness: 1),
          SizedBox(height: 16),
          
          // 추가 팁
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '추가 팁',
                        style: TextStyle(
                          fontSize: 16,
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
                
                Text(
                  '📱 주요 배터리 소모 앱',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 8),
                
                _buildAppUsageItem(context, 'Instagram', '15%', Colors.pink),
                _buildAppUsageItem(context, 'YouTube', '12%', Colors.red),
                _buildAppUsageItem(context, '카카오톡', '8%', Colors.yellow),
                
                SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      _showAppSettingsDialog(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '앱별 설정 관리하기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String mainValue,
    required String subValue,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),
          Text(
            mainValue,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            subValue,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Widget _buildActiveOptimizationItem(
    BuildContext context,
    String title,
    String duration,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: color,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
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
            duration,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppUsageItem(
    BuildContext context,
    String appName,
    String percentage,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '$appName: $percentage (오늘)',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showAppSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.settings, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '앱별 설정 관리',
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
              '📱 배터리 소모가 많은 앱들:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12),
            
            _buildDialogAppItem(context, 'Instagram', '15%', Colors.pink),
            _buildDialogAppItem(context, 'YouTube', '12%', Colors.red),
            _buildDialogAppItem(context, '카카오톡', '8%', Colors.yellow),
            
            SizedBox(height: 16),
            
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 권장 설정:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• 백그라운드 새로고침 끄기',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '• 위치 접근 권한 제한',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '• 알림 최적화',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('앱별 설정 관리 기능은 준비 중입니다'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDialogAppItem(
    BuildContext context,
    String appName,
    String percentage,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              appName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              percentage,
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