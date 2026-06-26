package com.mirarrapp.Left

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetPlugin
import java.io.File
import java.util.Calendar
import android.util.Log

class LeftWidgetProvider : HomeWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        val action = intent.action
        Log.d("LeftWidget", "onReceive: Received broadcast intent action: $action")
        
        // Listen for system date/time change broadcasts
        if (action == Intent.ACTION_DATE_CHANGED || 
            action == Intent.ACTION_TIME_CHANGED || 
            action == Intent.ACTION_TIMEZONE_CHANGED
        ) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, LeftWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            
            Log.d("LeftWidget", "onReceive: Date/Time changed. Active widgets count: ${appWidgetIds.size}")
            
            // Trigger update manually for all active widgets
            val prefs = HomeWidgetPlugin.getData(context)
            onUpdate(context, appWidgetManager, appWidgetIds, prefs)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        Log.d("LeftWidget", "onUpdate: Triggered. Active widgets count: ${appWidgetIds.size}")
        val calendar = Calendar.getInstance()
        val currentDayOfYear = calendar.get(Calendar.DAY_OF_YEAR)
        val currentYear = calendar.get(Calendar.YEAR)
        val currentDayKey = "${currentYear}_${currentDayOfYear}"
        Log.d("LeftWidget", "onUpdate: currentDayKey = $currentDayKey")

        for (appWidgetId in appWidgetIds) {
            Log.d("LeftWidget", "onUpdate: Redrawing widget $appWidgetId instantly with current image path")
            // Instantly redraw the widget with the current image
            updateAppWidget(context, appWidgetManager, appWidgetId, widgetData)
            
            // Read the last day this widget was successfully updated in the background
            val lastUpdatedDay = widgetData.getString("widget_last_update_day_$appWidgetId", "")
            Log.d("LeftWidget", "onUpdate: widget $appWidgetId lastUpdatedDay = $lastUpdatedDay")
            
            // Only trigger background rendering if the day has actually changed
            // This breaks the infinite loop between updateWidget and onUpdate
            if (currentDayKey != lastUpdatedDay) {
                try {
                    // Mark as updated for the current day immediately to prevent multiple rapid triggers
                    widgetData.edit().putString("widget_last_update_day_$appWidgetId", currentDayKey).apply()
                    Log.d("LeftWidget", "onUpdate: Day changed! Enqueuing WorkManager task directly for widget $appWidgetId")

                    // Clear any blocked/stuck unique work queue from previous failures to ensure immediate execution
                    try {
                        androidx.work.WorkManager.getInstance(context).cancelUniqueWork("home_widget_background")
                        Log.d("LeftWidget", "onUpdate: Cancelled unique work 'home_widget_background' to clear queue")
                    } catch (e: Exception) {
                        Log.e("LeftWidget", "onUpdate: Error cancelling unique work", e)
                    }

                    val backgroundIntent = Intent().apply {
                        data = Uri.parse("left://updateWidget?widgetId=$appWidgetId")
                    }
                    
                    // Call the companion object method of the worker directly, bypassing the BroadcastReceiver
                    es.antonborri.home_widget.HomeWidgetBackgroundWorker.enqueueWork(context, backgroundIntent)
                    Log.d("LeftWidget", "onUpdate: Successfully enqueued work directly via HomeWidgetBackgroundWorker")
                } catch (e: Exception) {
                    Log.e("LeftWidget", "onUpdate: Error enqueuing background work for widget $appWidgetId", e)
                }
            } else {
                Log.d("LeftWidget", "onUpdate: Day has not changed for widget $appWidgetId. Skipping background render.")
            }
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            widgetData: SharedPreferences = HomeWidgetPlugin.getData(context)
        ) {
            Log.d("LeftWidget", "updateAppWidget: Running for widget $appWidgetId")
            val views = RemoteViews(context.packageName, R.layout.left_widget_layout)
            
            // Get image path and screen ID for this widget ID from the shared widget preferences
            val imagePath = widgetData.getString("widget_image_path_$appWidgetId", null)
            val screenId = widgetData.getString("widget_screen_$appWidgetId", null)
            Log.d("LeftWidget", "updateAppWidget: widget $appWidgetId imagePath = $imagePath, screenId = $screenId")

            if (imagePath != null) {
                val file = File(imagePath)
                if (file.exists()) {
                    Log.d("LeftWidget", "updateAppWidget: File exists. Decoding bitmap: ${file.absolutePath}")
                    val bitmap = BitmapFactory.decodeFile(file.absolutePath)
                    if (bitmap != null) {
                        views.setImageViewBitmap(R.id.widget_image, bitmap)
                        Log.d("LeftWidget", "updateAppWidget: Bitmap set successfully.")
                    } else {
                        Log.e("LeftWidget", "updateAppWidget: Failed to decode bitmap! Showing placeholder.")
                        views.setImageViewResource(R.id.widget_image, R.drawable.widget_placeholder)
                    }

                    // Clean up older widget images to prevent disk accumulation
                    try {
                        val parentDir = file.parentFile
                        if (parentDir != null && parentDir.exists()) {
                            val prefix = "widget_image_${appWidgetId}_"
                            val files = parentDir.listFiles { _, name ->
                                name.startsWith(prefix) && name != file.name
                            }
                            if (files != null && files.isNotEmpty()) {
                                Log.d("LeftWidget", "updateAppWidget: Found ${files.size} older widget images. Cleaning up...")
                                for (oldFile in files) {
                                    val deleted = oldFile.delete()
                                    Log.d("LeftWidget", "updateAppWidget: Deleted old image ${oldFile.name}: $deleted")
                                }
                            }
                        }
                    } catch (e: Exception) {
                        Log.e("LeftWidget", "updateAppWidget: Error cleaning up older files", e)
                    }
                } else {
                    Log.w("LeftWidget", "updateAppWidget: File does not exist! Showing placeholder.")
                    views.setImageViewResource(R.id.widget_image, R.drawable.widget_placeholder)
                }
            } else {
                Log.w("LeftWidget", "updateAppWidget: imagePath is null! Showing placeholder.")
                views.setImageViewResource(R.id.widget_image, R.drawable.widget_placeholder)
            }

            // Create intent to open MainActivity
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("screen_id", screenId)
                data = Uri.parse("left://widget/$appWidgetId")
            }

            val pendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_image, pendingIntent)

            // Notify manager to update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
            Log.d("LeftWidget", "updateAppWidget: Widget $appWidgetId updated on screen.")
        }
    }
}
