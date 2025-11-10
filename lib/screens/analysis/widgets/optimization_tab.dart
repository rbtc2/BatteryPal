import 'package:flutter/material.dart';
import '../../../services/optimization_snapshot_service.dart';
import '../../../services/system_settings_service.dart';

/// 최적화 탭 - 재설계된 UI/UX
/// 
/// 🎯 주요 기능:
/// 1. OptimizationDashboardCard: 최적화 현황 대시보드
/// 2. AutoOptimizationCard: 자동 최적화 항목 관리
/// 3. ManualOptimizationCard: 수동 설정 항목 관리
/// 4. OptimizationTipsCard: 맞춤 추천 및 팁
/// 
/// 📱 구현된 섹션:
/// - 최적화 현황: 마지막 최적화 시간, 오늘 통계, 4가지 핵심 지표
/// - 자동 최적화: 원클릭 최적화에 포함되는 항목들 (토글)
/// - 수동 설정: 시스템 설정 화면으로 이동하는 항목들
/// - 맞춤 추천: 배터리 소모 앱, 절약 팁, 통계
/// 
/// 🎨 디자인 특징:
/// - 그라데이션 배경 (초록→청록)
/// - 색상별 구분 (자동: 초록, 수동: 파랑)
/// - 직관적 인터랙션 (토글, 버튼)
/// - 다크모드 완벽 대응

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
          // 섹션 1: 최적화 현황 대시보드
          const OptimizationDashboardCard(),
          
          const SizedBox(height: 16),
          
          // 섹션 2: 자동 최적화 항목
          const AutoOptimizationCard(),
          
          const SizedBox(height: 16),
          
          // 섹션 3: 수동 설정 항목
          const ManualOptimizationCard(),
          
          const SizedBox(height: 16),
          
          // 섹션 4: 최적화 팁 & 인사이트
          const OptimizationTipsCard(),
          
          // 하단 여백
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// 최적화 통계 데이터 모델
class OptimizationStats {
  final DateTime lastOptimizedAt;
  final int todayOptimizationCount;
  final Duration todayTotalSaved;
  final int appsKilled;
  final int memoryMB;
  final int cacheMB;
  final int servicesStopped;

  OptimizationStats({
    required this.lastOptimizedAt,
    required this.todayOptimizationCount,
    required this.todayTotalSaved,
    required this.appsKilled,
    required this.memoryMB,
    required this.cacheMB,
    required this.servicesStopped,
  });
}

/// 최적화 항목 데이터 모델
class OptimizationItem {
  final String id;
  final String title;
  final String currentStatus;
  final String effect;
  final IconData icon;
  bool isEnabled;
  final bool isAutomatic; // true: 자동, false: 수동

  OptimizationItem({
    required this.id,
    required this.title,
    required this.currentStatus,
    required this.effect,
    required this.icon,
    this.isEnabled = false,
    required this.isAutomatic,
  });
}

/// 섹션 1: 최적화 현황 대시보드
class OptimizationDashboardCard extends StatelessWidget {
  const OptimizationDashboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    // 더미 데이터
    final stats = OptimizationStats(
      lastOptimizedAt: DateTime.now().subtract(const Duration(hours: 2)),
      todayOptimizationCount: 3,
      todayTotalSaved: const Duration(hours: 2, minutes: 15),
      appsKilled: 12,
      memoryMB: 234,
      cacheMB: 512,
      servicesStopped: 5,
    );

    final lastOptimizedText = _formatTimeAgo(stats.lastOptimizedAt);
    final todaySavedText = _formatDuration(stats.todayTotalSaved);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green[400]!,
            Colors.teal[400]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                const Icon(
                  Icons.dashboard,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '최적화 현황',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 요약 정보
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    icon: Icons.access_time,
                    label: '마지막 최적화',
                    value: lastOptimizedText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    icon: Icons.refresh,
                    label: '오늘 횟수',
                    value: '${stats.todayOptimizationCount}회',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    icon: Icons.battery_std,
                    label: '오늘 절약',
                    value: todaySavedText,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 4가지 핵심 지표
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    icon: Icons.apps,
                    value: '${stats.appsKilled}개',
                    label: '종료된 앱',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    icon: Icons.memory,
                    value: '${stats.memoryMB}MB',
                    label: '확보한 메모리',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    icon: Icons.cleaning_services,
                    value: '${stats.cacheMB}MB',
                    label: '정리된 캐시',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    icon: Icons.settings_power,
                    value: '${stats.servicesStopped}개',
                    label: '중지된 서비스',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 프로그레스 바 (오늘 목표 대비)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '오늘 목표 진행률',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '75%',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.75,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return '${difference.inDays}일 전';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '+${duration.inHours}시간 ${duration.inMinutes % 60}분';
    } else {
      return '+${duration.inMinutes}분';
    }
  }
}

