import 'package:flutter/material.dart';
import 'dart:async';
import '../../../models/models.dart';

/// 배터리 상태 애니메이션 관리 Mixin
/// 충전 애니메이션 및 자동 순환 기능을 제공
mixin BatteryStatusAnimationMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  // AnimationController들
  late AnimationController rotationController;
  late AnimationController pulseController;
  late AnimationController cycleController;
  
  // 자동 순환 관련
  bool isAutoCycleEnabled = true;
  Timer? pauseTimer;
  Timer? cycleTimer;
  
  // 콜백 함수들
  VoidCallback? onNextDisplayInfo;
  bool Function()? isChargingGetter;
  AppSettings? Function()? settingsGetter;
  
  /// Mixin 초기화
  /// [onNextDisplayInfo] 다음 정보로 전환할 때 호출될 콜백
  /// [isChargingGetter] 충전 상태를 확인하는 getter
  /// [settingsGetter] 설정을 가져오는 getter
  void initBatteryStatusAnimation({
    required VoidCallback onNextDisplayInfo,
    required bool Function() isChargingGetter,
    required AppSettings? Function() settingsGetter,
  }) {
    this.onNextDisplayInfo = onNextDisplayInfo;
    this.isChargingGetter = isChargingGetter;
    this.settingsGetter = settingsGetter;
    
    // 회전 애니메이션 컨트롤러 (3초 주기)
    rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    // 펄스 애니메이션 컨트롤러 (1.5초 주기)
    pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // 순환 표시 애니메이션 컨트롤러 (5초 주기)
    cycleController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    
    // 충전 중일 때만 애니메이션 시작
    if (isChargingGetter()) {
      rotationController.repeat();
      pulseController.repeat(reverse: true);
    }
    
    // 설정에 따라 자동 순환 시작
    updateAutoCycleFromSettings();
  }
  
  /// 충전 상태 변경 처리
  void handleChargingStateChanged(bool wasCharging, bool isCharging) {
    if (isCharging != wasCharging) {
      if (isCharging) {
        rotationController.repeat();
        pulseController.repeat(reverse: true);
        updateAutoCycleFromSettings();
      } else {
        rotationController.stop();
        pulseController.stop();
        stopAutoCycle();
      }
    }
  }
  
  /// 설정 변경 처리
  void handleSettingsChanged() {
    updateAutoCycleFromSettings();
  }
  
  /// 설정에 따라 자동 순환 업데이트
  void updateAutoCycleFromSettings() {
    final settings = settingsGetter?.call();
    if (settings == null) {
      // 설정이 없으면 기본값으로 자동 순환 시작
      if (isChargingGetter?.call() == true) {
        startAutoCycle();
      }
      return;
    }
    
    // 자동 순환이 꺼져있으면 중지
    if (settings.batteryDisplayCycleSpeed == BatteryDisplayCycleSpeed.off) {
      stopAutoCycle();
      isAutoCycleEnabled = false;
      return;
    }
    
    // 자동 순환 활성화
    isAutoCycleEnabled = true;
    
    // 충전 중일 때만 자동 순환 시작
    if (isChargingGetter?.call() == true) {
      startAutoCycle();
    }
  }
  
  /// 자동 순환 시작
  void startAutoCycle() {
    if (isAutoCycleEnabled) {
      cycleController.repeat();
      startCycleTimer();
    }
  }
  
  /// 순환 타이머 시작
  void startCycleTimer() {
    // 이전 타이머가 있으면 취소
    cycleTimer?.cancel();
    
    final settings = settingsGetter?.call();
    final durationSeconds = settings?.batteryDisplayCycleSpeed.durationSeconds ?? 5;
    
    cycleTimer = Timer.periodic(Duration(seconds: durationSeconds), (timer) {
      if (mounted && isChargingGetter?.call() == true) {
        onNextDisplayInfo?.call();
      } else {
        timer.cancel();
        cycleTimer = null;
      }
    });
  }
  
  /// 자동 순환 중지
  void stopAutoCycle() {
    cycleController.stop();
    pauseTimer?.cancel();
    cycleTimer?.cancel();
    cycleTimer = null;
  }
  
  /// 사용자 상호작용 후 일시정지
  void pauseAutoCycle() {
    stopAutoCycle();
    pauseTimer?.cancel();
    pauseTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && isChargingGetter?.call() == true) {
        startAutoCycle();
      }
    });
  }
  
  /// Mixin 정리
  void disposeBatteryStatusAnimation() {
    rotationController.dispose();
    pulseController.dispose();
    cycleController.dispose();
    pauseTimer?.cancel();
    cycleTimer?.cancel();
  }
}

