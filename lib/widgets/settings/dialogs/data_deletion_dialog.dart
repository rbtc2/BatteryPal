import 'package:flutter/material.dart';
import '../../../services/battery_history_database_service.dart';

/// 데이터 삭제 다이얼로그
class DataDeletionDialog extends StatefulWidget {
  const DataDeletionDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const DataDeletionDialog(),
    );
  }

  @override
  State<DataDeletionDialog> createState() => _DataDeletionDialogState();
}

class _DataDeletionDialogState extends State<DataDeletionDialog> {
  final BatteryHistoryDatabaseService _databaseService = BatteryHistoryDatabaseService();
  
  // 선택된 데이터 타입
  bool _deleteChargingHistory = false; // 충전 현황 데이터 (충전 전류)
  bool _deleteChargingAnalysis = false; // 충전 분석 데이터 (충전 세션)
  bool _deleteBatteryHistory = false; // 배터리 히스토리 데이터
  
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.delete_outline, size: 24),
          SizedBox(width: 8),
          Text('저장된 데이터 삭제'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '삭제할 데이터를 선택하세요. 이 작업은 되돌릴 수 없습니다.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            // 충전 현황 데이터
            CheckboxListTile(
              title: const Text('충전 현황 데이터'),
              subtitle: const Text('충전 전류 기록 등'),
              value: _deleteChargingHistory,
              onChanged: _isDeleting ? null : (value) {
                setState(() {
                  _deleteChargingHistory = value ?? false;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            
            // 충전 분석 데이터
            CheckboxListTile(
              title: const Text('충전 분석 데이터'),
              subtitle: const Text('충전 세션 기록 등'),
              value: _deleteChargingAnalysis,
              onChanged: _isDeleting ? null : (value) {
                setState(() {
                  _deleteChargingAnalysis = value ?? false;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            
            // 배터리 히스토리 데이터
            CheckboxListTile(
              title: const Text('배터리 히스토리 데이터'),
              subtitle: const Text('배터리 레벨, 온도 등 전체 기록'),
              value: _deleteBatteryHistory,
              onChanged: _isDeleting ? null : (value) {
                setState(() {
                  _deleteBatteryHistory = value ?? false;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 8),
            
            // 경고 메시지
            if (_deleteChargingHistory || _deleteChargingAnalysis || _deleteBatteryHistory)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '선택한 데이터가 영구적으로 삭제됩니다.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: (_isDeleting || 
                     (!_deleteChargingHistory && !_deleteChargingAnalysis && !_deleteBatteryHistory))
              ? null
              : () => _confirmAndDelete(context),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: _isDeleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('삭제'),
        ),
      ],
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터 삭제 확인'),
        content: const Text(
          '정말로 선택한 데이터를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final deletedItems = <String>[];

      // 충전 현황 데이터 삭제
      if (_deleteChargingHistory) {
        try {
          final count = await _databaseService.deleteAllChargingCurrentData();
          if (count > 0) {
            deletedItems.add('충전 현황 데이터 ($count개)');
          }
        } catch (e) {
          debugPrint('충전 현황 데이터 삭제 실패: $e');
        }
      }

      // 충전 분석 데이터 삭제
      if (_deleteChargingAnalysis) {
        try {
          final count = await _databaseService.deleteAllChargingSessions();
          if (count > 0) {
            deletedItems.add('충전 분석 데이터 ($count개)');
          }
        } catch (e) {
          debugPrint('충전 분석 데이터 삭제 실패: $e');
        }
      }

      // 배터리 히스토리 데이터 삭제
      if (_deleteBatteryHistory) {
        try {
          final count = await _databaseService.deleteAllBatteryData();
          if (count > 0) {
            deletedItems.add('배터리 히스토리 데이터 ($count개)');
          }
        } catch (e) {
          debugPrint('배터리 히스토리 데이터 삭제 실패: $e');
        }
      }

      if (!context.mounted) return;

      // 성공 메시지
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deletedItems.isEmpty
                ? '삭제할 데이터가 없습니다.'
                : '${deletedItems.join(', ')} 삭제 완료',
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('데이터 삭제 실패: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

