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
import android.app.usage.UsageStatsManager
import android.app.usage.UsageEvents
import android.app.AppOpsManager
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
                "getChargingSessionInfo" -> {
                    val sessionInfo = getChargingSessionInfo()
                    result.success(sessionInfo)
                }
                "getDeveloperModeChargingTestEnabled" -> {
                    val isEnabled = getDeveloperModeChargingTestEnabled()
                    result.success(isEnabled)
                }
                "getAllFlutterSharedPreferences" -> {
                    val allPrefs = getAllFlutterSharedPreferences()
                    result.success(allPrefs)
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
                "hasUsageStatsPermission" -> {
                    val hasPermission = hasUsageStatsPermission()
                    result.success(hasPermission)
                }
                "openUsageStatsSettings" -> {
                    openUsageStatsSettings()
                    result.success(true)
                }
                "getScreenOnTime" -> {
                    val dateMillis = call.argument<Long>("dateMillis")
                    if (dateMillis != null) {
                        val screenOnTime = getScreenOnTime(dateMillis)
                        result.success(screenOnTime) // 밀리초 단위로 반환
                    } else {
                        result.error("INVALID_ARGUMENT", "dateMillis is required", null)
                    }
                }
                "checkDateChange" -> {
                    val dateChanged = DateChangeReceiver.checkAndClearDateChangeFlag(applicationContext)
                    result.success(dateChanged)
                }
                "getCurrentDateKey" -> {
                    val dateKey = DateChangeReceiver.getCurrentDateKey()
                    result.success(dateKey)
                }
                "isIgnoringBatteryOptimizations" -> {
                    val isIgnoring = isIgnoringBatteryOptimizations()
                    result.success(isIgnoring)
                }
                "openBatteryOptimizationSettings" -> {
                    openBatteryOptimizationSettings()
                    result.success(true)
                }
                "getDeveloperModeChargingTestEnabled" -> {
                    val isEnabled = getDeveloperModeChargingTestEnabled()
                    result.success(isEnabled)
                }
                "getAllFlutterSharedPreferences" -> {
                    val allPrefs = getAllFlutterSharedPreferences()
                    result.success(allPrefs)
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

    /// 충전 세션 정보 가져오기 (SharedPreferences에서 읽기)
    /// BatteryStateReceiver에서 저장한 충전 세션 정보를 읽어옵니다
    private fun getChargingSessionInfo(): Map<String, Any?> {
        return try {
            val batteryStatePrefs = applicationContext.getSharedPreferences("battery_state", Context.MODE_PRIVATE)
            
            val startTime = batteryStatePrefs.getLong("charging_session_start_time", -1)
            val endTime = batteryStatePrefs.getLong("charging_session_end_time", -1)
            val isChargingActive = batteryStatePrefs.getBoolean("is_charging_active", false)
            val startBatteryLevel = batteryStatePrefs.getFloat("charging_start_battery_level", -1f)
            val endBatteryLevel = batteryStatePrefs.getFloat("charging_end_battery_level", -1f)
            val chargingType = batteryStatePrefs.getString("charging_type", null)
            
            val result = mapOf<String, Any?>(
                "startTime" to (if (startTime > 0) startTime else null),
                "endTime" to (if (endTime > 0) endTime else null),
                "isChargingActive" to isChargingActive,
                "startBatteryLevel" to (if (startBatteryLevel >= 0) startBatteryLevel.toDouble() else null),
                "endBatteryLevel" to (if (endBatteryLevel >= 0) endBatteryLevel.toDouble() else null),
                "chargingType" to chargingType
            )
            
            android.util.Log.d("BatteryPal", "충전 세션 정보: $result")
            result
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "충전 세션 정보 가져오기 실패", e)
            mapOf<String, Any?>(
                "startTime" to null,
                "endTime" to null,
                "isChargingActive" to false,
                "startBatteryLevel" to null,
                "endBatteryLevel" to null,
                "chargingType" to null
            )
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

    // ========== Usage Stats 관련 메서드들 (화면 켜짐 시간 추적용) ==========

    /// Usage Stats 권한 확인
    /// AppOpsManager를 사용하여 정확한 권한 상태를 확인합니다
    private fun hasUsageStatsPermission(): Boolean {
        return try {
            // AppOpsManager를 사용한 권한 확인 (가장 정확한 방법)
            val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
            
            // MODE_ALLOWED = 0 (권한 허용됨)
            val hasPermission = mode == AppOpsManager.MODE_ALLOWED
            
            // 디버깅을 위한 상세 로그
            val modeString = when (mode) {
                AppOpsManager.MODE_ALLOWED -> "ALLOWED"
                AppOpsManager.MODE_IGNORED -> "IGNORED"
                AppOpsManager.MODE_ERRORED -> "ERRORED"
                AppOpsManager.MODE_DEFAULT -> "DEFAULT"
                else -> "UNKNOWN($mode)"
            }
            android.util.Log.d("BatteryPal", "Usage Stats 권한: $hasPermission (mode: $modeString)")
            
            hasPermission
        } catch (e: SecurityException) {
            // SecurityException이 발생하면 권한이 없는 것으로 간주
            android.util.Log.w("BatteryPal", "Usage Stats 권한 확인 중 SecurityException 발생: ${e.message}")
            false
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "Usage Stats 권한 확인 실패", e)
            false
        }
    }

    /// Usage Stats 설정 화면으로 이동
    private fun openUsageStatsSettings() {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
            android.util.Log.d("BatteryPal", "Usage Stats 설정 화면 열기")
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "Usage Stats 설정 화면 열기 실패", e)
        }
    }

    /// 특정 날짜의 화면 켜짐 시간 가져오기 (밀리초 단위)
    /// 
    /// [dateMillis] 조회할 날짜의 시작 시간 (밀리초)
    /// Returns 화면 켜짐 시간 (밀리초), 권한이 없으면 -1
    private fun getScreenOnTime(dateMillis: Long): Long {
        return try {
            if (!hasUsageStatsPermission()) {
                android.util.Log.w("BatteryPal", "Usage Stats 권한이 없습니다")
                return -1
            }
            
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            
            // 해당 날짜의 시작 시간과 끝 시간 계산
            val calendar = java.util.Calendar.getInstance()
            calendar.timeInMillis = dateMillis
            calendar.set(java.util.Calendar.HOUR_OF_DAY, 0)
            calendar.set(java.util.Calendar.MINUTE, 0)
            calendar.set(java.util.Calendar.SECOND, 0)
            calendar.set(java.util.Calendar.MILLISECOND, 0)
            val startTime = calendar.timeInMillis
            
            calendar.add(java.util.Calendar.DAY_OF_MONTH, 1)
            val endTime = calendar.timeInMillis
            
            // UsageEvents를 사용하여 화면 켜짐/꺼짐 이벤트 추적
            val usageEvents = usageStatsManager.queryEvents(startTime, endTime)
            
            if (usageEvents == null) {
                android.util.Log.w("BatteryPal", "UsageEvents가 null입니다")
                return 0
            }
            
            var screenOnTime = 0L
            var lastScreenOnTime: Long? = null
            
            // 이벤트 객체는 루프 밖에서 한 번만 생성 (재사용 방식)
            val event = UsageEvents.Event()
            
            android.util.Log.d("BatteryPal", "화면 켜짐 시간 조회: ${java.util.Date(startTime)} ~ ${java.util.Date(endTime)}")
            
            while (usageEvents.hasNextEvent()) {
                usageEvents.getNextEvent(event)
                
                // 날짜 범위를 벗어나는 이벤트는 무시 (안전성 검증)
                if (event.timeStamp < startTime || event.timeStamp > endTime) {
                    android.util.Log.w("BatteryPal", "날짜 범위를 벗어나는 이벤트 무시: ${java.util.Date(event.timeStamp)}")
                    continue
                }
                
                when (event.eventType) {
                    UsageEvents.Event.SCREEN_INTERACTIVE -> {
                        // 이미 화면이 켜져있던 경우, 이전 시간을 먼저 처리
                        if (lastScreenOnTime != null) {
                            // 이전 켜짐 시간이 현재 켜짐 시간보다 이전인 경우만 처리
                            // (중복 이벤트 방지)
                            if (lastScreenOnTime < event.timeStamp) {
                                // 이전 켜짐부터 현재 켜짐까지는 이미 화면이 켜져있었으므로
                                // 이전 시간을 현재 시간으로 업데이트만 함 (중복 계산 방지)
                                android.util.Log.d("BatteryPal", "중복 SCREEN_INTERACTIVE 이벤트: ${java.util.Date(lastScreenOnTime)} -> ${java.util.Date(event.timeStamp)}")
                            }
                        }
                        lastScreenOnTime = event.timeStamp
                        android.util.Log.d("BatteryPal", "화면 켜짐: ${java.util.Date(event.timeStamp)}")
                    }
                    UsageEvents.Event.SCREEN_NON_INTERACTIVE -> {
                        // 화면이 꺼짐
                        if (lastScreenOnTime != null) {
                            // 날짜 범위 내에서만 계산 (안전성 검증)
                            val onStart = kotlin.math.max(lastScreenOnTime, startTime)
                            val onEnd = kotlin.math.min(event.timeStamp, endTime)
                            
                            if (onEnd > onStart) {
                                val duration = onEnd - onStart
                                // 음수나 비정상적인 값 방지
                                if (duration > 0 && duration <= (endTime - startTime)) {
                                    screenOnTime += duration
                                    android.util.Log.d("BatteryPal", "화면 꺼짐: ${java.util.Date(event.timeStamp)}, 지속 시간: ${duration / 1000 / 60}분")
                                } else {
                                    android.util.Log.w("BatteryPal", "비정상적인 지속 시간 무시: ${duration}ms")
                                }
                            }
                        }
                        lastScreenOnTime = null
                    }
                }
            }
            
            // 아직 화면이 켜져있는 경우 (마지막 이벤트가 SCREEN_INTERACTIVE인 경우)
            // 하지만 날짜 범위를 벗어나면 안 됨 (안전성 검증)
            if (lastScreenOnTime != null) {
                val currentTime = System.currentTimeMillis()
                val onStart = kotlin.math.max(lastScreenOnTime, startTime)
                val onEnd = kotlin.math.min(currentTime, endTime) // 날짜 범위를 넘지 않도록
                
                if (onEnd > onStart) {
                    val duration = onEnd - onStart
                    // 음수나 비정상적인 값 방지
                    if (duration > 0 && duration <= (endTime - startTime)) {
                        screenOnTime += duration
                        android.util.Log.d("BatteryPal", "화면이 아직 켜져있음, 추가 시간: ${duration / 1000 / 60}분")
                    } else {
                        android.util.Log.w("BatteryPal", "비정상적인 추가 시간 무시: ${duration}ms")
                    }
                }
            }
            
            // 최대값 제한: 하루는 24시간을 넘을 수 없음 (안전성 검증)
            val maxTimeForDay = 24 * 60 * 60 * 1000L // 24시간을 밀리초로
            if (screenOnTime > maxTimeForDay) {
                android.util.Log.w("BatteryPal", "화면 켜짐 시간이 24시간을 초과: ${screenOnTime}ms (${screenOnTime / 1000.0 / 60.0 / 60.0}시간) -> ${maxTimeForDay}ms (24시간)로 제한")
                screenOnTime = maxTimeForDay
            }
            
            val hours = screenOnTime / 1000.0 / 60.0 / 60.0
            android.util.Log.d("BatteryPal", "화면 켜짐 시간: ${"%.2f".format(hours)}시간 (${screenOnTime}ms)")
            screenOnTime
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "화면 켜짐 시간 가져오기 실패", e)
            -1
        }
    }

    // ========== 배터리 최적화 예외 처리 (Phase 3) ==========

    /// 배터리 최적화 예외 여부 확인
    /// 
    /// Returns: 배터리 최적화에서 제외되었으면 true, 그렇지 않으면 false
    private fun isIgnoringBatteryOptimizations(): Boolean {
        return try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                val powerManager = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
                val isIgnoring = powerManager.isIgnoringBatteryOptimizations(packageName)
                android.util.Log.d("BatteryPal", "배터리 최적화 예외 여부: $isIgnoring")
                isIgnoring
            } else {
                // API 23 미만에서는 항상 true (배터리 최적화 기능 없음)
                true
            }
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "배터리 최적화 예외 확인 실패", e)
            false
        }
    }

    /// 배터리 최적화 설정 화면으로 이동
    /// 
    /// 사용자가 앱을 배터리 최적화에서 제외할 수 있도록 설정 화면을 엽니다.
    private fun openBatteryOptimizationSettings() {
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                startActivity(intent)
                android.util.Log.d("BatteryPal", "배터리 최적화 설정 화면 열기")
            } else {
                // API 23 미만에서는 배터리 최적화 기능이 없음
                android.util.Log.d("BatteryPal", "API 23 미만에서는 배터리 최적화 기능이 없습니다")
            }
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "배터리 최적화 설정 화면 열기 실패", e)
        }
    }
    
    // ========== 개발자 모드 디버깅 메서드 ==========
    
    /// 개발자 모드 충전 테스트 활성화 여부 확인
    /// Flutter SharedPreferences에서 직접 읽어옵니다
    private fun getDeveloperModeChargingTestEnabled(): Boolean {
        return try {
            val flutterPrefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            // Flutter SharedPreferences는 키를 그대로 저장
            val isEnabled = flutterPrefs.getBoolean("developerModeChargingTestEnabled", false)
            android.util.Log.d("BatteryPal", "개발자 모드 충전 테스트 활성화 여부 (MainActivity): $isEnabled")
            isEnabled
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "개발자 모드 설정 읽기 실패", e)
            false
        }
    }
    
    /// Flutter SharedPreferences의 모든 키-값 쌍 가져오기 (디버깅용)
    private fun getAllFlutterSharedPreferences(): Map<String, Any?> {
        return try {
            val flutterPrefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val allEntries = flutterPrefs.all
            
            android.util.Log.d("BatteryPal", "Flutter SharedPreferences 전체 키 개수: ${allEntries.size}")
            
            // 모든 키를 반환 (디버깅용)
            allEntries.mapKeys { it.key }
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "Flutter SharedPreferences 읽기 실패", e)
            emptyMap()
        }
    }
}
