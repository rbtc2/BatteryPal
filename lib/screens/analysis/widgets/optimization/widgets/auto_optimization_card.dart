import 'package:flutter/material.dart';
import '../../../../../services/optimization_snapshot_service.dart';
import '../models/optimization_models.dart';
import '../utils/optimization_formatters.dart';

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
  DateTime? _savedAt;

  @override
  void initState() {
    super.initState();
    _autoItems = _getAutoOptimizationItems();
    _checkSnapshot();
  }

  /// 저장된 스냅샷이 있는지 확인
  Future<void> _checkSnapshot() async {
    final hasSnapshot = await _snapshotService.hasAutoOptimizationSnapshot();
    if (hasSnapshot) {
      final savedAt = await _snapshotService.getSavedAt();
      if (mounted) {
        setState(() {
          _hasSnapshot = true;
          _savedAt = savedAt;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _hasSnapshot = false;
          _savedAt = null;
        });
      }
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
                // 저장 시간 표시
                if (_hasSnapshot && _savedAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '저장 시간: ${formatSavedTime(_savedAt!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
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
          final savedAt = await _snapshotService.getSavedAt();
          if (!mounted) return;
          setState(() {
            _hasSnapshot = true;
            _savedAt = savedAt;
          });
          
          if (!mounted) return;
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
          if (!mounted) return;
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

