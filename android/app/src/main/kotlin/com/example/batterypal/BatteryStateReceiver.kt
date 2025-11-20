package com.example.batterypal

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.os.Build
import android.os.BatteryManager
import android.util.Log
// WorkManager 제거 - 이벤트 기반으로만 작동하므로 주기적 작업 불필요

/// 배터리 상태 변화를 감지하는 독립적인 BroadcastReceiver
/// 앱이 백그라운드에 있거나 화면이 꺼진 상태에서도 작동
/// AndroidManifest에 정적으로 등록되어 앱이 완전히 종료되어도 작동
class BatteryStateReceiver : BroadcastReceiver() {
    
    companion object {
        // WorkManager 관련 상수 제거 - 이벤트 기반으로만 작동
    }
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("BatteryPal", "BatteryStateReceiver: onReceive 호출됨 - action: ${intent.action}")
        when (intent.action) {
            Intent.ACTION_POWER_CONNECTED -> {
                Log.d("BatteryPal", "BatteryStateReceiver: ACTION_POWER_CONNECTED 감지")
                handlePowerConnected(context)
            }
            Intent.ACTION_POWER_DISCONNECTED -> {
                Log.d("BatteryPal", "BatteryStateReceiver: ACTION_POWER_DISCONNECTED 감지")
                handlePowerDisconnected(context)
            }
            Intent.ACTION_BATTERY_CHANGED -> {
                handleBatteryChanged(context, intent)
            }
        }
    }
    
    /// 충전기 연결 처리
    private fun handlePowerConnected(context: Context) {
        try {
            Log.d("BatteryPal", "handlePowerConnected 시작")
            val now = System.currentTimeMillis()
            val batteryStatePrefs = context.getSharedPreferences("battery_state", Context.MODE_PRIVATE)
            
            // 충전 시작 시간 저장
            batteryStatePrefs.edit()
                .putLong("charging_session_start_time", now)
                .putBoolean("is_charging_active", true)
                .putLong("last_charging_event_time", now) // 진단용: 마지막 충전 이벤트 시간
                .putString("last_charging_event_type", "connected") // 진단용: 마지막 이벤트 타입
                .apply()
            
            Log.d("BatteryPal", "BatteryStateReceiver: 충전기 연결 감지 - 시작 시간: $now")
            
            // 배터리 정보 가져오기 (충전 시작 시점의 배터리 레벨 저장)
            var batteryPercent = -1.0
            var chargingType = "Unknown"
            
            val batteryIntent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            batteryIntent?.let {
                val level = it.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                val scale = it.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                batteryPercent = if (level != -1 && scale != -1 && scale > 0) {
                    (level * 100.0) / scale
                } else -1.0
                
                val plugged = it.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1)
                chargingType = when (plugged) {
                    BatteryManager.BATTERY_PLUGGED_AC -> "AC"
                    BatteryManager.BATTERY_PLUGGED_USB -> "USB"
                    BatteryManager.BATTERY_PLUGGED_WIRELESS -> "Wireless"
                    else -> "Unknown"
                }
                
                // 충전 시작 정보 저장
                batteryStatePrefs.edit()
                    .putFloat("charging_start_battery_level", batteryPercent.toFloat())
                    .putString("charging_type", chargingType)
                    .apply()
                
                Log.d("BatteryPal", "BatteryStateReceiver: 충전 시작 정보 저장 - 레벨: $batteryPercent%, 타입: $chargingType")
            }
            
            // 개발자 모드 충전 테스트 알림 표시
            val isDeveloperModeEnabled = isDeveloperModeChargingTestEnabled(context)
            Log.d("BatteryPal", "BatteryStateReceiver: 개발자 모드 활성화 여부: $isDeveloperModeEnabled")
            
            // Foreground Service 시작 (충전 모니터링)
            // 개발자 모드 알림도 Foreground Service를 통해 표시 (앱이 꺼진 상태에서도 작동)
            if (isDeveloperModeEnabled) {
                val levelText = if (batteryPercent >= 0) {
                    "충전이 시작되었습니다. (배터리: ${batteryPercent.toInt()}%, 타입: $chargingType)"
                } else {
                    "충전이 시작되었습니다. (타입: $chargingType)"
                }
                Log.d("BatteryPal", "BatteryStateReceiver: 개발자 모드 알림을 Foreground Service를 통해 표시 - $levelText")
                ChargingForegroundService.startService(
                    context,
                    showDeveloperNotification = true,
                    title = "충전 시작",
                    message = levelText
                )
            } else {
                Log.d("BatteryPal", "BatteryStateReceiver: 개발자 모드가 비활성화되어 알림을 표시하지 않음")
                ChargingForegroundService.startService(context)
            }
            
        } catch (e: Exception) {
            Log.e("BatteryPal", "BatteryStateReceiver: 충전기 연결 처리 오류", e)
        }
    }
    
    /// 충전기 분리 처리
    private fun handlePowerDisconnected(context: Context) {
        try {
            Log.d("BatteryPal", "handlePowerDisconnected 시작")
            val now = System.currentTimeMillis()
            val batteryStatePrefs = context.getSharedPreferences("battery_state", Context.MODE_PRIVATE)
            
            val startTime = batteryStatePrefs.getLong("charging_session_start_time", -1)
            
            if (startTime > 0) {
                // 충전 종료 시간 저장
                batteryStatePrefs.edit()
                    .putLong("charging_session_end_time", now)
                    .putBoolean("is_charging_active", false)
                    .apply()
                
                val duration = now - startTime
                Log.d("BatteryPal", "BatteryStateReceiver: 충전기 분리 감지 - 종료 시간: $now, 지속 시간: ${duration / 1000}초")
                
                // 배터리 정보 가져오기 (충전 종료 시점의 배터리 레벨 저장)
                val batteryIntent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
                batteryIntent?.let {
                    val level = it.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                    val scale = it.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                    val batteryPercent = if (level != -1 && scale != -1 && scale > 0) {
                        (level * 100.0) / scale
                    } else -1.0
                    
                    // 충전 종료 정보 저장
                    batteryStatePrefs.edit()
                        .putFloat("charging_end_battery_level", batteryPercent.toFloat())
                        .apply()
                    
                    Log.d("BatteryPal", "BatteryStateReceiver: 충전 종료 정보 저장 - 레벨: $batteryPercent%")
                }
            } else {
                // 시작 시간이 없으면 종료 시간만 저장
                batteryStatePrefs.edit()
                    .putLong("charging_session_end_time", now)
                    .putBoolean("is_charging_active", false)
                    .apply()
                
                Log.d("BatteryPal", "BatteryStateReceiver: 충전기 분리 감지 (시작 시간 없음) - 종료 시간: $now")
            }
            
            // 마지막 충전 이벤트 시간 저장 (진단용)
            batteryStatePrefs.edit()
                .putLong("last_charging_event_time", now)
                .putString("last_charging_event_type", "disconnected")
                .apply()
            
            // 개발자 모드 충전 테스트 알림 표시
            val isDeveloperModeEnabled = isDeveloperModeChargingTestEnabled(context)
            Log.d("BatteryPal", "BatteryStateReceiver: 충전기 분리 - 개발자 모드 활성화 여부: $isDeveloperModeEnabled")
            
            // Foreground Service를 통해 알림 표시 후 종료
            if (isDeveloperModeEnabled) {
                val batteryIntent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
                val batteryLevel = batteryIntent?.let {
                    val level = it.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                    val scale = it.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                    if (level != -1 && scale != -1 && scale > 0) {
                        (level * 100.0) / scale
                    } else -1.0
                } ?: -1.0
                
                val levelText = if (batteryLevel >= 0) {
                    "충전이 종료되었습니다. (배터리: ${batteryLevel.toInt()}%)"
                } else {
                    "충전이 종료되었습니다."
                }
                
                Log.d("BatteryPal", "BatteryStateReceiver: 개발자 모드 알림을 Foreground Service를 통해 표시 (분리) - $levelText")
                // Foreground Service에 알림 표시 요청 후 종료
                ChargingForegroundService.showNotificationAndStop(
                    context,
                    title = "충전 종료",
                    message = levelText
                )
            } else {
                Log.d("BatteryPal", "BatteryStateReceiver: 충전기 분리 - 개발자 모드가 비활성화되어 알림을 표시하지 않음")
                // Foreground Service 종료 (충전 종료)
                ChargingForegroundService.stopService(context)
            }
            
        } catch (e: Exception) {
            Log.e("BatteryPal", "BatteryStateReceiver: 충전기 분리 처리 오류", e)
        }
    }
    
    /// 배터리 상태 변화 처리 (기존 로직)
    private fun handleBatteryChanged(context: Context, intent: Intent) {
        try {
            val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
            val plugged = intent.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1)
            val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
            
            val batteryPercent = if (level != -1 && scale != -1 && scale > 0) {
                (level * 100.0) / scale
            } else -1.0
            
            val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING || 
                            status == BatteryManager.BATTERY_STATUS_FULL ||
                            plugged != 0
            
            // 충전 타입 구분
            val chargingType = when (plugged) {
                BatteryManager.BATTERY_PLUGGED_AC -> "AC"
                BatteryManager.BATTERY_PLUGGED_USB -> "USB"
                BatteryManager.BATTERY_PLUGGED_WIRELESS -> "Wireless"
                else -> "Unknown"
            }
            
            Log.d("BatteryPal", "BatteryStateReceiver: 배터리 상태 변화 - ${batteryPercent}%, 충전중: $isCharging, 타입: $chargingType")
            
            // SharedPreferences를 통해 마지막 배터리 레벨 확인
            val batteryStatePrefs = context.getSharedPreferences("battery_state", Context.MODE_PRIVATE)
            val lastBatteryLevel = batteryStatePrefs.getFloat("last_battery_level", -1f)
            val hasNotified = batteryStatePrefs.getBoolean("has_notified_charging_complete", false)
            
            // Flutter SharedPreferences에서 설정 읽기
            val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            
            // 충전 완료 알림 체크 (100% 도달 시)
            if (isCharging && 
                batteryPercent >= 100.0 && 
                lastBatteryLevel < 100.0 && 
                !hasNotified) {
                
                // 충전 완료 알림 설정 확인 (Flutter SharedPreferences에서 읽기)
                // Flutter SharedPreferences는 키를 그대로 저장하므로 접두사 없이 읽기
                val chargingCompleteEnabled = flutterPrefs.getBoolean("chargingCompleteNotificationEnabled", false)
                val notifyOnFastCharging = flutterPrefs.getBoolean("chargingCompleteNotifyOnFastCharging", true)
                val notifyOnNormalCharging = flutterPrefs.getBoolean("chargingCompleteNotifyOnNormalCharging", true)
                
                Log.d("BatteryPal", "BatteryStateReceiver: 알림 설정 확인 - enabled: $chargingCompleteEnabled, fast: $notifyOnFastCharging, normal: $notifyOnNormalCharging")
                
                if (chargingCompleteEnabled) {
                    // 충전 타입 필터 확인
                    val shouldNotify = when {
                        notifyOnFastCharging && notifyOnNormalCharging -> true
                        notifyOnFastCharging && chargingType == "AC" -> true
                        notifyOnNormalCharging && (chargingType == "USB" || chargingType == "Wireless") -> true
                        else -> false
                    }
                    
                    Log.d("BatteryPal", "BatteryStateReceiver: 알림 필요 여부: $shouldNotify")
                    
                    if (shouldNotify) {
                        // 알림 표시
                        showChargingCompleteNotification(context)
                        
                        // 알림 플래그 설정
                        batteryStatePrefs.edit().putBoolean("has_notified_charging_complete", true).apply()
                        Log.d("BatteryPal", "BatteryStateReceiver: 충전 완료 알림 표시됨")
                    }
                }
            }
            
            // 배터리 레벨이 100% 미만으로 떨어지면 알림 플래그 리셋
            if (batteryPercent < 100.0) {
                batteryStatePrefs.edit().putBoolean("has_notified_charging_complete", false).apply()
            }
            
            // 현재 상태 저장
            batteryStatePrefs.edit()
                .putFloat("last_battery_level", batteryPercent.toFloat())
                .putBoolean("last_is_charging", isCharging)
                .apply()
            
        } catch (e: Exception) {
            Log.e("BatteryPal", "BatteryStateReceiver: 오류 발생", e)
        }
    }
    
    /// 충전 완료 알림 표시
    private fun showChargingCompleteNotification(context: Context) {
        try {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
            
            // Android 8.0 이상에서는 알림 채널 필요
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                val channelId = "battery_charging_channel"
                val channelName = "배터리 충전 알림"
                val channel = android.app.NotificationChannel(
                    channelId,
                    channelName,
                    android.app.NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "배터리 충전 상태에 대한 알림을 받습니다."
                    enableVibration(true)
                    enableLights(true)
                }
                notificationManager.createNotificationChannel(channel)
                
                val notification = android.app.Notification.Builder(context, channelId)
                    .setContentTitle("충전 완료")
                    .setContentText("배터리가 100% 충전되었습니다.")
                    .setSmallIcon(android.R.drawable.ic_dialog_info)
                    .setDefaults(android.app.Notification.DEFAULT_ALL)
                    .setAutoCancel(true)
                    .build()
                
                notificationManager.notify(1, notification)
                Log.d("BatteryPal", "BatteryStateReceiver: 네이티브 알림 표시됨")
            } else {
                // Android 8.0 미만
                @Suppress("DEPRECATION")
                val notification = android.app.Notification.Builder(context)
                    .setContentTitle("충전 완료")
                    .setContentText("배터리가 100% 충전되었습니다.")
                    .setSmallIcon(android.R.drawable.ic_dialog_info)
                    .setPriority(android.app.Notification.PRIORITY_HIGH)
                    .setDefaults(android.app.Notification.DEFAULT_ALL)
                    .setAutoCancel(true)
                    .build()
                
                notificationManager.notify(1, notification)
                Log.d("BatteryPal", "BatteryStateReceiver: 네이티브 알림 표시됨 (구버전)")
            }
        } catch (e: Exception) {
            Log.e("BatteryPal", "BatteryStateReceiver: 알림 표시 실패", e)
        }
    }
    
    // WorkManager 주기적 작업 제거됨
    // 이벤트 기반으로만 작동하므로 주기적 폴링 불필요
    // 충전 상태 변화(ON/OFF)만 감지하여 Foreground Service 시작/종료
    
    /// 개발자 모드 충전 테스트 활성화 여부 확인
    /// Flutter SharedPreferences에서 설정을 읽어옵니다
    private fun isDeveloperModeChargingTestEnabled(context: Context): Boolean {
        return try {
            val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            
            // Flutter SharedPreferences는 "flutter." 접두사를 사용합니다
            val key = "flutter.developerModeChargingTestEnabled"
            
            // 키 존재 여부 확인
            val isEnabled = if (flutterPrefs.contains(key)) {
                flutterPrefs.getBoolean(key, false)
            } else {
                // 대체 키 시도 (이전 형식 호환성)
                flutterPrefs.getBoolean("developerModeChargingTestEnabled", false)
            }
            
            Log.d("BatteryPal", "BatteryStateReceiver: 개발자 모드 충전 테스트 활성화 여부: $isEnabled (키: $key)")
            
            isEnabled
        } catch (e: Exception) {
            Log.e("BatteryPal", "BatteryStateReceiver: 개발자 모드 설정 읽기 실패", e)
            false
        }
    }
    
    /// 개발자 모드 충전 테스트 알림 표시
    /// 앱이 꺼져있어도 충전 상태 변화를 감지했음을 알리는 알림
    private fun showDeveloperChargingTestNotification(
        context: Context, 
        title: String, 
        message: String
    ) {
        try {
            Log.d("BatteryPal", "showDeveloperChargingTestNotification 호출: title=$title, message=$message")
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            if (notificationManager == null) {
                Log.e("BatteryPal", "NotificationManager를 가져올 수 없습니다")
                return
            }
            
            // Android 13+ (API 33+) 알림 권한 확인
            // 앱이 꺼진 상태에서도 알림을 표시하려면 알림 권한이 필요합니다
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                if (!notificationManager.areNotificationsEnabled()) {
                    Log.w("BatteryPal", "알림 권한이 없어서 알림을 표시할 수 없습니다. 앱 설정에서 알림 권한을 허용해주세요.")
                    return
                }
                Log.d("BatteryPal", "알림 권한 확인 완료: 허용됨")
            }
            
            // 앱 아이콘 리소스 ID 가져오기
            val packageName = context.packageName
            val iconResId = context.resources.getIdentifier("ic_launcher", "mipmap", packageName)
            val smallIcon = if (iconResId != 0) {
                Log.d("BatteryPal", "앱 아이콘 사용: $iconResId")
                iconResId
            } else {
                Log.w("BatteryPal", "앱 아이콘을 찾을 수 없어 시스템 아이콘 사용")
                android.R.drawable.ic_dialog_info
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channelId = "developer_charging_test_channel"
                
                // 채널 존재 여부 확인 (NotificationService에서 미리 생성됨)
                val channel = notificationManager.getNotificationChannel(channelId)
                if (channel == null) {
                    // 채널이 없으면 생성 (백업용 - 앱이 처음 실행되거나 채널이 삭제된 경우)
                    val channelName = "개발자 모드: 충전 테스트"
                    val newChannel = NotificationChannel(
                        channelId,
                        channelName,
                        NotificationManager.IMPORTANCE_HIGH
                    ).apply {
                        description = "개발자 모드 충전 감지 테스트용 알림"
                        enableVibration(true)
                        enableLights(true)
                        setShowBadge(true)
                        setSound(null, null) // 소리 없음 (진동만)
                    }
                    notificationManager.createNotificationChannel(newChannel)
                    Log.d("BatteryPal", "개발자 모드 알림 채널 생성 (백업): $channelId")
                } else {
                    Log.d("BatteryPal", "개발자 모드 알림 채널 확인 완료: $channelId, importance=${channel.importance}")
                }
                
                // 메인 액티비티로 이동하는 PendingIntent
                val mainIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    mainIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                
                val notification = Notification.Builder(context, channelId)
                    .setContentTitle(title)
                    .setContentText(message)
                    .setSmallIcon(smallIcon)
                    .setDefaults(Notification.DEFAULT_VIBRATE) // 진동만
                    .setAutoCancel(true)
                    .setContentIntent(pendingIntent)
                    .setStyle(Notification.BigTextStyle().bigText(message))
                    .setPriority(Notification.PRIORITY_HIGH) // 높은 우선순위
                    .setCategory(Notification.CATEGORY_STATUS) // 상태 알림 카테고리
                    .setVisibility(Notification.VISIBILITY_PUBLIC) // 공개 알림
                    .build()
                
                // 고유한 알림 ID 사용 (타임스탬프 기반)
                val notificationId = (System.currentTimeMillis() % Int.MAX_VALUE).toInt()
                
                // 알림 표시 전 로그
                Log.d("BatteryPal", "개발자 모드 충전 테스트 알림 표시 시도: channelId=$channelId, notificationId=$notificationId")
                Log.d("BatteryPal", "개발자 모드 충전 테스트 알림 내용: title=$title, message=$message, smallIcon=$smallIcon")
                
                // 알림 표시
                notificationManager.notify(notificationId, notification)
                
                // 알림 표시 후 확인
                val notificationChannel = notificationManager.getNotificationChannel(channelId)
                Log.d("BatteryPal", "개발자 모드 충전 테스트 알림 표시 완료")
                Log.d("BatteryPal", "  - channelId: $channelId")
                Log.d("BatteryPal", "  - channelImportance: ${notificationChannel?.importance}")
                Log.d("BatteryPal", "  - channelSound: ${notificationChannel?.sound}")
                Log.d("BatteryPal", "  - channelVibration: ${notificationChannel?.shouldVibrate()}")
                Log.d("BatteryPal", "  - notificationId: $notificationId")
                Log.d("BatteryPal", "개발자 모드 충전 테스트 알림 표시: $title - $message")
            } else {
                // Android 8.0 미만
                @Suppress("DEPRECATION")
                val mainIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    mainIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT
                )
                
                // 앱 아이콘 리소스 ID 가져오기
                val packageName = context.packageName
                val iconResId = context.resources.getIdentifier("ic_launcher", "mipmap", packageName)
                val smallIcon = if (iconResId != 0) iconResId else android.R.drawable.ic_dialog_info
                
                @Suppress("DEPRECATION")
                val notification = Notification.Builder(context)
                    .setContentTitle(title)
                    .setContentText(message)
                    .setSmallIcon(smallIcon)
                    .setPriority(Notification.PRIORITY_HIGH)
                    .setDefaults(Notification.DEFAULT_VIBRATE)
                    .setAutoCancel(true)
                    .setContentIntent(pendingIntent)
                    .setStyle(Notification.BigTextStyle().bigText(message))
                    .build()
                
                val notificationId = (System.currentTimeMillis() % Int.MAX_VALUE).toInt()
                notificationManager.notify(notificationId, notification)
                
                Log.d("BatteryPal", "개발자 모드 충전 테스트 알림 표시 (구버전): $title - $message, notificationId=$notificationId")
            }
        } catch (e: Exception) {
            Log.e("BatteryPal", "개발자 모드 알림 표시 실패", e)
        }
    }
}

