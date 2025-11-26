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
    // 배터리 충전 알림 채널
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

    // 개발자 모드 충전 테스트 알림 채널
    // BatteryStateReceiver에서 앱이 꺼진 상태에서도 사용할 수 있도록 미리 생성
    const AndroidNotificationChannel developerChargingChannel = AndroidNotificationChannel(
      'developer_charging_test_channel',  // channelId - BatteryStateReceiver와 동일
      '개발자 모드: 충전 테스트',  // channelName
      description: '개발자 모드 충전 감지 테스트용 알림',
      importance: Importance.high,
      playSound: false,  // 진동만 (BatteryStateReceiver와 동일)
      enableVibration: true,
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(developerChargingChannel);

    debugPrint('개발자 모드 충전 테스트 알림 채널 생성 완료');
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
    debugPrint('알림 탭됨: ${response.payload}, actionId: ${response.actionId}');
    
    // 액션 ID에 따른 처리
    if (response.actionId != null) {
      _handleNotificationAction(response.actionId!, response.payload);
    } else if (response.payload != null) {
      // 페이로드가 있으면 처리
      _handleNotificationPayload(response.payload!);
    }
  }
  
  // 알림 액션 처리 콜백 (BatteryNotificationManager에서 설정)
  static Function(String actionId, String? payload)? _actionHandler;
  
  /// 알림 액션 핸들러 설정
  static void setActionHandler(Function(String actionId, String? payload)? handler) {
    _actionHandler = handler;
  }
  
  /// 알림 액션 처리
  static void _handleNotificationAction(String actionId, String? payload) {
    try {
      debugPrint('알림 액션 처리: $actionId, payload: $payload');
      
      // 외부 핸들러가 있으면 호출
      final handler = _actionHandler;
      if (handler != null) {
        try {
          handler(actionId, payload);
        } catch (e, stackTrace) {
          debugPrint('알림 액션 핸들러 실행 중 에러 발생: $e');
          debugPrint('스택 트레이스: $stackTrace');
        }
        return;
      }
      
      // 기본 처리
      switch (actionId) {
        case 'dismiss':
          // 알림 끄기 - 이번 충전 세션 동안 알림 중지
          debugPrint('알림 끄기 액션 처리');
          break;
        case 'remind_5min':
          // 5분 후 다시 알림
          debugPrint('5분 후 다시 알림 액션 처리');
          break;
        case 'open_app':
          // 앱 열기 - 기본 동작 (이미 구현됨)
          debugPrint('앱 열기 액션 처리');
          break;
        default:
          debugPrint('알 수 없는 액션: $actionId');
      }
    } catch (e, stackTrace) {
      debugPrint('알림 액션 처리 중 에러 발생: $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
  
  /// 알림 페이로드 처리
  static void _handleNotificationPayload(String payload) {
    debugPrint('알림 페이로드 처리: $payload');
    // 필요시 페이로드 기반 처리 로직 추가
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

  /// 과충전 경고 알림 표시
  /// 
  /// [minutes]: 100% 도달 후 경과 시간 (분)
  /// [level]: 알림 단계 (1: 1차, 2: 2차, 3: 3차)
  /// [message]: 알림 메시지
  /// [chargingSpeed]: 충전 속도 타입 ('ultra_fast', 'fast', 'normal')
  /// [temperature]: 배터리 온도 (선택적)
  Future<void> showOverchargeWarningNotification({
    required int minutes,
    required int level,
    required String message,
    String? chargingSpeed,
    double? temperature,
  }) async {
    try {
      if (!_isInitialized) {
        debugPrint('알림 서비스가 초기화되지 않았습니다. 초기화 시도...');
        await initialize();
      }

      // 입력값 검증
      if (minutes < 0) {
        debugPrint('경과 시간이 음수입니다: $minutes');
        return;
      }
      
      if (level < 1 || level > 3) {
        debugPrint('알림 단계가 유효하지 않습니다: $level');
        return;
      }

      // 알림 단계에 따라 중요도 조정
      final importance = level >= 3 
          ? Importance.max 
          : Importance.high;
      
      final priority = level >= 3 
          ? Priority.max 
          : Priority.high;

      // 상황별 맞춤 메시지 생성
      String enhancedMessage = _buildEnhancedMessage(
        message: message,
        minutes: minutes,
        level: level,
        chargingSpeed: chargingSpeed,
        temperature: temperature,
      );

      // 알림 액션 버튼 정의
      final actions = <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'dismiss',
          '알림 끄기',
          showsUserInterface: false,
        ),
        const AndroidNotificationAction(
          'remind_5min',
          '5분 후 다시',
          showsUserInterface: false,
        ),
      ];

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'battery_charging_channel',
        '배터리 충전 알림',
        channelDescription: '배터리 충전 상태에 대한 알림을 받습니다.',
        importance: importance,
        priority: priority,
        showWhen: true,
        enableVibration: true,
        playSound: level >= 2, // 2차 이상 알림만 소리 재생
        actions: actions,
        styleInformation: BigTextStyleInformation(
          enhancedMessage,
          contentTitle: level >= 3 
              ? '⚠️ 과충전 위험'
              : level >= 2 
                  ? '⚠️ 과충전 주의'
                  : '충전 완료',
        ),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final title = level >= 3 
          ? '⚠️ 과충전 위험'
          : level >= 2 
              ? '⚠️ 과충전 주의'
              : '충전 완료';

      // 알림 ID: 3000 + level (과충전 알림용)
      final notificationId = 3000 + level;
      
      // 페이로드에 정보 포함
      final payload = 'overcharge|$level|$minutes|${chargingSpeed ?? 'unknown'}|${temperature ?? -1}';

      await _notifications.show(
        notificationId,
        title,
        enhancedMessage,
        notificationDetails,
        payload: payload,
      );

      debugPrint('과충전 경고 알림 표시됨: $title - $enhancedMessage (경과: ${minutes}분)');
    } catch (e, stackTrace) {
      debugPrint('과충전 경고 알림 표시 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
  
  /// 상황별 맞춤 메시지 생성
  String _buildEnhancedMessage({
    required String message,
    required int minutes,
    required int level,
    String? chargingSpeed,
    double? temperature,
  }) {
    try {
      final buffer = StringBuffer(message);
      
      // 온도 정보 추가
      if (temperature != null && temperature >= 40.0) {
        buffer.write('\n\n🌡️ 배터리 온도: ${temperature.toStringAsFixed(1)}°C');
        buffer.write('\n온도가 높아 즉시 분리 권장합니다.');
      }
      
      // 충전 속도 정보 추가
      if (chargingSpeed != null) {
        final speedText = _getChargingSpeedText(chargingSpeed);
        buffer.write('\n⚡ $speedText');
      }
      
      // 경과 시간 정보 추가
      buffer.write('\n⏱️ 100% 도달 후 ${minutes}분 경과');
      
      return buffer.toString();
    } catch (e) {
      debugPrint('메시지 생성 중 에러 발생: $e');
      return message; // 에러 발생 시 기본 메시지 반환
    }
  }
  
  /// 충전 속도 텍스트 가져오기
  String _getChargingSpeedText(String chargingSpeed) {
    switch (chargingSpeed) {
      case 'ultra_fast':
        return '초고속 충전';
      case 'fast':
        return '고속 충전';
      case 'normal':
        return '일반 충전';
      default:
        return '충전';
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

