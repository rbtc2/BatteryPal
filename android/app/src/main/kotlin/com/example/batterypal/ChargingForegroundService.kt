package com.example.batterypal

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.BatteryManager
import android.os.Build
import android.os.IBinder
import android.util.Log

/// 충전 상태 변화만 감지하는 Foreground Service
/// 주기적 폴링을 사용하지 않고, BroadcastReceiver의 이벤트만 사용
class ChargingForegroundService : Service() {
    
    companion object {
        private const val TAG = "ChargingForegroundService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "charging_foreground_service_channel"
        private const val CHANNEL_NAME = "충전 모니터링"
        
        // 개발자 모드 알림용 상수
        private const val EXTRA_SHOW_DEVELOPER_NOTIFICATION = "show_developer_notification"
        private const val EXTRA_NOTIFICATION_TITLE = "notification_title"
        private const val EXTRA_NOTIFICATION_MESSAGE = "notification_message"
        private const val EXTRA_STOP_AFTER_NOTIFICATION = "stop_after_notification"
        private const val DEVELOPER_NOTIFICATION_ID = 2000
        
        /// Foreground Service 시작
        fun startService(context: Context, showDeveloperNotification: Boolean = false, title: String? = null, message: String? = null) {
            val intent = Intent(context, ChargingForegroundService::class.java).apply {
                putExtra(EXTRA_SHOW_DEVELOPER_NOTIFICATION, showDeveloperNotification)
                if (title != null) putExtra(EXTRA_NOTIFICATION_TITLE, title)
                if (message != null) putExtra(EXTRA_NOTIFICATION_MESSAGE, message)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            Log.d(TAG, "Foreground Service 시작 요청 (개발자 알림: $showDeveloperNotification)")
        }
        
        /// Foreground Service 종료
        fun stopService(context: Context) {
            val intent = Intent(context, ChargingForegroundService::class.java)
            context.stopService(intent)
            Log.d(TAG, "Foreground Service 종료 요청")
        }
        
        /// 알림 표시 후 Foreground Service 종료
        fun showNotificationAndStop(context: Context, title: String, message: String) {
            val intent = Intent(context, ChargingForegroundService::class.java).apply {
                putExtra(EXTRA_SHOW_DEVELOPER_NOTIFICATION, true)
                putExtra(EXTRA_NOTIFICATION_TITLE, title)
                putExtra(EXTRA_NOTIFICATION_MESSAGE, message)
                putExtra("stop_after_notification", true) // 알림 표시 후 종료 플래그
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            Log.d(TAG, "알림 표시 후 종료 요청: $title - $message")
        }
    }
    
    private var batteryReceiver: android.content.BroadcastReceiver? = null
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Foreground Service 생성")
        
        // 알림 채널 생성
        createNotificationChannel()
        
        // Foreground Service로 시작 (알림 필수)
        startForeground(NOTIFICATION_ID, createNotification())
        
        // 배터리 상태 변화 리스너는 등록하지 않음
        // BatteryStateReceiver에서 이미 감지하고 있으므로 여기서는 추가 감지 불필요
        // 이 서비스는 단순히 백그라운드에서 실행 중임을 표시하는 역할만 함
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Foreground Service 시작")
        
        // 알림 업데이트
        val notification = createNotification()
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
        
        // 개발자 모드 알림 표시 (Intent에서 전달된 경우)
        intent?.let {
            val showDeveloperNotification = it.getBooleanExtra(EXTRA_SHOW_DEVELOPER_NOTIFICATION, false)
            val stopAfterNotification = it.getBooleanExtra(EXTRA_STOP_AFTER_NOTIFICATION, false)
            
            if (showDeveloperNotification) {
                val title = it.getStringExtra(EXTRA_NOTIFICATION_TITLE) ?: "충전 알림"
                val message = it.getStringExtra(EXTRA_NOTIFICATION_MESSAGE) ?: "충전 상태가 변경되었습니다."
                showDeveloperChargingTestNotification(title, message)
                Log.d(TAG, "개발자 모드 알림 표시: $title - $message")
                
                // 알림 표시 후 종료 플래그가 있으면 서비스 종료
                if (stopAfterNotification) {
                    Log.d(TAG, "알림 표시 후 서비스 종료")
                    stopSelf()
                }
            }
        }
        
        // 서비스가 종료되어도 자동으로 재시작하지 않음
        // 충전 상태가 변경되면 BatteryStateReceiver에서 다시 시작할 것
        return START_NOT_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Foreground Service 종료")
        
        // 리스너 정리
        batteryReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (e: Exception) {
                Log.e(TAG, "리시버 해제 실패", e)
            }
        }
        batteryReceiver = null
    }
    
