// 백업 파일: 이 파일은 나중에 복구할 때 사용됩니다.
// import 경로 오류는 정상입니다 (백업 디렉토리 구조 때문).
// 복구 시 import 경로를 수정해야 합니다.

import 'package:flutter/material.dart';
import 'widgets/charging_patterns_tab.dart';
// 복구 시 경로 수정 필요: lib/utils/dialog_utils.dart
import '../../utils/dialog_utils.dart';

/// 분석 탭 화면 - 충전 패턴 분석
class AnalysisTab extends StatefulWidget {
  final bool isProUser;
  final VoidCallback onProToggle;
  final int initialTabIndex;

  const AnalysisTab({
    super.key,
    required this.isProUser,
    required this.onProToggle,
    this.initialTabIndex = 0,
  });

  @override
  State<AnalysisTab> createState() => _AnalysisTabState();
}

class _AnalysisTabState extends State<AnalysisTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('배터리 분석'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          if (!widget.isProUser)
            TextButton(
              onPressed: () {
                DialogUtils.showAnalysisProUpgradeDialog(
                  context,
                  onUpgrade: widget.onProToggle,
                );
              },
              child: const Text('Pro로 업그레이드'),
            ),
        ],
      ),
      body: ChargingPatternsTab(
        isProUser: widget.isProUser,
        onProUpgrade: widget.onProToggle,
      ),
    );
  }
}