/// 섹션 2: 자동 최적화 항목
class AutoOptimizationCard extends StatefulWidget {
  const AutoOptimizationCard({super.key});

  @override
  State<AutoOptimizationCard> createState() => _AutoOptimizationCardState();
}

class _AutoOptimizationCardState extends State<AutoOptimizationCard> {
  late List<OptimizationItem> _autoItems;
  final OptimizationSnapshotService _snapshotService = OptimizationSnapshotService();
  bool _hasSnapshot = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _autoItems = _getAutoOptimizationItems();
    _checkSnapshot();
  }

  /// 저장된 스냅샷이 있는지 확인
  Future<void> _checkSnapshot() async {
    final hasSnapshot = await _snapshotService.hasAutoOptimizationSnapshot();
    if (mounted) {
      setState(() {
        _hasSnapshot = hasSnapshot;
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                    const Text('⚡', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '자동 최적화 항목',
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
                const SizedBox(height: 4),
                Text(
                  '원클릭 최적화 시 자동 실행됩니다',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                // 저장/복원 버튼
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _saveCurrentSettings,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save, size: 18),
                        label: const Text('현재 설정 저장'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    if (_hasSnapshot) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _restoreSavedSettings,
                          icon: const Icon(Icons.restore, size: 18),
                          label: const Text('저장된 설정 복원'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // 항목 리스트
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: _autoItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAutoItem(context, item),
              )).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAutoItem(BuildContext context, OptimizationItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.isEnabled
            ? Colors.green[50]!.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 1.0)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isEnabled
              ? Colors.green[400]!.withValues(alpha: 0.5)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: item.isEnabled ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[400]!.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.icon,
              color: Colors.green[600],
              size: 24,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.currentStatus,
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
          
          const SizedBox(width: 12),
          
          // 토글 스위치
          Switch(
            value: item.isEnabled,
            onChanged: (value) => _toggleItem(item),
            activeThumbColor: Colors.green[600],
          ),
        ],
      ),
    );
  }

  void _toggleItem(OptimizationItem item) {
    setState(() {
      item.isEnabled = !item.isEnabled;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          item.isEnabled 
              ? '✓ ${item.title} 활성화됨' 
              : '${item.title} 비활성화됨',
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 현재 설정 저장
  Future<void> _saveCurrentSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 현재 모든 항목의 상태를 Map으로 변환
      final Map<String, bool> states = {};
      for (final item in _autoItems) {
        states[item.id] = item.isEnabled;
      }

      // 스냅샷 저장
      final success = await _snapshotService.saveAutoOptimizationSnapshot(states);

      if (mounted) {
        if (success) {
          setState(() {
            _hasSnapshot = true;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('현재 설정이 저장되었습니다'),
                ],
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green[600],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('설정 저장에 실패했습니다'),
                ],
              ),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류 발생: $e'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 저장된 설정 복원
  Future<void> _restoreSavedSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 저장된 스냅샷 불러오기
      final savedStates = await _snapshotService.loadAutoOptimizationSnapshot();

      if (savedStates == null || savedStates.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('저장된 설정이 없습니다'),
                ],
              ),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // 저장된 상태로 복원
      int restoredCount = 0;
      for (final item in _autoItems) {
        if (savedStates.containsKey(item.id)) {
          final savedValue = savedStates[item.id]!;
          if (item.isEnabled != savedValue) {
            item.isEnabled = savedValue;
            restoredCount++;
          }
        }
      }

      if (mounted) {
        setState(() {
          // UI 업데이트를 위해 setState 호출
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('저장된 설정으로 복원되었습니다 ($restoredCount개 항목)'),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('복원 실패: $e'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<OptimizationItem> _getAutoOptimizationItems() {
    return [
      OptimizationItem(
        id: 'background_apps',
        title: '백그라운드 앱 종료',
        currentStatus: '현재 실행 중: 15개 앱',
        effect: '+25분',
        icon: Icons.apps,
        isEnabled: false,
        isAutomatic: true,
      ),
      OptimizationItem(
        id: 'memory_clean',
        title: '메모리 정리',
        currentStatus: '사용 가능: 1.2GB / 4GB',
        effect: '+15분',
        icon: Icons.memory,
        isEnabled: false,
        isAutomatic: true,
      ),
      OptimizationItem(
        id: 'cache_clean',
        title: '캐시 정리',
        currentStatus: '누적: 450MB',
        effect: '+10분',
        icon: Icons.cleaning_services,
        isEnabled: false,
        isAutomatic: true,
      ),
      OptimizationItem(
        id: 'services_stop',
        title: '불필요한 서비스 중지',
        currentStatus: '실행 중: 8개 서비스',
        effect: '+20분',
        icon: Icons.settings_power,
        isEnabled: false,
        isAutomatic: true,
      ),
      OptimizationItem(
        id: 'brightness_auto',
        title: '화면 밝기 자동 조절',
        currentStatus: '현재: 80% → 목표: 40%',
        effect: '+20분',
        icon: Icons.brightness_6,
        isEnabled: false,
        isAutomatic: true,
      ),
    ];
  }
}

/// 섹션 3: 수동 설정 항목
class ManualOptimizationCard extends StatefulWidget {
  const ManualOptimizationCard({super.key});

  @override
  State<ManualOptimizationCard> createState() => _ManualOptimizationCardState();
}

class _ManualOptimizationCardState extends State<ManualOptimizationCard> {
  final OptimizationSnapshotService _snapshotService = OptimizationSnapshotService();
  final SystemSettingsService _systemSettingsService = SystemSettingsService();
  final Map<String, String?> _previousValues = {}; // 항목별 이전 값 캐시

  @override
  void initState() {
    super.initState();
    _loadPreviousValues();
  }

  /// 저장된 이전 값 불러오기
  Future<void> _loadPreviousValues() async {
    final manualItems = _getManualOptimizationItems();
    for (final item in manualItems) {
      final previousValue = await _snapshotService.getManualSettingPreviousValue(item.id);
      if (mounted) {
        setState(() {
          _previousValues[item.id] = previousValue;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final manualItems = _getManualOptimizationItems();

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
            offset: const Offset(0, 2),
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
                    const Text('⚙️', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '수동 설정 항목',
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
                const SizedBox(height: 4),
                Text(
                  '시스템 설정 화면으로 이동합니다',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          
          // 항목 리스트
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: manualItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildManualItem(context, item),
              )).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildManualItem(BuildContext context, OptimizationItem item) {
    final previousValue = _previousValues[item.id];
    
    return InkWell(
      onTap: () => _openSettings(context, item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50]!.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 1.0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blue[400]!.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 아이콘
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[400]!.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    color: Colors.blue[600],
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.currentStatus,
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
                
                const SizedBox(width: 12),
                
                // 화살표 아이콘
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.blue[600],
                  size: 16,
                ),
              ],
            ),
            
            // 이전 값 표시 (있는 경우)
            if (previousValue != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange[50]!.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 1.0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange[300]!.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 14,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '이전 값: $previousValue',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[700],
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 항목 클릭 전 현재 시스템 설정 값 읽기 및 저장
  Future<String?> _readAndSaveCurrentValue(OptimizationItem item) async {
    try {
      String currentValue;
      
      // 항목별로 현재 시스템 설정 값 읽기
      switch (item.id) {
        case 'battery_saver':
          final enabled = await _systemSettingsService.isBatterySaverEnabled();
          currentValue = enabled == true ? '켜짐' : '꺼짐';
          break;
        case 'network_optimize':
          final type = await _systemSettingsService.getNetworkConnectionType();
          currentValue = type ?? '알 수 없음';
          break;
        case 'location_save':
          final status = await _systemSettingsService.getLocationServiceStatus();
          currentValue = status ?? '알 수 없음';
          break;
        case 'sync_frequency':
          final status = await _systemSettingsService.getSyncStatus();
          currentValue = status ?? '알 수 없음';
          break;
        case 'screen_timeout':
          final timeout = await _systemSettingsService.getScreenTimeout();
          if (timeout != null && timeout > 0) {
            // 초를 분:초 형식으로 변환
            final minutes = timeout ~/ 60;
            final seconds = timeout % 60;
            if (minutes > 0) {
              currentValue = seconds > 0 ? '${minutes}분 ${seconds}초' : '${minutes}분';
            } else {
              currentValue = '${seconds}초';
            }
          } else {
            currentValue = '알 수 없음';
          }
          break;
        default:
          // 기본값은 currentStatus 사용
          currentValue = item.currentStatus;
      }
      
      // 이전 값 저장
      await _snapshotService.saveManualSettingPreviousValue(item.id, currentValue);
      if (mounted) {
        setState(() {
          _previousValues[item.id] = currentValue;
        });
      }
      
      return currentValue;
    } catch (e) {
      debugPrint('현재 값 읽기 실패: $e');
      return null;
    }
  }

  void _openSettings(BuildContext context, OptimizationItem item) async {
    // 항목 클릭 전에 현재 시스템 설정 값 읽기 및 저장
    await _readAndSaveCurrentValue(item);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.title} 설정 화면으로 이동합니다'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<OptimizationItem> _getManualOptimizationItems() {
    return [
      OptimizationItem(
        id: 'battery_saver',
        title: '배터리 세이버 모드',
        currentStatus: '상태: 꺼짐',
        effect: '+30분',
        icon: Icons.battery_std,
        isEnabled: false,
        isAutomatic: false,
      ),
      OptimizationItem(
        id: 'network_optimize',
        title: '네트워크 최적화 (5G → Wi-Fi)',
        currentStatus: '현재: 5G 연결',
        effect: '+25분',
        icon: Icons.signal_cellular_alt,
        isEnabled: false,
        isAutomatic: false,
      ),
      OptimizationItem(
        id: 'location_save',
        title: '위치 서비스 절약 모드',
        currentStatus: '현재: 고정밀도',
        effect: '+15분',
        icon: Icons.location_on,
        isEnabled: false,
        isAutomatic: false,
      ),
      OptimizationItem(
        id: 'sync_frequency',
        title: '동기화 빈도 조절',
        currentStatus: '상태: 자동 동기화 켜짐',
        effect: '+20분',
        icon: Icons.sync,
        isEnabled: false,
        isAutomatic: false,
      ),
      OptimizationItem(
        id: 'screen_timeout',
        title: '화면 시간 초과 단축',
        currentStatus: '현재: 2분 → 권장: 30초',
        effect: '+10분',
        icon: Icons.timer,
        isEnabled: false,
        isAutomatic: false,
      ),
    ];
  }
}

/// 섹션 4: 최적화 팁 & 인사이트
class OptimizationTipsCard extends StatelessWidget {
  const OptimizationTipsCard({super.key});

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
            offset: const Offset(0, 2),
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
                const Text('💡', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '맞춤 추천',
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
          
          // 배터리 소모가 많은 앱
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildBatteryDrainApps(context),
          ),
          
          const SizedBox(height: 16),
          
          // 오늘의 배터리 절약 팁
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildDailyTips(context),
          ),
          
          const SizedBox(height: 16),
          
          // 최적화 통계
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildOptimizationStats(context),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBatteryDrainApps(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50]!.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 1.0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple[400]!.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.battery_alert,
                color: Colors.purple[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '배터리 소모가 많은 앱 3개',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAppItem(context, 'Instagram', '15%', Colors.pink),
          _buildAppItem(context, 'YouTube', '12%', Colors.red),
          _buildAppItem(context, '카카오톡', '8%', Colors.yellow[700]!),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('앱별 설정 관리 기능은 준비 중입니다'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple[600],
                side: BorderSide(color: Colors.purple[400]!),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '앱별 설정',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppItem(BuildContext context, String appName, String percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              appName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _buildDailyTips(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50]!.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 1.0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange[400]!.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: Colors.orange[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '오늘의 배터리 절약 팁',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem(context, '점심시간에 비행기 모드를 켜면 +30분'),
          _buildTipItem(context, '밤에 다크모드를 사용하면 +20분'),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple[400]!.withValues(alpha: 0.1),
            Colors.purple[600]!.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple[400]!.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: Colors.purple[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '최적화 통계',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatRow(context, '이번 주 평균 절약', '1시간 45분'),
          const SizedBox(height: 8),
          _buildStatRow(context, '가장 효과적인 항목', '백그라운드 앱 종료'),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.purple[600],
          ),
        ),
      ],
    );
  }
}
