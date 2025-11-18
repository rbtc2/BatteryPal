import 'package:flutter/material.dart';
import '../../../services/battery_optimization_helper.dart';

/// 배터리 최적화 설정 다이얼로그
class BatteryOptimizationDialog extends StatelessWidget {
  final bool isIgnoring;

  const BatteryOptimizationDialog({
    super.key,
    required this.isIgnoring,
  });

  static Future<void> show(BuildContext context) async {
    final isIgnoring = await BatteryOptimizationHelper.isIgnoringBatteryOptimizations();
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => BatteryOptimizationDialog(isIgnoring: isIgnoring),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.battery_saver,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('배터리 최적화 설정'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isIgnoring
                ? '✅ 배터리 최적화에서 제외되어 있습니다.'
                : '⚠️ 배터리 최적화에서 제외되지 않았습니다.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isIgnoring
                  ? Colors.green
                  : Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '앱이 꺼져 있을 때도 충전 데이터를 수집하려면\n'
            '배터리 최적화에서 제외해야 합니다.\n\n'
            '설정 화면에서 이 앱을 "최적화 안 함"으로\n'
            '설정해주세요.',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            Navigator.of(context).pop();
            await BatteryOptimizationHelper.openBatteryOptimizationSettings();
          },
          icon: const Icon(Icons.settings, size: 18),
          label: const Text('설정으로 이동'),
        ),
      ],
    );
  }
}