    /// 알림 채널 생성
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW // 낮은 중요도 (사용자 방해 최소화)
            ).apply {
                description = "배터리 충전 상태를 모니터링하고 있습니다."
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "알림 채널 생성 완료")
        }
    }
    
    /// 알림 생성
    private fun createNotification(): Notification {
        // 메인 액티비티로 이동하는 PendingIntent
        val mainIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            mainIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // 현재 충전 상태 확인
        val batteryIntent = registerReceiver(null, android.content.IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val batteryLevel = batteryIntent?.let {
            val level = it.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            val scale = it.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
            if (level != -1 && scale != -1 && scale > 0) {
                (level * 100) / scale
            } else -1
        } ?: -1
        
        val contentText = if (batteryLevel >= 0) {
            "배터리 $batteryLevel% - 충전 모니터링 중"
        } else {
            "충전 모니터링 중"
        }
        
        // 앱 아이콘 리소스 ID 가져오기
        val iconResId = resources.getIdentifier("ic_launcher", "mipmap", packageName)
        val smallIcon = if (iconResId != 0) iconResId else android.R.drawable.ic_dialog_info
        
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("BatteryPal")
                .setContentText(contentText)
                .setSmallIcon(smallIcon)
                .setContentIntent(pendingIntent)
                .setOngoing(true) // 사용자가 제거할 수 없도록
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("BatteryPal")
                .setContentText(contentText)
                .setSmallIcon(smallIcon)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .setPriority(Notification.PRIORITY_LOW)
                .build()
        }
    }
    
    // 배터리 레벨 업데이트 메서드 제거
    // 충전 상태 변화(ON/OFF)만 감지하므로 주기적 업데이트 불필요
    
    /// 개발자 모드 충전 테스트 알림 표시
    /// Foreground Service에서 알림을 표시하므로 앱이 꺼진 상태에서도 작동
    private fun showDeveloperChargingTestNotification(title: String, message: String) {
        try {
            Log.d(TAG, "showDeveloperChargingTestNotification 호출: title=$title, message=$message")
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            if (notificationManager == null) {
                Log.e(TAG, "NotificationManager를 가져올 수 없습니다")
                return
            }
            
            // Android 13+ (API 33+) 알림 권한 확인
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                if (!notificationManager.areNotificationsEnabled()) {
                    Log.w(TAG, "알림 권한이 없어서 알림을 표시할 수 없습니다.")
                    return
                }
                Log.d(TAG, "알림 권한 확인 완료: 허용됨")
            }
            
            // 개발자 모드 알림 채널 ID (BatteryStateReceiver와 동일)
            val channelId = "developer_charging_test_channel"
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // 채널 존재 여부 확인
                var channel = notificationManager.getNotificationChannel(channelId)
                if (channel == null) {
                    // 채널이 없으면 생성 (백업용)
                    val channelName = "개발자 모드: 충전 테스트"
                    channel = NotificationChannel(
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
                    notificationManager.createNotificationChannel(channel)
                    Log.d(TAG, "개발자 모드 알림 채널 생성 (백업): $channelId")
                }
                
                // 메인 액티비티로 이동하는 PendingIntent
                val mainIntent = Intent(this, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                }
                val pendingIntent = PendingIntent.getActivity(
                    this,
                    0,
                    mainIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                
                // 앱 아이콘 리소스 ID 가져오기
                val iconResId = resources.getIdentifier("ic_launcher", "mipmap", packageName)
                val smallIcon = if (iconResId != 0) iconResId else android.R.drawable.ic_dialog_info
                
                val notification = Notification.Builder(this, channelId)
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
                
                notificationManager.notify(DEVELOPER_NOTIFICATION_ID, notification)
                Log.d(TAG, "개발자 모드 충전 테스트 알림 표시 완료: $title - $message")
            } else {
                // Android 8.0 미만
                @Suppress("DEPRECATION")
                val mainIntent = Intent(this, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                }
                val pendingIntent = PendingIntent.getActivity(
                    this,
                    0,
                    mainIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT
                )
                
                val iconResId = resources.getIdentifier("ic_launcher", "mipmap", packageName)
                val smallIcon = if (iconResId != 0) iconResId else android.R.drawable.ic_dialog_info
                
                @Suppress("DEPRECATION")
                val notification = Notification.Builder(this)
                    .setContentTitle(title)
                    .setContentText(message)
                    .setSmallIcon(smallIcon)
                    .setPriority(Notification.PRIORITY_HIGH)
                    .setDefaults(Notification.DEFAULT_VIBRATE)
                    .setAutoCancel(true)
                    .setContentIntent(pendingIntent)
                    .setStyle(Notification.BigTextStyle().bigText(message))
                    .build()
                
                notificationManager.notify(DEVELOPER_NOTIFICATION_ID, notification)
                Log.d(TAG, "개발자 모드 충전 테스트 알림 표시 (구버전): $title - $message")
            }
        } catch (e: Exception) {
            Log.e(TAG, "개발자 모드 알림 표시 실패", e)
        }
    }
}

