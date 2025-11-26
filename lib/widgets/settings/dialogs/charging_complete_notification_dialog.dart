import 'package:flutter/material.dart';
import '../../../services/settings_service.dart';

/// 충전 완료 알림 설정 다이얼로그
/// 2025년 최신 스타일 적용
class ChargingCompleteNotificationDialog extends StatelessWidget {
  final SettingsService settingsService;

  const ChargingCompleteNotificationDialog({
    super.key,
    required this.settingsService,
  });

  static void show(BuildContext context, SettingsService settingsService) {
    showDialog(
      context: context,
      builder: (context) => ChargingCompleteNotificationDialog(
        settingsService: settingsService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더 (그라데이션 배경)
              _buildHeader(context),
              
              // 스크롤 가능한 콘텐츠
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildContent(context, setState),
                ),
              ),
              
              // 하단 액션 버튼
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 헤더 (그라데이션 배경 + 큰 아이콘)
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.battery_charging_full,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '충전 완료 알림',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '100% 충전 완료 시 알림 받기',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// 콘텐츠
  Widget _buildContent(BuildContext context, StateSetter setState) {
    final isEnabled = settingsService.appSettings.chargingCompleteNotificationEnabled;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 메인 토글 (큰 카드 형태)
        _buildMainToggleCard(context, setState, isEnabled),
        
        if (isEnabled) ...[
          const SizedBox(height: 24),
          
          // 충전 타입 선택 (FilterChip 그리드)
          _buildChargingTypeSelector(context, setState),
          
          const SizedBox(height: 24),
          
          // 과충전 방지 설정 (접을 수 있는 ExpansionTile 스타일)
          _buildOverchargeProtectionSection(context, setState),
        ],
      ],
    );
  }

  /// 메인 토글 카드
  Widget _buildMainToggleCard(
    BuildContext context,
    StateSetter setState,
    bool isEnabled,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isEnabled
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.notifications_active,
              size: 28,
              color: isEnabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '충전 완료 알림 활성화',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '100% 충전 완료 시 알림 받기',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (value) {
              settingsService.updateChargingCompleteNotification(value);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  /// 충전 타입 선택 (FilterChip 그리드)
  Widget _buildChargingTypeSelector(
    BuildContext context,
    StateSetter setState,
  ) {
    final isFastSelected = settingsService.appSettings.chargingCompleteNotifyOnFastCharging;
    final isNormalSelected = settingsService.appSettings.chargingCompleteNotifyOnNormalCharging;
    final hasError = !isFastSelected && !isNormalSelected;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasError
              ? Theme.of(context).colorScheme.error.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: hasError ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bolt,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '충전 타입 선택',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilterChip(
                avatar: Icon(
                  Icons.bolt,
                  size: 18,
                  color: isFastSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
                label: const Text('고속 충전'),
                selected: isFastSelected,
                onSelected: (selected) {
                  settingsService.updateChargingCompleteNotifyOnFastCharging(selected);
                  setState(() {});
                },
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isFastSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              FilterChip(
                avatar: Icon(
                  Icons.usb,
                  size: 18,
                  color: isNormalSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
                label: const Text('일반 충전'),
                selected: isNormalSelected,
                onSelected: (selected) {
                  settingsService.updateChargingCompleteNotifyOnNormalCharging(selected);
                  setState(() {});
                },
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isNormalSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ],
          ),
          if (hasError) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '최소 하나의 충전 타입을 선택해야 합니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 과충전 방지 설정 (접을 수 있는 ExpansionTile 스타일)
  Widget _buildOverchargeProtectionSection(
    BuildContext context,
    StateSetter setState,
  ) {
    final isOverchargeEnabled = settingsService.appSettings.overchargeProtectionEnabled;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          // 헤더 (토글 포함)
          InkWell(
            onTap: () {
              settingsService.updateOverchargeProtection(!isOverchargeEnabled);
              setState(() {});
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isOverchargeEnabled
                          ? Theme.of(context).colorScheme.secondaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.shield,
                      size: 24,
                      color: isOverchargeEnabled
                          ? Theme.of(context).colorScheme.onSecondaryContainer
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '과충전 방지 알림',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '100% 도달 후 과충전 경고 알림 받기',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isOverchargeEnabled,
                    onChanged: (value) {
                      settingsService.updateOverchargeProtection(value);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // 세부 설정 (과충전 방지 활성화 시에만 표시)
          if (isOverchargeEnabled) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 알림 속도 설정
                  Text(
                    '알림 속도',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'fast',
                        label: Text('빠름'),
                        tooltip: '기본값의 50% (더 빠른 알림)',
                      ),
                      ButtonSegment<String>(
                        value: 'normal',
                        label: Text('보통'),
                        tooltip: '기본값 (권장)',
                      ),
                      ButtonSegment<String>(
                        value: 'slow',
                        label: Text('느림'),
                        tooltip: '기본값의 150% (더 느린 알림)',
                      ),
                    ],
                    selected: {settingsService.appSettings.overchargeAlertSpeed},
                    onSelectionChanged: (Set<String> newSelection) {
                      if (newSelection.isNotEmpty) {
                        settingsService.updateOverchargeAlertSpeed(newSelection.first);
                        setState(() {});
                      }
                    },
                    style: SegmentedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getSpeedDescription(settingsService.appSettings.overchargeAlertSpeed),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 온도 기반 알림 조정
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.thermostat,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '온도 기반 알림 조정',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '온도 40°C 이상 시 알림 타이밍 50% 단축',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: settingsService.appSettings.temperatureBasedAdjustment,
                          onChanged: (value) {
                            settingsService.updateTemperatureBasedAdjustment(value);
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 하단 액션 버튼
  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            '완료',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// 알림 속도 설명 텍스트 가져오기
  String _getSpeedDescription(String speed) {
    switch (speed) {
      case 'fast':
        return '기본값의 50% (더 빠른 알림)';
      case 'slow':
        return '기본값의 150% (더 느린 알림)';
      case 'normal':
      default:
        return '기본값 (권장)';
    }
  }
}

