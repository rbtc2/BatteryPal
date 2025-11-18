import 'package:flutter/material.dart';
import '../../../services/settings_service.dart';

/// 커스텀 퍼센트 추가 다이얼로그
class AddCustomPercentDialog extends StatelessWidget {
  final SettingsService settingsService;
  final VoidCallback onAdded;

  const AddCustomPercentDialog({
    super.key,
    required this.settingsService,
    required this.onAdded,
  });

  static void show(
    BuildContext context,
    SettingsService settingsService,
    VoidCallback onAdded,
  ) {
    showDialog(
      context: context,
      builder: (context) => AddCustomPercentDialog(
        settingsService: settingsService,
        onAdded: onAdded,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    
    return AlertDialog(
      title: const Text('커스텀 퍼센트 추가'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '퍼센트 (10-100)',
              hintText: '예: 75',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            final percent = double.tryParse(controller.text);
            if (percent != null && percent >= 10 && percent <= 100) {
              settingsService.addChargingPercentThreshold(percent);
              Navigator.of(context).pop();
              onAdded();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('10-100 사이의 숫자를 입력해주세요.'),
                ),
              );
            }
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
}

