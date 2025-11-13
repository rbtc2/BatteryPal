import 'package:flutter/material.dart';
import 'widgets/battery_health_tab.dart';
import 'widgets/charging_patterns_tab.dart';
import 'widgets/optimization_tab.dart';
import '../../utils/dialog_utils.dart';

/// 분석 탭 화면 - 3개의 하위 탭으로 구성된 탭 인터페이스
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

class _AnalysisTabState extends State<AnalysisTab> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void didUpdateWidget(AnalysisTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // initialTabIndex가 변경되면 TabController 업데이트
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      _tabController.animateTo(widget.initialTabIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: const [
            Tab(
              icon: Icon(Icons.battery_full),
              text: '소모',
            ),
            Tab(
              icon: Icon(Icons.charging_station),
              text: '충전',
            ),
            Tab(
              icon: Icon(Icons.tune),
              text: '최적화',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          BatteryHealthTab(
            isProUser: widget.isProUser,
            onProUpgrade: widget.onProToggle,
          ),
          ChargingPatternsTab(
            isProUser: widget.isProUser,
            onProUpgrade: widget.onProToggle,
          ),
          OptimizationTab(
            isProUser: widget.isProUser,
            onProUpgrade: widget.onProToggle,
          ),
        ],
      ),
    );
  }
}
