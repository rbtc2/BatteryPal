package com.example.batterypal

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.os.BatteryManager
import android.util.Log
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

/// 충전 데이터 수집 및 저장을 담당하는 클래스
/// 네이티브 레벨에서 배터리 정보를 수집하고 SQLite 데이터베이스에 저장합니다.
class ChargingDataCollector(private val context: Context) {
    
    companion object {
        private const val DATABASE_NAME = "battery_history.db"
        private const val TABLE_NAME = "battery_history"
        private const val TAG = "ChargingDataCollector"
        
        // 데이터베이스 경로는 Flutter의 getApplicationDocumentsDirectory()와 동일하게 설정
        // Flutter의 path_provider는 Android에서 app_flutter 디렉토리를 사용
        // 경로: /data/data/com.example.batterypal/app_flutter/battery_history.db
        private fun getDatabasePath(context: Context): String {
            // Flutter의 path_provider가 사용하는 경로
            // Android에서는 app_flutter 디렉토리 사용
            val filesDir = context.filesDir
            val appFlutterDir = File(filesDir.parent, "app_flutter")
            
            // app_flutter 디렉토리가 없으면 생성
            if (!appFlutterDir.exists()) {
                appFlutterDir.mkdirs()
            }
            
            return File(appFlutterDir, DATABASE_NAME).absolutePath
        }
    }
    
    private var database: SQLiteDatabase? = null
    
    /// 데이터베이스 연결 열기
    private fun openDatabase(): SQLiteDatabase? {
        if (database?.isOpen == true) {
            return database
        }
        
        try {
            val dbPath = getDatabasePath(context)
            Log.d(TAG, "데이터베이스 경로: $dbPath")
            
            // 데이터베이스 파일이 없으면 생성
            val dbFile = File(dbPath)
            if (!dbFile.exists()) {
                Log.w(TAG, "데이터베이스 파일이 없습니다. Flutter에서 먼저 생성해야 합니다.")
                // 데이터베이스 파일이 없으면 생성하지 않고 null 반환
                // Flutter 앱이 먼저 실행되어 데이터베이스를 생성해야 함
                return null
            }
            
            database = SQLiteDatabase.openDatabase(
                dbPath,
                null,
                SQLiteDatabase.OPEN_READWRITE
            )
            
            // 테이블이 없으면 생성 (안전장치)
            ensureTableExists()
            
            Log.d(TAG, "데이터베이스 연결 성공")
            return database
        } catch (e: Exception) {
            Log.e(TAG, "데이터베이스 연결 실패", e)
            return null
        }
    }
    
    /// 테이블 존재 확인 및 생성
    private fun ensureTableExists() {
        val db = database ?: return
        
        try {
            // 테이블이 존재하는지 확인
            val cursor = db.rawQuery(
                "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
                arrayOf(TABLE_NAME)
            )
            
            val tableExists = cursor.count > 0
            cursor.close()
            
            if (!tableExists) {
                Log.w(TAG, "테이블이 없습니다. Flutter에서 먼저 생성해야 합니다.")
                // 테이블 생성은 Flutter의 SchemaManager에서 처리
                // 여기서는 생성하지 않음
            }
        } catch (e: Exception) {
            Log.e(TAG, "테이블 확인 실패", e)
        }
    }
    
