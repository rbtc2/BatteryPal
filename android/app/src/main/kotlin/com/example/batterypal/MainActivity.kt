package com.example.batterypal

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.batterypal/battery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getBatteryTemperature(): Double {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val batteryIntent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val temperature = batteryIntent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1) ?: -1
        return if (temperature != -1) temperature / 10.0 else -1.0 // 온도는 0.1도 단위로 저장됨
    }

    private fun getBatteryVoltage(): Int {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val batteryIntent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        return batteryIntent?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1) ?: -1
    }

    private fun getBatteryCapacity(): Int {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val batteryIntent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        return batteryIntent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
    }

    private fun getBatteryHealth(): Int {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val batteryIntent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        return batteryIntent?.getIntExtra(BatteryManager.EXTRA_HEALTH, -1) ?: -1
    }
}
