import 'package:flutter/material.dart';

/// 개요 탭 - 빈 위젯 (4탭 구조로 변경됨)
class OverviewTab extends StatelessWidget {
  final bool isProUser;
  final VoidCallback? onProUpgrade;
  final Function(int)? onTabChange;

  const OverviewTab({
    super.key,
    required this.isProUser,
    this.onProUpgrade,
    this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '개요 탭이 제거되었습니다.\n4탭 구조로 변경되었습니다.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
      ),
    );
  }
}
