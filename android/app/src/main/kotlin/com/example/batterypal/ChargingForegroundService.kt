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
        
        /// Foreground Service 시작
        fun startService(context: Context) {
            val intent = Intent(context, ChargingForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            Log.d(TAG, "Foreground Service 시작 요청")
        }
        
        /// Foreground Service 종료
        fun stopService(context: Context) {
            val intent = Intent(context, ChargingForegroundService::class.java)
            context.stopService(intent)
            Log.d(TAG, "Foreground Service 종료 요청")
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
}

