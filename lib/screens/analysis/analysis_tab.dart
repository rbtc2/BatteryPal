import 'package:flutter/material.dart';
import 'widgets/overview_tab.dart';
import 'widgets/battery_health_tab.dart';
import 'widgets/charging_patterns_tab.dart';
import 'widgets/usage_analytics_tab.dart';
import 'widgets/optimization_tab.dart';

/// 분석 탭 화면 - 5개의 하위 탭으로 구성된 탭 인터페이스
class AnalysisTab extends StatefulWidget {
  final bool isProUser;
  final VoidCallback onProToggle;

  const AnalysisTab({
    super.key,
    required this.isProUser,
    required this.onProToggle,
  });

  @override
  State<AnalysisTab> createState() => _AnalysisTabState();
}

class _AnalysisTabState extends State<AnalysisTab> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
                // TODO: Pro 업그레이드 다이얼로그 표시
                widget.onProToggle();
              },
              child: const Text('Pro로 업그레이드'),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard),
            ),
            Tab(
              icon: Icon(Icons.battery_full),
            ),
            Tab(
              icon: Icon(Icons.charging_station),
            ),
            Tab(
              icon: Icon(Icons.analytics),
            ),
            Tab(
              icon: Icon(Icons.tune),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          OverviewTab(
            isProUser: widget.isProUser,
            onProUpgrade: widget.onProToggle,
          ),
          BatteryHealthTab(
            isProUser: widget.isProUser,
            onProUpgrade: widget.onProToggle,
          ),
          ChargingPatternsTab(
            isProUser: widget.isProUser,
            onProUpgrade: widget.onProToggle,
          ),
          UsageAnalyticsTab(
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
