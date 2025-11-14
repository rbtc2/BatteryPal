package com.example.batterypal

import android.app.Application
import android.util.Log

/// 앱의 메인 Application 클래스
/// 
/// 참고: BatteryStateReceiver는 AndroidManifest.xml에 정적으로 등록되어 있어
/// 앱이 종료되어도 작동합니다. 동적 등록은 필요하지 않습니다.
class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        Log.d("BatteryPal", "MainApplication: onCreate 호출됨")
    }
    
    override fun onTerminate() {
        super.onTerminate()
        Log.d("BatteryPal", "MainApplication: onTerminate 호출됨")
    }
}