    /// 배터리 정보 수집 및 저장
    fun collectAndSaveBatteryData(): Boolean {
        try {
            val db = openDatabase() ?: return false
            
            val batteryIntent = context.registerReceiver(
                null,
                android.content.IntentFilter(android.content.Intent.ACTION_BATTERY_CHANGED)
            ) ?: return false
            
            val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            
            // 배터리 정보 수집
            val level = batteryIntent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            val scale = batteryIntent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
            val batteryPercent = if (level != -1 && scale != -1 && scale > 0) {
                (level * 100.0) / scale
            } else -1.0
            
            val plugged = batteryIntent.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1)
            val status = batteryIntent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
            val temperature = batteryIntent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1)
            val voltage = batteryIntent.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1)
            
            // 충전 타입
            val chargingType = when (plugged) {
                BatteryManager.BATTERY_PLUGGED_AC -> "AC"
                BatteryManager.BATTERY_PLUGGED_USB -> "USB"
                BatteryManager.BATTERY_PLUGGED_WIRELESS -> "Wireless"
                else -> "Unknown"
            }
            
            // 충전 전류 (API 21+)
            var currentNow = -1
            var chargingCurrent = -1
            try {
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
                    currentNow = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
                    chargingCurrent = if (currentNow != -1) {
                        kotlin.math.abs(currentNow / 1000) // mA 단위로 변환
                    } else -1
                }
            } catch (e: Exception) {
                Log.w(TAG, "충전 전류 가져오기 실패: ${e.message}")
            }
            
            // 배터리 용량 및 건강도
            var capacity = -1
            var health = -1
            try {
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
                    capacity = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
                }
                health = batteryIntent.getIntExtra(BatteryManager.EXTRA_HEALTH, -1)
            } catch (e: Exception) {
                Log.w(TAG, "배터리 용량/건강도 가져오기 실패: ${e.message}")
            }
            
            val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING || 
                            status == BatteryManager.BATTERY_STATUS_FULL ||
                            plugged != 0
            
            val timestamp = System.currentTimeMillis()
            val temperatureCelsius = if (temperature != -1) temperature / 10.0 else -1.0
            
            // Phase 5: 중복 방지 최적화 - 인덱스를 활용한 빠른 중복 체크
            // 타임스탬프를 초 단위로 반올림하여 중복 체크 (1초 이내의 데이터는 중복으로 간주)
            val timestampSeconds = timestamp / 1000
            val minTimestamp = (timestampSeconds * 1000 - 1000)
            val maxTimestamp = (timestampSeconds * 1000 + 1000)
            
            // Phase 5: EXISTS 쿼리 사용 (COUNT보다 빠름)
            val duplicateCheck = db.rawQuery(
                "SELECT 1 FROM $TABLE_NAME WHERE timestamp >= ? AND timestamp <= ? LIMIT 1",
                arrayOf(minTimestamp.toString(), maxTimestamp.toString())
            )
            
            val isDuplicate = duplicateCheck.count > 0
            duplicateCheck.close()
            
            if (isDuplicate) {
                Log.d(TAG, "배터리 데이터 중복 감지 - 타임스탬프: $timestamp, 스킵")
                return true // 중복이지만 성공으로 처리 (이미 데이터가 있음)
            }
            
            // 데이터베이스에 저장
            val values = android.content.ContentValues().apply {
                put("timestamp", timestamp)
                put("level", batteryPercent)
                put("state", status)
                put("temperature", temperatureCelsius)
                put("voltage", voltage)
                put("capacity", capacity)
                put("health", health)
                put("charging_type", chargingType)
                put("charging_current", chargingCurrent)
                put("is_charging", if (isCharging) 1 else 0)
                put("is_app_in_foreground", 0) // 백그라운드에서 수집
                put("collection_method", "background_workmanager") // 수집 방법 표시
                put("data_quality", 1.0) // 기본 품질
                put("created_at", timestamp / 1000) // 초 단위
            }
            
            val rowId = db.insert(TABLE_NAME, null, values)
            
            if (rowId != -1L) {
                Log.d(TAG, "배터리 데이터 저장 성공: ${batteryPercent}%, ${chargingCurrent}mA, ${chargingType}")
                return true
            } else {
                Log.e(TAG, "배터리 데이터 저장 실패")
                return false
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "배터리 데이터 수집 및 저장 실패", e)
            return false
        }
    }
    
    /// 데이터베이스 연결 닫기
    fun close() {
        try {
            database?.close()
            database = null
            Log.d(TAG, "데이터베이스 연결 닫기 완료")
        } catch (e: Exception) {
            Log.e(TAG, "데이터베이스 연결 닫기 실패", e)
        }
    }
}

