import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'permission_helper.dart';

/// 알림을 관리하는 서비스 클래스
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// 알림 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('알림 서비스가 이미 초기화되었습니다.');
      return;
    }

    try {
      // Android 초기화 설정
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS 초기화 설정
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Android 알림 채널 생성
      await _createNotificationChannel();

      // 권한 요청
      await _requestPermissions();

      _isInitialized = true;
      debugPrint('알림 서비스 초기화 완료');
    } catch (e) {
      debugPrint('알림 서비스 초기화 실패: $e');
      rethrow;
    }
  }

  /// Android 알림 채널 생성
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'battery_charging_channel',
      '배터리 충전 알림',
      description: '배터리 충전 상태에 대한 알림을 받습니다.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// 알림 권한 요청
  Future<void> _requestPermissions() async {
    // Android 13 이상에서만 권한 요청
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        debugPrint('알림 권한이 허용되었습니다.');
      } else {
        debugPrint('알림 권한이 거부되었습니다.');
      }
    }
  }

  /// 알림 탭 처리
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('알림 탭됨: ${response.payload}');
    // 필요시 알림 탭 시 처리 로직 추가
  }

  /// 충전 완료 알림 표시
  Future<void> showChargingCompleteNotification() async {
    if (!_isInitialized) {
      debugPrint('알림 서비스가 초기화되지 않았습니다.');
      await initialize();
    }

    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'battery_charging_channel',
        '배터리 충전 알림',
        channelDescription: '배터리 충전 상태에 대한 알림을 받습니다.',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        0, // 알림 ID (고유 ID)
        '충전 완료',
        '배터리가 100% 충전되었습니다.',
        notificationDetails,
      );

      debugPrint('충전 완료 알림 표시됨');
    } catch (e) {
      debugPrint('충전 완료 알림 표시 실패: $e');
    }
  }

  /// 충전 퍼센트 알림 표시
  Future<void> showChargingPercentNotification(int percent) async {
    if (!_isInitialized) {
      debugPrint('알림 서비스가 초기화되지 않았습니다.');
      await initialize();
    }

    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'battery_charging_channel',
        '배터리 충전 알림',
        channelDescription: '배터리 충전 상태에 대한 알림을 받습니다.',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 알림 ID는 퍼센트 기반으로 고유하게 설정 (1-1000은 충전 완료 알림용, 1001+는 퍼센트 알림용)
      final notificationId = 1000 + percent.toInt();

      await _notifications.show(
        notificationId,
        '충전 알림',
        '배터리가 $percent% 충전되었습니다.',
        notificationDetails,
      );

      debugPrint('충전 퍼센트 알림 표시됨: $percent%');
    } catch (e) {
      debugPrint('충전 퍼센트 알림 표시 실패: $e');
    }
  }

  /// 충전 시작 알림 표시 (개발자 모드용)
  Future<void> showChargingStartNotification({String? chargingType}) async {
    if (!_isInitialized) {
      debugPrint('알림 서비스가 초기화되지 않았습니다.');
      await initialize();
    }

    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'battery_charging_channel',
        '배터리 충전 알림',
        channelDescription: '배터리 충전 상태에 대한 알림을 받습니다.',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final message = chargingType != null 
          ? '충전이 시작되었습니다. (타입: $chargingType)'
          : '충전이 시작되었습니다.';

      // 알림 ID: 2000 (충전 시작 알림용)
      await _notifications.show(
        2000,
        '충전 시작',
        message,
        notificationDetails,
      );

      debugPrint('충전 시작 알림 표시됨: $message');
    } catch (e) {
      debugPrint('충전 시작 알림 표시 실패: $e');
    }
  }

  /// 충전 종료 알림 표시 (개발자 모드용)
  Future<void> showChargingEndNotification({double? batteryLevel}) async {
    if (!_isInitialized) {
      debugPrint('알림 서비스가 초기화되지 않았습니다.');
      await initialize();
    }

    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'battery_charging_channel',
        '배터리 충전 알림',
        channelDescription: '배터리 충전 상태에 대한 알림을 받습니다.',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final message = batteryLevel != null 
          ? '충전이 종료되었습니다. (배터리: ${batteryLevel.toInt()}%)'
          : '충전이 종료되었습니다.';

      // 알림 ID: 2001 (충전 종료 알림용)
      await _notifications.show(
        2001,
        '충전 종료',
        message,
        notificationDetails,
      );

      debugPrint('충전 종료 알림 표시됨: $message');
    } catch (e) {
      debugPrint('충전 종료 알림 표시 실패: $e');
    }
  }

  /// 알림 권한 확인
  Future<bool> checkPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// 알림 권한 요청 (외부에서 호출 가능)
  /// 
  /// [context] BuildContext (다이얼로그 표시용, null이면 기본 요청)
  /// [showDialog] 다이얼로그를 표시할지 여부 (기본값: false)
  /// 
  /// Returns 권한이 허용되었는지 여부
  Future<bool> requestPermission({
    BuildContext? context,
    bool showDialog = false,
  }) async {
    // context가 있고 다이얼로그를 표시하려면 PermissionHelper 사용
    if (context != null && showDialog) {
      return await PermissionHelper.requestNotificationPermission(context);
    }
    
    // 기본 권한 요청
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('모든 알림 취소됨');
  }
}

