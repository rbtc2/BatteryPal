import 'package:flutter/material.dart';

/// 배터리 소모 탭 - 배터리 소모량 분석
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
          // 배터리 소모량 관련 내용이 여기에 추가될 예정
        ],
      ),
    );
  }
}
