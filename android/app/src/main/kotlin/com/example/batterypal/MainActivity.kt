package com.example.batterypal

import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.BatteryManager
import android.os.Bundle
import android.provider.Settings
import android.net.Uri
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.batterypal/battery"
    private var batteryReceiver: BroadcastReceiver? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
                "getAppUsageStats" -> {
                    val appUsageStats = getAppUsageStats()
                    result.success(appUsageStats)
                }
                "getTodayScreenTime" -> {
                    val screenTime = getTodayScreenTime()
                    result.success(screenTime)
                }
                "checkUsageStatsPermission" -> {
                    val hasPermission = checkUsageStatsPermission()
                    result.success(hasPermission)
                }
                "openUsageStatsSettings" -> {
                    openUsageStatsSettings()
                    result.success(null)
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
    
    /// 앱 사용 통계 가져오기
    private fun getAppUsageStats(): List<Map<String, Any>> {
        try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val pm = packageManager
            val time = System.currentTimeMillis()
            // 오늘 자정(00:00:00)부터 현재까지의 데이터 가져오기
            val calendar = java.util.Calendar.getInstance().apply {
                timeInMillis = time
                set(java.util.Calendar.HOUR_OF_DAY, 0)
                set(java.util.Calendar.MINUTE, 0)
                set(java.util.Calendar.SECOND, 0)
                set(java.util.Calendar.MILLISECOND, 0)
            }
            val startTime = calendar.timeInMillis
            
            val usageStats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                time
            )
            
            return usageStats.map { usage ->
                // PackageManager를 사용하여 실제 앱 이름 가져오기
                var appName = usage.packageName
                var appIcon = ""
                
                try {
                    val applicationInfo = pm.getApplicationInfo(usage.packageName, PackageManager.GET_META_DATA)
                    // loadLabel() 사용 (getApplicationLabel()보다 더 안정적)
                    appName = applicationInfo.loadLabel(pm).toString()
                    
                    // loadLabel()이 실패하거나 빈 문자열이면 getApplicationLabel() 사용
                    if (appName.isEmpty() || appName == usage.packageName) {
                        val label = pm.getApplicationLabel(applicationInfo)
                        appName = label?.toString() ?: usage.packageName
                    }
                    
                    // 앱 아이콘 가져오기
                    try {
                        val drawable = pm.getApplicationIcon(usage.packageName)
                        val bitmap = drawableToBitmap(drawable, 96, 96) // 96x96 크기로 변환
                        val outputStream = java.io.ByteArrayOutputStream()
                        bitmap.compress(Bitmap.CompressFormat.PNG, 90, outputStream)
                        val iconBytes = outputStream.toByteArray()
                        if (iconBytes.isNotEmpty()) {
                            appIcon = android.util.Base64.encodeToString(iconBytes, android.util.Base64.NO_WRAP)
                        } else {
                            appIcon = ""
                        }
                    } catch (e: Exception) {
                        // 아이콘 가져오기 실패 시 빈 문자열
                        appIcon = ""
                        android.util.Log.w("BatteryPal", "앱 아이콘 가져오기 실패 (${usage.packageName}): ${e.message}")
                    }
                } catch (e: android.content.pm.PackageManager.NameNotFoundException) {
                    // 앱이 설치되지 않았거나 제거된 경우
                    val parts = usage.packageName.split('.')
                    appName = if (parts.isNotEmpty()) parts.last() else usage.packageName
                    android.util.Log.w("BatteryPal", "앱을 찾을 수 없음 (${usage.packageName})")
                } catch (e: Exception) {
                    // 기타 예외 발생 시
                    val parts = usage.packageName.split('.')
                    appName = if (parts.isNotEmpty()) parts.last() else usage.packageName
                    android.util.Log.w("BatteryPal", "앱 이름 가져오기 실패 (${usage.packageName}): ${e.javaClass.simpleName}")
                }
                
                mapOf(
                    "packageName" to usage.packageName,
                    "appName" to appName,
                    "appIcon" to appIcon,
                    "totalTimeInForeground" to usage.totalTimeInForeground,
                    "lastTimeUsed" to usage.lastTimeUsed,
                    "launchCount" to 0, // launchCount는 API 레벨에 따라 사용 불가능할 수 있음
                    "firstTimeStamp" to usage.firstTimeStamp,
                    "lastTimeStamp" to usage.lastTimeStamp
                )
            }.sortedByDescending { it["totalTimeInForeground"] as Long }
            
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "앱 사용 통계 가져오기 실패", e)
            return emptyList()
        }
    }
    
    /// Drawable을 Bitmap으로 변환
    private fun drawableToBitmap(drawable: Drawable, width: Int, height: Int): Bitmap {
        // BitmapDrawable인 경우 크기 조정
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            val originalBitmap = drawable.bitmap
            // 원하는 크기와 다르면 크기 조정
            if (originalBitmap.width != width || originalBitmap.height != height) {
                return Bitmap.createScaledBitmap(originalBitmap, width, height, true)
            }
            return originalBitmap
        }
        
        // 일반 Drawable인 경우 Canvas에 그리기
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, width, height)
        drawable.draw(canvas)
        return bitmap
    }
    
    /// 오늘의 총 스크린 타임 계산
    private fun getTodayScreenTime(): Long {
        try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val time = System.currentTimeMillis()
            // 오늘 자정(00:00:00)부터 현재까지의 데이터 가져오기
            val calendar = java.util.Calendar.getInstance().apply {
                timeInMillis = time
                set(java.util.Calendar.HOUR_OF_DAY, 0)
                set(java.util.Calendar.MINUTE, 0)
                set(java.util.Calendar.SECOND, 0)
                set(java.util.Calendar.MILLISECOND, 0)
            }
            val startTime = calendar.timeInMillis
            
            val usageStats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                time
            )
            
            // 모든 앱의 포그라운드 시간을 합산
            val totalScreenTime = usageStats.sumOf { it.totalTimeInForeground }
            
            android.util.Log.d("BatteryPal", "오늘의 스크린 타임: ${totalScreenTime}ms")
            return totalScreenTime
            
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "스크린 타임 계산 실패", e)
            return 0L
        }
    }
    
    /// 사용 통계 권한 확인
    private fun checkUsageStatsPermission(): Boolean {
        try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val time = System.currentTimeMillis()
            // 오늘 자정(00:00:00)부터 현재까지의 데이터 가져오기
            val calendar = java.util.Calendar.getInstance().apply {
                timeInMillis = time
                set(java.util.Calendar.HOUR_OF_DAY, 0)
                set(java.util.Calendar.MINUTE, 0)
                set(java.util.Calendar.SECOND, 0)
                set(java.util.Calendar.MILLISECOND, 0)
            }
            val startTime = calendar.timeInMillis
            val usageStats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                time
            )
            
            // 권한이 있으면 빈 리스트가 아닌 데이터를 받을 수 있음
            val hasPermission = usageStats.isNotEmpty()
            android.util.Log.d("BatteryPal", "사용 통계 권한 상태: $hasPermission")
            return hasPermission
            
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "사용 통계 권한 확인 실패", e)
            return false
        }
    }
    
    /// 사용 통계 설정 화면 열기 (개선된 버전)
    /// 사용 통계 접근 권한 설정 화면으로 직접 이동
    private fun openUsageStatsSettings() {
        try {
            // 사용 통계 접근 권한 설정 화면으로 직접 이동
            // 이 화면에서 사용자는 BatteryPal 앱의 사용 통계 접근 권한을 허용할 수 있습니다
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            android.util.Log.d("BatteryPal", "사용 통계 설정 화면으로 이동")
        } catch (e: Exception) {
            android.util.Log.e("BatteryPal", "설정 화면 열기 실패", e)
            // 실패 시 앱 설정 페이지로 폴백
            try {
                val packageName = applicationContext.packageName
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(intent)
                android.util.Log.d("BatteryPal", "앱 설정 페이지로 폴백 이동 (패키지: $packageName)")
            } catch (e2: Exception) {
                android.util.Log.e("BatteryPal", "앱 설정 페이지 열기도 실패", e2)
            }
        }
    }
}
