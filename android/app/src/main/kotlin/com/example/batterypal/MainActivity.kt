package com.example.batterypal

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Bundle
import android.provider.Settings
import android.location.LocationManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.content.ContentResolver
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.batterypal/battery"
    private val SYSTEM_SETTINGS_CHANNEL = "com.example.batterypal/system_settings"
    private var batteryReceiver: BroadcastReceiver? = null
    private var methodChannel: MethodChannel? = null
    private var systemSettingsChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 배터리 채널 설정
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getBatteryTemperature" -> {
                    val temperature = getBatteryTemperature()
                    result.success(temperature)
                }
                "getBatteryVoltage" -> {
                    val voltage = getBatteryVoltage()
                    result.success(voltage)
                }
                "getBatteryCapacity" -> {
                    val capacity = getBatteryCapacity()
                    result.success(capacity)
                }
                "getBatteryHealth" -> {
                    val health = getBatteryHealth()
                    result.success(health)
                }
                "getBatteryLevel" -> {
                    val level = getBatteryLevel()
                    result.success(level)
                }
                "getChargingInfo" -> {
                    val chargingInfo = getChargingInfo()
                    result.success(chargingInfo)
                }
                "getChargingCurrentOnly" -> {
                    val chargingCurrent = getChargingCurrentOnly()
                    result.success(chargingCurrent)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // 시스템 설정 채널 설정
        systemSettingsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYSTEM_SETTINGS_CHANNEL)
        systemSettingsChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getScreenBrightness" -> {
                    val brightness = getScreenBrightness()
                    result.success(brightness)
                }
                "getLocationServiceStatus" -> {
                    val status = getLocationServiceStatus()
                    result.success(status)
                }
                "getNetworkConnectionType" -> {
                    val type = getNetworkConnectionType()
                    result.success(type)
                }
                "getScreenTimeout" -> {
                    val timeout = getScreenTimeout()
                    result.success(timeout)
                }
                "isBatterySaverEnabled" -> {
                    val enabled = isBatterySaverEnabled()
                    result.success(enabled)
                }
                "getSyncStatus" -> {
                    val status = getSyncStatus()
                    result.success(status)
                }
                "setScreenBrightness" -> {
                    val brightness = call.argument<Int>("brightness")
                    if (brightness != null) {
                        val success = setScreenBrightness(brightness)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "Brightness value is required", null)
                    }
                }
                "canWriteSettings" -> {
                    val canWrite = canWriteSettings()
                    result.success(canWrite)
                }
                "openWriteSettingsPermission" -> {
                    openWriteSettingsPermission()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setupBatteryReceiver()
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterBatteryReceiver()
    }

    /// 배터리 상태 변화 실시간 감지를 위한 BroadcastReceiver 설정
    private fun setupBatteryReceiver() {
        try {
            batteryReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    if (intent?.action == Intent.ACTION_BATTERY_CHANGED) {
                        // 즉시 충전 상태 확인 및 Flutter에 알림
                        val chargingInfo = getChargingInfo()
                        notifyFlutterBatteryChange(chargingInfo)
                    }
                }
            }
            
            val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
            registerReceiver(batteryReceiver, filter)
            android.util.Log.d("BatteryPal", "배터리 BroadcastReceiver 등록 완료")
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "배터리 BroadcastReceiver 설정 실패", e)
        }
    }

    /// BroadcastReceiver 해제
    private fun unregisterBatteryReceiver() {
        try {
            batteryReceiver?.let { receiver ->
                unregisterReceiver(receiver)
                android.util.Log.d("BatteryPal", "배터리 BroadcastReceiver 해제 완료")
            }
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "배터리 BroadcastReceiver 해제 실패", e)
        }
    }

    /// Flutter에 배터리 상태 변화 즉시 알림
    private fun notifyFlutterBatteryChange(chargingInfo: Map<String, Any>) {
        try {
            methodChannel?.invokeMethod("onBatteryStateChanged", chargingInfo)
            android.util.Log.d("BatteryPal", "Flutter에 배터리 상태 변화 알림: $chargingInfo")
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "Flutter 알림 실패", e)
        }
    }

    // 공통 배터리 인텐트 가져오기 메서드 (권장 방법)
    private fun getBatteryIntent(): Intent? {
        return try {
            val batteryIntent = applicationContext.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            if (batteryIntent == null) {
                android.util.Log.w("BatteryPal", "배터리 인텐트가 null입니다")
            }
            batteryIntent
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "배터리 인텐트 가져오기 실패", e)
            null
        }
    }

    private fun getBatteryTemperature(): Double {
        try {
            val batteryIntent = getBatteryIntent()
            if (batteryIntent == null) {
                android.util.Log.w("BatteryPal", "배터리 인텐트가 null입니다")
                return -1.0
            }
            
            val temperature = batteryIntent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1)
            val result = if (temperature != -1) temperature / 10.0 else -1.0 // 온도는 0.1도 단위로 저장됨
            android.util.Log.d("BatteryPal", "배터리 온도: $result°C (원본: $temperature)")
            return result
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "배터리 온도 가져오기 실패", e)
            return -1.0
        }
    }

    private fun getBatteryVoltage(): Int {
        try {
            val batteryIntent = getBatteryIntent()
            if (batteryIntent == null) {
                android.util.Log.w("BatteryPal", "배터리 인텐트가 null입니다")
                return -1
            }
            
            val voltage = batteryIntent.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1)
            android.util.Log.d("BatteryPal", "배터리 전압: ${voltage}mV")
            return voltage
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "배터리 전압 가져오기 실패", e)
            return -1
        }
    }

    private fun getBatteryCapacity(): Int {
        try {
            val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            
            // BatteryManager를 사용하여 실제 배터리 용량 가져오기 (API 21+)
            val capacity = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
                batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
            } else {
                // API 21 미만에서는 기본값 반환
                -1
            }
            android.util.Log.d("BatteryPal", "배터리 용량: ${capacity}mAh (API 레벨: ${android.os.Build.VERSION.SDK_INT})")
            return capacity
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "배터리 용량 가져오기 실패", e)
            return -1
        }
    }

    private fun getBatteryHealth(): Int {
        try {
            val batteryIntent = getBatteryIntent()
            val health = batteryIntent?.getIntExtra(BatteryManager.EXTRA_HEALTH, -1) ?: -1
            android.util.Log.d("BatteryPal", "배터리 건강도: $health")
            return health
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "배터리 건강도 가져오기 실패", e)
            return -1
        }
    }

    private fun getBatteryLevel(): Double {
        try {
            val batteryIntent = getBatteryIntent()
            if (batteryIntent == null) {
                android.util.Log.w("BatteryPal", "배터리 인텐트가 null입니다")
                return -1.0
            }
            
            val level = batteryIntent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            val scale = batteryIntent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
            
            val result = if (level != -1 && scale != -1 && scale > 0) {
                // 더 정확한 배터리 레벨 계산 (소수점 포함)
                val percentage = (level * 100.0) / scale
                // 소수점 둘째 자리까지 반올림
                kotlin.math.round(percentage * 100.0) / 100.0
            } else -1.0
            
            android.util.Log.d("BatteryPal", "배터리 레벨: ${result}% (레벨: $level, 스케일: $scale)")
            return result
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "배터리 레벨 가져오기 실패", e)
            return -1.0
        }
    }

    private fun getChargingInfo(): Map<String, Any> {
        try {
            val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            val batteryIntent = getBatteryIntent()
            
            if (batteryIntent == null) {
                android.util.Log.w("BatteryPal", "배터리 인텐트가 null입니다")
                return mapOf(
                    "chargingType" to "Unknown",
                    "chargingCurrent" to -1,
                    "currentNow" to -1,
                    "currentAverage" to -1,
                    "isCharging" to false
                )
            }
            
            val plugged = batteryIntent.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1)
            val status = batteryIntent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
            
            // 충전 방식 구분 (더 정확한 감지)
            val chargingType = when (plugged) {
                BatteryManager.BATTERY_PLUGGED_AC -> "AC"
                BatteryManager.BATTERY_PLUGGED_USB -> "USB"
                BatteryManager.BATTERY_PLUGGED_WIRELESS -> "Wireless"
                else -> "Unknown"
            }
            
            // BatteryManager를 사용하여 현재 전류 가져오기 (API 21+)
            var currentNow = -1
            var currentAverage = -1
            try {
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
                    currentNow = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
                    currentAverage = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_AVERAGE)
                }
            } catch (e: Exception) {
                android.util.Log.w("BatteryPal", "전류 정보 가져오기 실패: ${e.message}")
                currentNow = -1
                currentAverage = -1
            }
            
            // 충전 전류 (mA) - 더 정확한 계산
            val chargingCurrent = if (currentNow != -1) {
                // 음수는 방전, 양수는 충전을 의미
                kotlin.math.abs(currentNow / 1000)
            } else -1
            
            // 충전 상태 더 정확히 감지
            val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING || 
                            status == BatteryManager.BATTERY_STATUS_FULL ||
                            plugged != 0
            
            val result = mapOf(
                "chargingType" to chargingType,
                "chargingCurrent" to chargingCurrent,
                "currentNow" to currentNow,
                "currentAverage" to currentAverage,
                "isCharging" to isCharging,
                "plugged" to plugged,
                "status" to status
            )
            
            android.util.Log.d("BatteryPal", "충전 정보: $result")
            return result
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "충전 정보 가져오기 실패", e)
            return mapOf(
                "chargingType" to "Unknown",
                "chargingCurrent" to -1,
                "currentNow" to -1,
                "currentAverage" to -1,
                "isCharging" to false
            )
        }
    }
    
    /// 충전 전류만 빠르게 가져오기 (실시간 모니터링용)
    private fun getChargingCurrentOnly(): Int {
        try {
            val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            
            // BatteryManager를 사용하여 현재 전류만 빠르게 가져오기
            var currentNow = -1
            try {
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
                    currentNow = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
                }
            } catch (e: Exception) {
                android.util.Log.w("BatteryPal", "충전 전류만 가져오기 실패: ${e.message}")
                return -1
            }
            
            // 충전 전류 (mA) - 절댓값 사용
            val chargingCurrent = if (currentNow != -1) {
                kotlin.math.abs(currentNow / 1000)
            } else -1
            
            android.util.Log.d("BatteryPal", "충전 전류만: ${chargingCurrent}mA (원본: $currentNow)")
            return chargingCurrent
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "충전 전류만 가져오기 실패", e)
            return -1
        }
    }

    // ========== 시스템 설정 읽기 메서드들 ==========

    /// 화면 밝기 읽기 (0-100)
    private fun getScreenBrightness(): Int {
        return try {
            val brightness = Settings.System.getInt(
                contentResolver,
                Settings.System.SCREEN_BRIGHTNESS
            )
            // Android의 밝기 값은 0-255 범위이므로 0-100으로 변환
            val percentage = (brightness * 100) / 255
            android.util.Log.d("BatteryPal", "화면 밝기: $percentage% (원본: $brightness)")
            percentage
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "화면 밝기 읽기 실패", e)
            -1
        }
    }

    /// 위치 서비스 상태 읽기
    private fun getLocationServiceStatus(): String {
        return try {
            val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
            val isGpsEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
            val isNetworkEnabled = locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
            
            val status = when {
                isGpsEnabled && isNetworkEnabled -> "고정밀도"
                isGpsEnabled -> "GPS만"
                isNetworkEnabled -> "네트워크만"
                else -> "꺼짐"
            }
            android.util.Log.d("BatteryPal", "위치 서비스 상태: $status")
            status
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "위치 서비스 상태 읽기 실패", e)
            "알 수 없음"
        }
    }

    /// 네트워크 연결 타입 읽기
    private fun getNetworkConnectionType(): String {
        return try {
            val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val network = connectivityManager.activeNetwork ?: return "없음"
            val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return "없음"
            
            val type = when {
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "Wi-Fi"
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> {
                    // 5G/4G/3G 구분 (Android 10+)
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                        // NET_CAPABILITY_NR = 24 (API 29+)
                        val is5G = capabilities.hasCapability(24) // NET_CAPABILITY_NR
                        if (is5G) {
                            "5G"
                        } else {
                            "4G"
                        }
                    } else {
                        "모바일 데이터"
                    }
                }
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "이더넷"
                else -> "없음"
            }
            android.util.Log.d("BatteryPal", "네트워크 연결 타입: $type")
            type
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "네트워크 연결 타입 읽기 실패", e)
            "알 수 없음"
        }
    }

    /// 화면 시간 초과 읽기 (초 단위)
    private fun getScreenTimeout(): Int {
        return try {
            val timeout = Settings.System.getInt(
                contentResolver,
                Settings.System.SCREEN_OFF_TIMEOUT
            )
            // 밀리초를 초로 변환
            val seconds = timeout / 1000
            android.util.Log.d("BatteryPal", "화면 시간 초과: ${seconds}초 (원본: ${timeout}ms)")
            seconds
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "화면 시간 초과 읽기 실패", e)
            -1
        }
    }

    /// 배터리 세이버 모드 상태 읽기
    private fun isBatterySaverEnabled(): Boolean {
        return try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
            val isEnabled = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
                powerManager.isPowerSaveMode
            } else {
                false
            }
            android.util.Log.d("BatteryPal", "배터리 세이버 모드: $isEnabled")
            isEnabled
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "배터리 세이버 모드 상태 읽기 실패", e)
            false
        }
    }

    /// 동기화 상태 읽기
    private fun getSyncStatus(): String {
        return try {
            val isSyncEnabled = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
                ContentResolver.getMasterSyncAutomatically()
            } else {
                // API 21 미만에서는 기본값 반환
                true
            }
            val status = if (isSyncEnabled) "자동 동기화 켜짐" else "자동 동기화 꺼짐"
            android.util.Log.d("BatteryPal", "동기화 상태: $status")
            status
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "동기화 상태 읽기 실패", e)
            "알 수 없음"
        }
    }

    /// 화면 밝기 설정 (0-100)
    /// 
    /// [brightness] 0-100 범위의 밝기 값
    /// Returns 설정 성공 여부
    private fun setScreenBrightness(brightness: Int): Boolean {
        return try {
            // 권한 확인
            if (!canWriteSettings()) {
                android.util.Log.w("BatteryPal", "화면 밝기 설정 권한이 없습니다")
                return false
            }

            // 0-100을 0-255로 변환
            val systemBrightness = (brightness * 255 / 100).coerceIn(0, 255)
            
            Settings.System.putInt(
                contentResolver,
                Settings.System.SCREEN_BRIGHTNESS,
                systemBrightness
            )
            
            android.util.Log.d("BatteryPal", "화면 밝기 설정: $brightness% (시스템 값: $systemBrightness)")
            true
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "화면 밝기 설정 실패", e)
            false
        }
    }

    /// 시스템 설정 변경 권한 확인
    /// 
    /// Returns 권한이 있는지 여부
    private fun canWriteSettings(): Boolean {
        return try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                Settings.System.canWrite(this)
            } else {
                // API 23 미만에서는 기본적으로 권한이 있음
                true
            }
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "권한 확인 실패", e)
            false
        }
    }

    /// 시스템 설정 변경 권한 설정 화면으로 이동
    /// WRITE_SETTINGS 권한을 허용하기 위한 특별한 설정 화면으로 이동
    private fun openWriteSettingsPermission() {
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).apply {
                    data = android.net.Uri.parse("package:$packageName")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(intent)
                android.util.Log.d("BatteryPal", "시스템 설정 변경 권한 설정 화면으로 이동")
            } else {
                // API 23 미만에서는 권한이 필요 없음
                android.util.Log.d("BatteryPal", "API 23 미만에서는 권한이 필요 없습니다")
            }
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "권한 설정 화면 열기 실패", e)
        }
    }
}
