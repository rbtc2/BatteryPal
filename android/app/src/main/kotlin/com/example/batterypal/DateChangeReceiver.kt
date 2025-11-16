package com.example.batterypal

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import java.util.Calendar

/// 날짜 변경을 감지하는 독립적인 BroadcastReceiver
/// 앱이 백그라운드에 있거나 완전히 종료된 상태에서도 작동
/// AndroidManifest에 정적으로 등록되어 앱이 완전히 종료되어도 작동
class DateChangeReceiver : BroadcastReceiver() {
    
    companion object {
        private const val PREFS_NAME = "date_change_state"
        private const val KEY_LAST_LOADED_DATE = "last_loaded_date"
        private const val KEY_DATE_CHANGED_FLAG = "date_changed_flag"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_SET,
            Intent.ACTION_TIMEZONE_CHANGED -> {
                handleDateChange(context)
            }
            Intent.ACTION_BOOT_COMPLETED -> {
                // 부팅 완료 시에도 날짜 변경 확인
                handleDateChange(context)
            }
        }
    }
    
    /// 날짜 변경 처리
    private fun handleDateChange(context: Context) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val calendar = Calendar.getInstance()
            val currentDate = "${calendar.get(Calendar.YEAR)}-${String.format("%02d", calendar.get(Calendar.MONTH) + 1)}-${String.format("%02d", calendar.get(Calendar.DAY_OF_MONTH))}"
            
            val lastLoadedDate = prefs.getString(KEY_LAST_LOADED_DATE, null)
            
            // 날짜가 변경되었는지 확인
            if (lastLoadedDate != null && lastLoadedDate != currentDate) {
                Log.d("BatteryPal", "DateChangeReceiver: 날짜 변경 감지 - $lastLoadedDate -> $currentDate")
                
                // 날짜 변경 플래그 설정 (앱이 시작될 때 확인)
                prefs.edit()
                    .putBoolean(KEY_DATE_CHANGED_FLAG, true)
                    .putString(KEY_LAST_LOADED_DATE, currentDate)
                    .apply()
                
                Log.d("BatteryPal", "DateChangeReceiver: 날짜 변경 플래그 설정 완료")
            } else if (lastLoadedDate == null) {
                // 처음 실행 시 현재 날짜 저장
                prefs.edit()
                    .putString(KEY_LAST_LOADED_DATE, currentDate)
                    .apply()
                Log.d("BatteryPal", "DateChangeReceiver: 초기 날짜 저장 - $currentDate")
            }
        } catch (e: Exception) {
            Log.e("BatteryPal", "DateChangeReceiver: 날짜 변경 처리 오류", e)
        }
    }
    
    companion object {
        /// 날짜 변경 플래그 확인 및 초기화
        /// 앱이 시작될 때 호출하여 날짜 변경 여부 확인
        fun checkAndClearDateChangeFlag(context: Context): Boolean {
            return try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val dateChanged = prefs.getBoolean(KEY_DATE_CHANGED_FLAG, false)
                
                if (dateChanged) {
                    // 플래그 초기화
                    prefs.edit()
                        .putBoolean(KEY_DATE_CHANGED_FLAG, false)
                        .apply()
                    Log.d("BatteryPal", "DateChangeReceiver: 날짜 변경 플래그 확인 및 초기화")
                }
                
                dateChanged
            } catch (e: Exception) {
                Log.e("BatteryPal", "DateChangeReceiver: 날짜 변경 플래그 확인 실패", e)
                false
            }
        }
        
        /// 현재 날짜 키 가져오기
        fun getCurrentDateKey(): String {
            val calendar = Calendar.getInstance()
            return "${calendar.get(Calendar.YEAR)}-${String.format("%02d", calendar.get(Calendar.MONTH) + 1)}-${String.format("%02d", calendar.get(Calendar.DAY_OF_MONTH))}"
        }
    }
}

