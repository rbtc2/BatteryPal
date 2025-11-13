import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import '../../models/models.dart';
import '../../services/settings_service.dart';

/// 표시할 정보 타입 열거형
enum DisplayInfoType {
  batteryLevel,    // 배터리 레벨
  chargingCurrent, // 충전 전류
  batteryTemp,     // 배터리 온도
}

/// 표시 정보 데이터 모델
class DisplayInfo {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData? icon;
  
  DisplayInfo({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    this.icon,
  });
}

/// 충전 속도 타입 정보
class _ChargingSpeedType {
  final String label;
  final IconData icon;
  final Color color;
  
  _ChargingSpeedType({
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// 배터리 상태 카드 위젯
/// 홈 탭에서 배터리 정보를 표시하는 카드 (원형 게이지 디자인)
class BatteryStatusCard extends StatefulWidget {
  final BatteryInfo? batteryInfo;
  final SettingsService? settingsService;

  const BatteryStatusCard({
    super.key,
    this.batteryInfo,
    this.settingsService,
  });

  @override
  State<BatteryStatusCard> createState() => _BatteryStatusCardState();
}

class _BatteryStatusCardState extends State<BatteryStatusCard>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _cycleController; // 순환 표시용
  
  // 현재 표시 중인 정보 인덱스
  int _currentDisplayIndex = 0;
  
  // 자동 순환 활성화 여부
  bool _isAutoCycleEnabled = true;
  
  // 사용자 상호작용 후 일시정지 시간
  Timer? _pauseTimer;
  
  // 자동 순환 타이머
  Timer? _cycleTimer;
  
  // 스와이프 시작 위치
  double _swipeStartX = 0;
  
  @override
  void initState() {
    super.initState();
    
    // 회전 애니메이션 컨트롤러 (3초 주기)
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    // 펄스 애니메이션 컨트롤러 (1.5초 주기)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // 순환 표시 애니메이션 컨트롤러 (5초 주기)
    _cycleController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    
    // 충전 중일 때만 애니메이션 시작
    if (widget.batteryInfo?.isCharging == true) {
      _rotationController.repeat();
      _pulseController.repeat(reverse: true);
    }
    
    // 설정에 따라 자동 순환 시작
    _updateAutoCycleFromSettings();
  }
  
  @override
  void didUpdateWidget(BatteryStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 충전 상태가 변경될 때 애니메이션 제어
    if (widget.batteryInfo?.isCharging != oldWidget.batteryInfo?.isCharging) {
      if (widget.batteryInfo?.isCharging == true) {
        _rotationController.repeat();
        _pulseController.repeat(reverse: true);
        _updateAutoCycleFromSettings();
      } else {
        _rotationController.stop();
        _pulseController.stop();
        _stopAutoCycle();
        _currentDisplayIndex = 0; // 기본 배터리 정보로 리셋
      }
    }
    
    // 설정이 변경될 때 자동 순환 업데이트
    if (widget.settingsService != oldWidget.settingsService) {
      _updateAutoCycleFromSettings();
    }
  }
  
  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _cycleController.dispose();
    _pauseTimer?.cancel();
    _cycleTimer?.cancel();
    super.dispose();
  }
  
  /// 설정에 따라 자동 순환 업데이트
  void _updateAutoCycleFromSettings() {
    final settings = widget.settingsService?.appSettings;
    if (settings == null) {
      // 설정이 없으면 기본값으로 자동 순환 시작
      if (widget.batteryInfo?.isCharging == true) {
        _startAutoCycle();
      }
      return;
    }
    
    // 자동 순환이 꺼져있으면 중지
    if (settings.batteryDisplayCycleSpeed == BatteryDisplayCycleSpeed.off) {
      _stopAutoCycle();
      _isAutoCycleEnabled = false;
      return;
    }
    
    // 자동 순환 활성화
    _isAutoCycleEnabled = true;
    
    // 충전 중일 때만 자동 순환 시작
    if (widget.batteryInfo?.isCharging == true) {
      _startAutoCycle();
    }
  }
  
  /// 자동 순환 시작
  void _startAutoCycle() {
    if (_isAutoCycleEnabled) {
      _cycleController.repeat();
      _startCycleTimer();
    }
  }
  
  /// 순환 타이머 시작
  void _startCycleTimer() {
    // 이전 타이머가 있으면 취소
    _cycleTimer?.cancel();
    
    final settings = widget.settingsService?.appSettings;
    final durationSeconds = settings?.batteryDisplayCycleSpeed.durationSeconds ?? 5;
    
    _cycleTimer = Timer.periodic(Duration(seconds: durationSeconds), (timer) {
      if (mounted && widget.batteryInfo?.isCharging == true) {
        _nextDisplayInfo();
      } else {
        timer.cancel();
        _cycleTimer = null;
      }
    });
  }
  
  /// 자동 순환 중지
  void _stopAutoCycle() {
    _cycleController.stop();
    _pauseTimer?.cancel();
    _cycleTimer?.cancel();
    _cycleTimer = null;
  }
  
  /// 다음 정보로 전환 (자동 순환용)
  void _nextDisplayInfo() {
    _changeDisplayIndex(1, pauseAutoCycle: true);
  }
  
  /// 표시 정보 전환 (공통 로직)
  /// [increment] 1: 다음, -1: 이전
  /// [pauseAutoCycle] 자동 순환 일시정지 여부
  void _changeDisplayIndex(int increment, {bool pauseAutoCycle = false}) {
    final settings = widget.settingsService?.appSettings;
    
    setState(() {
      final availableInfoTypes = _getAvailableInfoTypes(settings);
      if (availableInfoTypes.isNotEmpty) {
        if (increment > 0) {
          _currentDisplayIndex = (_currentDisplayIndex + 1) % availableInfoTypes.length;
        } else {
          _currentDisplayIndex = (_currentDisplayIndex - 1 + availableInfoTypes.length) % availableInfoTypes.length;
        }
      }
    });
    
    // 자동 순환이 활성화되어 있고 일시정지가 요청되면 일시정지
    if (pauseAutoCycle && _isAutoCycleEnabled) {
      _pauseAutoCycle();
    }
  }
  
  /// 사용자 상호작용 후 일시정지
  void _pauseAutoCycle() {
    _stopAutoCycle();
    _pauseTimer?.cancel();
    _pauseTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && widget.batteryInfo?.isCharging == true) {
        _startAutoCycle();
      }
    });
  }
  
  /// 현재 표시할 정보 가져오기
  DisplayInfo _getCurrentDisplayInfo() {
    final batteryInfo = widget.batteryInfo;
    final settings = widget.settingsService?.appSettings;
    
    if (batteryInfo == null) {
      return DisplayInfo(
        title: '배터리',
        value: '--%',
        subtitle: '정보 없음',
        color: Colors.grey,
      );
    }
    
    // 설정에 따라 표시할 정보 필터링
    final availableInfoTypes = _getAvailableInfoTypes(settings);
    if (availableInfoTypes.isEmpty) {
      // 표시할 정보가 없으면 기본 배터리 정보
      return DisplayInfo(
        title: '배터리',
        value: '${batteryInfo.level.toInt()}%',
        subtitle: batteryInfo.isCharging ? '충전 중' : '방전 중',
        color: _getLevelColor(batteryInfo.level),
        icon: batteryInfo.isCharging ? Icons.bolt : Icons.battery_std,
      );
    }
    
    // 현재 인덱스를 사용 가능한 정보 범위로 조정
    final adjustedIndex = _currentDisplayIndex % availableInfoTypes.length;
    final infoType = availableInfoTypes[adjustedIndex];
    
    switch (infoType) {
      case DisplayInfoType.batteryLevel:
        return DisplayInfo(
          title: '배터리',
          value: '${batteryInfo.level.toInt()}%',
          subtitle: batteryInfo.isCharging ? '충전 중' : '방전 중',
          color: _getLevelColor(batteryInfo.level),
          icon: batteryInfo.isCharging ? Icons.bolt : Icons.battery_std,
        );
        
      case DisplayInfoType.chargingCurrent:
        if (batteryInfo.isCharging) {
          final current = batteryInfo.chargingCurrent.abs();
          final speedType = _getChargingSpeedType(current);
          return DisplayInfo(
            title: '충전 속도',
            value: '${current}mA',
            subtitle: speedType.label,
            color: speedType.color,
            icon: speedType.icon,
          );
        } else {
          return DisplayInfo(
            title: '배터리',
            value: '${batteryInfo.level.toInt()}%',
            subtitle: '방전 중',
            color: _getLevelColor(batteryInfo.level),
            icon: Icons.battery_std,
          );
        }
        
      case DisplayInfoType.batteryTemp:
        return DisplayInfo(
          title: '배터리 온도',
          value: batteryInfo.formattedTemperature,
          subtitle: _getTemperatureStatus(batteryInfo.temperature),
          color: _getTemperatureColor(batteryInfo.temperature),
          icon: Icons.thermostat,
        );
    }
  }
  
  /// 설정에 따라 사용 가능한 정보 타입 목록 반환
  List<DisplayInfoType> _getAvailableInfoTypes(AppSettings? settings) {
    final List<DisplayInfoType> availableTypes = [];
    
    // 자동 순환이 꺼져 있으면 항상 배터리 퍼센트만 표시
    if (settings?.batteryDisplayCycleSpeed == BatteryDisplayCycleSpeed.off) {
      availableTypes.add(DisplayInfoType.batteryLevel);
      return availableTypes;
    }
    
    // 배터리 퍼센트 표시 설정 확인
    if (settings?.showBatteryPercentage != false) {
      availableTypes.add(DisplayInfoType.batteryLevel);
    }
    
    // 충전 전류 표시 설정 확인 (충전 중일 때만)
    if (settings?.showChargingCurrent != false && widget.batteryInfo?.isCharging == true) {
      availableTypes.add(DisplayInfoType.chargingCurrent);
    }
    
    // 배터리 온도 표시 설정 확인
    if (settings?.showBatteryTemperature != false) {
      availableTypes.add(DisplayInfoType.batteryTemp);
    }
    
    return availableTypes;
  }
  
  /// 충전 속도 타입 정보
  _ChargingSpeedType _getChargingSpeedType(int current) {
    if (current >= 2000) {
      return _ChargingSpeedType(
        label: '고속 충전',
        icon: Icons.flash_on,
        color: Colors.red[400]!,
      );
    } else if (current >= 1000) {
      return _ChargingSpeedType(
        label: '일반 충전',
        icon: Icons.battery_charging_full,
        color: Colors.blue[400]!,
      );
    } else {
      return _ChargingSpeedType(
        label: '저속 충전',
        icon: Icons.battery_6_bar,
        color: Colors.green[400]!,
      );
    }
  }
  
  /// 온도 상태 텍스트
  String _getTemperatureStatus(double temp) {
    if (temp < 30) return '냉각 상태';
    if (temp < 40) return '정상 온도';
    if (temp < 45) return '약간 높음';
    return '고온 주의';
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.batteryInfo?.level ?? 0;
    final isCharging = widget.batteryInfo?.isCharging ?? false;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 메인 영역: 게이지 + 상태
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                // 원형 게이지
                Expanded(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildCircularGauge(context, level),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 상태 정보
                Expanded(
                  flex: 1,
                  child: _buildStatusInfo(context, isCharging),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 2개 메트릭 (온도/전압)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    icon: '🌡️',
                    label: '온도',
                    value: widget.batteryInfo?.formattedTemperature ?? '--°C',
                    color: _getTemperatureColor(widget.batteryInfo?.temperature ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    icon: '⚡',
                    label: '전압',
                    value: widget.batteryInfo?.formattedVoltage ?? '--mV',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCircularGauge(BuildContext context, double level) {
    final isCharging = widget.batteryInfo?.isCharging ?? false;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // 배경 원
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: isCharging 
              ? _buildAnimatedChargingGauge(context, level)
              : CustomPaint(
                  size: const Size(200, 200),
                  painter: BatteryGaugePainter(
                    progress: level / 100,
                    strokeWidth: 12,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
        ),
        // 중앙 텍스트 (동적 표시) + 제스처 감지
        GestureDetector(
          onTap: () {
            final settings = widget.settingsService?.appSettings;
            if (settings?.enableTapToSwitch == true) {
              // 수동 탭은 자동 순환 일시정지 없이 작동
              _changeDisplayIndex(1);
            }
          },
          onHorizontalDragStart: (details) {
            final settings = widget.settingsService?.appSettings;
            if (settings?.enableSwipeToSwitch == true) {
              _swipeStartX = details.globalPosition.dx;
            }
          },
          onHorizontalDragEnd: (details) {
            final settings = widget.settingsService?.appSettings;
            if (settings?.enableSwipeToSwitch == true) {
              final swipeEndX = details.globalPosition.dx;
              final swipeDistance = swipeEndX - _swipeStartX;
              
              // 최소 스와이프 거리 (50px)
              if (swipeDistance.abs() > 50) {
                // 수동 스와이프는 자동 순환 일시정지 없이 작동
                if (swipeDistance > 0) {
                  // 오른쪽으로 스와이프 -> 이전 정보
                  _changeDisplayIndex(-1);
                } else {
                  // 왼쪽으로 스와이프 -> 다음 정보
                  _changeDisplayIndex(1);
                }
              }
            }
          },
          behavior: HitTestBehavior.opaque, // 전체 영역을 터치 가능하게
          child: AnimatedBuilder(
            animation: _cycleController,
            builder: (context, child) {
              final displayInfo = _getCurrentDisplayInfo();
              return Container(
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                color: Colors.transparent, // 투명하지만 hit test 가능
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.3, 0.0), // 오른쪽에서 시작 (일부만 슬라이드)
                            end: Offset.zero,
                          ).animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        displayInfo.value,
                        key: ValueKey(displayInfo.title),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: displayInfo.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.3, 0.0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        displayInfo.title,
                        key: ValueKey(displayInfo.title),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    if (displayInfo.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.3, 0.0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          displayInfo.subtitle,
                          key: ValueKey(displayInfo.subtitle),
                          style: TextStyle(
                            fontSize: 10,
                            color: displayInfo.color.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 충전 중일 때 애니메이션이 적용된 게이지
  Widget _buildAnimatedChargingGauge(BuildContext context, double level) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController]),
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulseController.value * 0.05), // 5% 크기 변화
          child: Transform.rotate(
            angle: _rotationController.value * 2 * math.pi,
              child: CustomPaint(
              size: const Size(200, 200),
              painter: BatteryGaugePainter(
                progress: level / 100,
                strokeWidth: 12,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatusInfo(BuildContext context, bool isCharging) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCharging 
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCharging 
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '상태',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isCharging ? Icons.bolt : Icons.battery_std,
                size: 20,
                color: isCharging ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  isCharging ? '충전 중' : '방전 중',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isCharging ? Colors.green : Colors.grey,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricCard(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(double level) {
    if (level > 50) return Colors.green;
    if (level > 20) return Colors.orange;
    return Colors.red;
  }
  
  Color _getTemperatureColor(double temp) {
    if (temp < 30) return Colors.blue;
    if (temp < 40) return Colors.green;
    if (temp < 45) return Colors.orange;
    return Colors.red;
  }
}

/// 배터리 게이지 페인터 (Pro 업그레이드 그라데이션 적용)
class BatteryGaugePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;

  BatteryGaugePainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 배경 원 그리기
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 진행률에 따른 호 그리기 (Pro 업그레이드 그라데이션 적용)
    final sweepAngle = 2 * math.pi * progress;
    final startAngle = -math.pi / 2; // 12시 방향부터 시작
    
    // 각도에 따라 색상을 계산하여 선형 그라데이션 효과 구현
    // 부드러운 그라데이션을 위해 충분한 세그먼트 수 사용
    final segments = (sweepAngle * 60 / (2 * math.pi)).ceil().clamp(1, 120);
    final segmentAngle = sweepAngle / segments;
    
    for (int i = 0; i < segments; i++) {
      final currentAngle = startAngle + (segmentAngle * i);
      final t = i / segments; // 0.0 ~ 1.0
      
      // Pro 업그레이드 그라데이션 색상 (초록 → 청록)
      final color = Color.lerp(
        Colors.green[400]!,
        Colors.teal[400]!,
        t,
      )!;
      
      final segmentPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        segmentAngle,
        false,
        segmentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(BatteryGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.strokeWidth != strokeWidth ||
           oldDelegate.backgroundColor != backgroundColor;
  }
}
