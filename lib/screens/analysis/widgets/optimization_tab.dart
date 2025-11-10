import 'package:flutter/material.dart';
import '../../../services/optimization_snapshot_service.dart';
import '../../../services/system_settings_service.dart';
import 'optimization/models/optimization_models.dart';
import 'optimization/widgets/optimization_dashboard_card.dart';
import 'optimization/widgets/auto_optimization_card.dart';
import 'optimization/widgets/optimization_tips_card.dart';

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

  /// 저장된 이전 값이 하나라도 있는지 확인
  bool _hasAnyPreviousValue() {
    return _previousValues.values.any((value) => value != null);
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
                // 사용자 안내 메시지
                if (_hasAnyPreviousValue()) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50]!.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 1.0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue[200]!.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '항목을 클릭하면 현재 설정 값이 자동으로 저장됩니다. 이전 값은 복원 시 참고하세요.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[700],
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange[50]!.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 1.0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange[300]!.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.orange[200]!.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.history,
                        size: 14,
                        color: Colors.orange[800],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '이전 값',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            previousValue,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 삭제 버튼
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.orange[700],
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      onPressed: () => _clearPreviousValue(item.id),
                      tooltip: '이전 값 삭제',
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
              currentValue = seconds > 0 ? '$minutes분 $seconds초' : '$minutes분';
            } else {
              currentValue = '$seconds초';
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

  /// 이전 값 삭제
  Future<void> _clearPreviousValue(String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이전 값 삭제'),
        content: const Text('저장된 이전 값을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _snapshotService.clearManualSettingPreviousValue(itemId);
      if (mounted) {
        setState(() {
          _previousValues[itemId] = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('이전 값이 삭제되었습니다'),
              ],
            ),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _openSettings(BuildContext context, OptimizationItem item) async {
    // 항목 클릭 전에 현재 시스템 설정 값 읽기 및 저장
    final savedValue = await _readAndSaveCurrentValue(item);
    
    // 저장 성공 시 피드백
    if (savedValue != null && mounted) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '현재 설정 값이 저장되었습니다: $savedValue',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green[600],
        ),
      );
    }
    
    // 시스템 설정 화면으로 이동 안내
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text('${item.title} 설정 화면으로 이동합니다'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
