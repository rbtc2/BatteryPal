package com.example.batterypal

import android.content.Context
import android.os.BatteryManager
import android.util.Log
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.util.concurrent.TimeUnit

/// 충전 데이터 수집을 위한 WorkManager Worker
/// 앱이 백그라운드에 있거나 종료된 상태에서도 주기적으로 충전 데이터를 수집합니다.
class ChargingDataWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    private val dataCollector = ChargingDataCollector(context)

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        try {
            Log.d("BatteryPal", "ChargingDataWorker: 작업 시작")
            
            // 충전 상태 확인
            val batteryIntent = applicationContext.registerReceiver(
                null,
                android.content.IntentFilter(android.content.Intent.ACTION_BATTERY_CHANGED)
            ) ?: return@withContext Result.retry()
            
            val plugged = batteryIntent.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1)
            val status = batteryIntent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
            val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING || 
                            status == BatteryManager.BATTERY_STATUS_FULL ||
                            plugged != 0
            
            if (!isCharging) {
                Log.d("BatteryPal", "ChargingDataWorker: 충전 중이 아니므로 작업 종료")
                // 충전이 종료되었으므로 WorkManager 작업도 취소해야 함
                // (BatteryStateReceiver에서 처리)
                return@withContext Result.success()
            }
            
            // 배터리 정보 수집 및 저장
            val success = dataCollector.collectAndSaveBatteryData()
            
            if (success) {
                Log.d("BatteryPal", "ChargingDataWorker: 데이터 수집 및 저장 완료")
                
                // 충전 중이면 다음 작업도 예약 (OneTimeWorkRequest로 10초 후 실행)
                // 이렇게 하면 PeriodicWorkRequest의 15분 제한을 우회하여 더 자주 수집 가능
                if (isCharging) {
                    scheduleNextCollection(applicationContext)
                }
                
                Result.success()
            } else {
                Log.w("BatteryPal", "ChargingDataWorker: 데이터 수집 실패, 재시도")
                Result.retry()
            }
        } catch (e: Exception) {
            Log.e("BatteryPal", "ChargingDataWorker: 오류 발생", e)
            
            // Phase 5: 오류 처리 개선 - 재시도 횟수 제한
            val runAttemptCount = runAttemptCount
            if (runAttemptCount >= 3) {
                // 3번 재시도 후에도 실패하면 성공으로 처리 (무한 재시도 방지)
                Log.w("BatteryPal", "ChargingDataWorker: 최대 재시도 횟수 도달, 작업 종료")
                return@withContext Result.success()
            }
            
            Result.retry()
        }
    }
    
    /// 다음 데이터 수집 작업 예약 (적응형 주기)
    /// Phase 3: 충전 전류에 따라 수집 주기를 조정
    private fun scheduleNextCollection(context: Context) {
        try {
            val workManager = WorkManager.getInstance(context)
            
            // 현재 충전 전류 확인
            val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            var currentNow = -1
            try {
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
                    currentNow = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
                }
            } catch (e: Exception) {
                Log.w("BatteryPal", "ChargingDataWorker: 충전 전류 확인 실패: ${e.message}")
            }
            
            val chargingCurrent = if (currentNow != -1) {
                kotlin.math.abs(currentNow / 1000) // mA 단위
            } else -1
            
            // 적응형 수집 주기 계산
            val delaySeconds = calculateAdaptiveDelay(chargingCurrent)
            
            // Phase 3: 제약 조건 최적화
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.NOT_REQUIRED)
                .setRequiresBatteryNotLow(false)
                .setRequiresCharging(false)
                .setRequiresDeviceIdle(false)
                .setRequiresStorageNotLow(false)
                .build()
            
            val nextWorkRequest = OneTimeWorkRequestBuilder<ChargingDataWorker>()
                .setConstraints(constraints)
                .setInitialDelay(delaySeconds, TimeUnit.SECONDS)
                .addTag("charging_data_collection")
                .build()
            
            workManager.enqueue(nextWorkRequest)
            Log.d("BatteryPal", "ChargingDataWorker: 다음 데이터 수집 작업 예약 (${delaySeconds}초 후, 전류: ${chargingCurrent}mA)")
        } catch (e: Exception) {
            Log.e("BatteryPal", "ChargingDataWorker: 다음 작업 예약 실패", e)
        }
    }
    
    /// Phase 3: 적응형 수집 주기 계산
    /// 충전 전류가 높을수록 더 자주 수집, 낮을수록 덜 자주 수집
    private fun calculateAdaptiveDelay(chargingCurrent: Int): Long {
        // 충전 전류가 없거나 알 수 없으면 기본값 (10초)
        if (chargingCurrent <= 0) {
            return 10L
        }
        
        return when {
            // 초고속 충전 (2A 이상) - 5초마다 수집
            chargingCurrent >= 2000 -> 5L
            
            // 고속 충전 (1A ~ 2A) - 10초마다 수집
            chargingCurrent >= 1000 -> 10L
            
            // 일반 충전 (0.5A ~ 1A) - 20초마다 수집
            chargingCurrent >= 500 -> 20L
            
            // 저속 충전 (0.5A 미만) - 30초마다 수집
            else -> 30L
        }
    }
}

