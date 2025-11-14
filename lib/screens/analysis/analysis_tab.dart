import 'package:flutter/material.dart';
import 'widgets/battery_drain_tab.dart';
import 'widgets/charging_patterns_tab.dart';
import '../../utils/dialog_utils.dart';

/// 분석 탭 화면 - 2개의 하위 탭으로 구성된 탭 인터페이스
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
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    // 탭 변경 리스너 추가
    _tabController.addListener(_onTabChanged);
  }
  
  /// 탭 변경 감지
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      // 탭 변경 완료 시 상태 업데이트 (BatteryDrainTab에 전달)
      setState(() {});
    }
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
    _tabController.removeListener(_onTabChanged);
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          BatteryDrainTab(
            isProUser: widget.isProUser,
            onProUpgrade: widget.onProToggle,
            tabController: _tabController,
            tabIndex: 0, // 소모 탭 인덱스
          ),
          ChargingPatternsTab(
            isProUser: widget.isProUser,
            onProUpgrade: widget.onProToggle,
          ),
        ],
      ),
    );
  }
}
