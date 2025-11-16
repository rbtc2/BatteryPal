package com.example.batterypal

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.os.BatteryManager
import android.util.Log
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkRequest
import java.util.concurrent.TimeUnit

/// 배터리 상태 변화를 감지하는 독립적인 BroadcastReceiver
/// 앱이 백그라운드에 있거나 화면이 꺼진 상태에서도 작동
/// AndroidManifest에 정적으로 등록되어 앱이 완전히 종료되어도 작동
class BatteryStateReceiver : BroadcastReceiver() {
    
    companion object {
        private const val WORK_NAME = "charging_data_collection"
        private const val WORK_INTERVAL_MINUTES = 15L // PeriodicWorkRequest의 최소 간격 (15분)
        private const val ONE_TIME_WORK_DELAY_SECONDS = 10L // OneTimeWorkRequest 지연 시간 (10초)
    }
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_POWER_CONNECTED -> {
                handlePowerConnected(context)
            }
            Intent.ACTION_POWER_DISCONNECTED -> {
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
            val now = System.currentTimeMillis()
            val batteryStatePrefs = context.getSharedPreferences("battery_state", Context.MODE_PRIVATE)
            
            // 충전 시작 시간 저장
            batteryStatePrefs.edit()
                .putLong("charging_session_start_time", now)
                .putBoolean("is_charging_active", true)
                .apply()
            
            Log.d("BatteryPal", "BatteryStateReceiver: 충전기 연결 감지 - 시작 시간: $now")
            
            // 배터리 정보 가져오기 (충전 시작 시점의 배터리 레벨 저장)
            val batteryIntent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            batteryIntent?.let {
                val level = it.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                val scale = it.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                val batteryPercent = if (level != -1 && scale != -1 && scale > 0) {
                    (level * 100.0) / scale
                } else -1.0
                
                val plugged = it.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1)
                val chargingType = when (plugged) {
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
            
            // WorkManager 주기적 작업 예약 (충전 데이터 수집)
            scheduleChargingDataCollection(context)
            
        } catch (e: Exception) {
            Log.e("BatteryPal", "BatteryStateReceiver: 충전기 연결 처리 오류", e)
        }
    }
    
    /// 충전기 분리 처리
    private fun handlePowerDisconnected(context: Context) {
        try {
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
            
            // WorkManager 주기적 작업 취소 (충전 종료)
            cancelChargingDataCollection(context)
            
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
                    .setPriority(android.app.Notification.PRIORITY_HIGH)
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
    
    /// WorkManager 주기적 작업 예약 (충전 데이터 수집)
    private fun scheduleChargingDataCollection(context: Context) {
        try {
            val workManager = WorkManager.getInstance(context)
            
            // Phase 3: 제약 조건 최적화 (배터리 효율성과 데이터 수집의 균형)
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.NOT_REQUIRED) // 네트워크 불필요
                .setRequiresBatteryNotLow(false) // 배터리 부족해도 실행 (충전 중이므로)
                .setRequiresCharging(false) // 충전 중이 아니어도 실행 (충전 중일 때만 실행되므로)
                .setRequiresDeviceIdle(false) // 기기가 유휴 상태일 필요 없음
                .setRequiresStorageNotLow(false) // 저장 공간 부족해도 실행
                .build()
            
            // 즉시 실행할 OneTimeWorkRequest 생성 (첫 데이터 수집)
            val immediateWorkRequest = OneTimeWorkRequestBuilder<ChargingDataWorker>()
                .setConstraints(constraints)
                .addTag(WORK_NAME)
                .build()
            
            // 주기적 작업 요청 생성 (15분마다 실행)
            // 주의: PeriodicWorkRequest의 최소 간격은 15분
            val periodicWorkRequest = PeriodicWorkRequestBuilder<ChargingDataWorker>(
                WORK_INTERVAL_MINUTES, TimeUnit.MINUTES
            )
                .setConstraints(constraints)
                .addTag(WORK_NAME)
                .build()
            
            // 즉시 실행 작업 추가
            workManager.enqueue(immediateWorkRequest)
            
            // 주기적 작업 예약 (기존 작업이 있으면 교체)
            workManager.enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.REPLACE,
                periodicWorkRequest
            )
            
            Log.d("BatteryPal", "BatteryStateReceiver: WorkManager 작업 예약 완료 (즉시 실행 + ${WORK_INTERVAL_MINUTES}분 간격)")
        } catch (e: Exception) {
            Log.e("BatteryPal", "BatteryStateReceiver: WorkManager 작업 예약 실패", e)
        }
    }
    
    /// WorkManager 주기적 작업 취소
    private fun cancelChargingDataCollection(context: Context) {
        try {
            val workManager = WorkManager.getInstance(context)
            workManager.cancelUniqueWork(WORK_NAME)
            Log.d("BatteryPal", "BatteryStateReceiver: WorkManager 주기적 작업 취소 완료")
        } catch (e: Exception) {
            Log.e("BatteryPal", "BatteryStateReceiver: WorkManager 작업 취소 실패", e)
        }
    }
}

