package com.mirarrapp.Left

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.mirarrapp.left/widget"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getActiveWidgetIds" -> {
                    val appWidgetManager = AppWidgetManager.getInstance(this)
                    val ids = appWidgetManager.getAppWidgetIds(ComponentName(this, LeftWidgetProvider::class.java))
                    result.success(ids.toList())
                }
                "updateWidget" -> {
                    val widgetId = call.argument<Int>("widgetId")
                    if (widgetId != null) {
                        val appWidgetManager = AppWidgetManager.getInstance(this)
                        LeftWidgetProvider.updateAppWidget(this, appWidgetManager, widgetId)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "widgetId is null", null)
                    }
                }
                "requestPinWidget" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val appWidgetManager = AppWidgetManager.getInstance(this)
                        val myProvider = ComponentName(this, LeftWidgetProvider::class.java)
                        if (appWidgetManager.isRequestPinAppWidgetSupported) {
                            appWidgetManager.requestPinAppWidget(myProvider, null, null)
                            result.success(true)
                        } else {
                            result.error("NOT_SUPPORTED", "Pinning widgets is not supported on this device", null)
                        }
                    } else {
                        result.error("API_LOW", "Pinning widgets requires Android 8.0 (API 26) or higher", null)
                    }
                }
                "getInitialScreenId" -> {
                    val screenId = intent.getStringExtra("screen_id")
                    intent.removeExtra("screen_id")
                    result.success(screenId)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val screenId = intent.getStringExtra("screen_id")
        if (screenId != null) {
            methodChannel?.invokeMethod("onScreenSelected", screenId)
            intent.removeExtra("screen_id")
        }
    }
}
