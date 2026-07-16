package com.example.homematch

import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.example.homematch/security"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAdbEnabled" -> {
                    val adbEnabled = try {
                        val isAdbEnabled = Settings.Global.getInt(
                            contentResolver,
                            Settings.Global.ADB_ENABLED,
                            0
                        ) == 1
                        
                        val isAdbSecure = Settings.Secure.getInt(
                            contentResolver,
                            "adb_enabled",
                            0
                        ) == 1

                        val finalResult = isAdbEnabled || isAdbSecure
                        android.util.Log.d("HomeMatchSecurity", "ADB Check: $finalResult (Global: $isAdbEnabled, Secure: $isAdbSecure)")
                        finalResult
                    } catch (t: Throwable) {
                        android.util.Log.e("HomeMatchSecurity", "ADB Check Error", t)
                        false
                    }
                    result.success(adbEnabled)
                }
                else -> result.notImplemented()
            }
        }
    }
}
