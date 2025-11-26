// 충전 세션 리스트 아이템 위젯
// 개별 세션을 표시하는 재사용 가능한 위젯

import 'package:flutter/material.dart';
import '../models/charging_session_models.dart';
import '../utils/time_slot_utils.dart';

/// 충전 세션 리스트 아이템 위젯
/// 
/// 개별 세션의 정보를 표시하는 카드 형태의 위젯
/// - 세션 제목, 시간대, 배터리 변화량
/// - 충전 시간, 평균 전류, 효율
/// - 전류 변화 이력
class ChargingSessionListItem extends StatefulWidget {
  final ChargingSessionRecord session;
  final VoidCallback? onTap;

  const ChargingSessionListItem({
    super.key,
    required this.session,
    this.onTap,
  });

  @override
  State<ChargingSessionListItem> createState() => _ChargingSessionListItemState();
}

class _ChargingSessionListItemState extends State<ChargingSessionListItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final color = TimeSlotUtils.getTimeSlotColor(session.timeSlot);
    final efficiencyColor = TimeSlotUtils.getEfficiencyColor(session.efficiency);
    
    // 시간 포맷팅
    final startTimeStr = '${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr = '${session.endTime.hour.toString().padLeft(2, '0')}:${session.endTime.minute.toString().padLeft(2, '0')}';
    final timeRange = '$startTimeStr - $endTimeStr';
    
    // 배터리 변화량 포맷팅
    final batteryChange = '${session.startBatteryLevel.toStringAsFixed(0)}% → ${session.endBatteryLevel.toStringAsFixed(0)}%';
    
    // 충전 시간 포맷팅
    final duration = _formatDuration(session.duration);
    
    // 평균 전류 포맷팅
    final avgCurrent = '${session.avgCurrent.toStringAsFixed(0)}mA';
    
    // 효율 포맷팅
    final efficiency = '${session.efficiency.toStringAsFixed(0)}%';
    
    // 평균 온도 포맷팅
    final temperature = '${session.avgTemperature.toStringAsFixed(1)}°C';

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
        widget.onTap?.call();
      },
      child: Container(
        constraints: BoxConstraints(
          minHeight: _isExpanded ? 200 : 180,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: color,
              width: 4,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 아이콘 + 제목 + 시간 + 효율성
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(session.icon, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.sessionTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeRange,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: efficiencyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '효율 $efficiency',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: efficiencyColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 주요 정보 그리드 (고정 높이로 일관성 확보)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildInfoItem(context, batteryChange, '배터리 변화', Colors.green),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoItem(context, duration, '충전 시간', Colors.blue),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoItem(context, avgCurrent, '평균 전류', color),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 온도 정보
            Row(
              children: [
                const Icon(Icons.thermostat, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '평균 온도: $temperature',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (session.speedChanges.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${session.speedChanges.length}회 변경',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            
            // 속도 변경 이력 (있을 경우)
            if (session.speedChanges.isNotEmpty && _isExpanded) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timeline, size: 14, color: color),
                        const SizedBox(width: 6),
                        Text(
                          '속도 변경 이력',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...session.speedChanges.map((change) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_formatTime(change.timestamp)} ${change.description}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String value, String label, Color color) {
    return Container(
      height: 60, // 고정 높이 설정
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Duration을 읽기 쉬운 형식으로 포맷팅
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '$hours시간 $minutes분';
    } else {
      return '$minutes분';
    }
  }

  /// DateTime을 시간 형식으로 포맷팅
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

