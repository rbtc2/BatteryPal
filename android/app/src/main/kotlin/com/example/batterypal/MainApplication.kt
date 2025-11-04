package com.example.batterypal

import android.app.Application
import android.content.Intent
import android.content.IntentFilter
import android.util.Log

/// 앱의 메인 Application 클래스
/// 백그라운드에서도 배터리 상태를 모니터링하기 위해 BroadcastReceiver 등록
class MainApplication : Application() {
    private var batteryReceiver: BatteryStateReceiver? = null
    
    override fun onCreate() {
        super.onCreate()
        Log.d("BatteryPal", "MainApplication: onCreate 호출됨")
        setupBatteryReceiver()
    }
    
    override fun onTerminate() {
        super.onTerminate()
        Log.d("BatteryPal", "MainApplication: onTerminate 호출됨")
        unregisterBatteryReceiver()
    }
    
    /// 배터리 상태 변화 실시간 감지를 위한 BroadcastReceiver 설정
    private fun setupBatteryReceiver() {
        try {
            batteryReceiver = BatteryStateReceiver()
            
            val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
            registerReceiver(batteryReceiver, filter)
            Log.d("BatteryPal", "MainApplication: 배터리 BroadcastReceiver 등록 완료")
        } catch (e: Exception) {
            Log.e("BatteryPal", "MainApplication: 배터리 BroadcastReceiver 설정 실패", e)
        }
    }
    
    /// BroadcastReceiver 해제
    private fun unregisterBatteryReceiver() {
        try {
            batteryReceiver?.let { receiver ->
                unregisterReceiver(receiver)
                Log.d("BatteryPal", "MainApplication: 배터리 BroadcastReceiver 해제 완료")
            }
        } catch (e: Exception) {
            Log.e("BatteryPal", "MainApplication: 배터리 BroadcastReceiver 해제 실패", e)
        }
    }
}

