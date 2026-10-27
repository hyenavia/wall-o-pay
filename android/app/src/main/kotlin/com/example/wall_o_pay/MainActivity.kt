package com.example.wall_o_pay

import android.content.Context
import android.content.Intent
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.wall_o_pay/notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationAccessGranted" -> {
                    val enabledPackages = NotificationManagerCompat.getEnabledListenerPackages(this)
                    result.success(enabledPackages.contains(packageName))
                }
                "openNotificationSettings" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
                "getPendingNotifications" -> {
                    val prefs = getSharedPreferences(
                        TransactionNotificationListenerService.PREFS_NAME,
                        Context.MODE_PRIVATE
                    )
                    val raw = prefs.getString(TransactionNotificationListenerService.KEY_NOTIFICATIONS, "[]") ?: "[]"
                    val jsonArray = JSONArray(raw)
                    val list = mutableListOf<Map<String, Any>>()
                    for (i in 0 until jsonArray.length()) {
                        val obj = jsonArray.getJSONObject(i)
                        val map = mutableMapOf<String, Any>()
                        map["id"] = obj.optString("id")
                        map["package"] = obj.optString("package")
                        map["title"] = obj.optString("title")
                        map["text"] = obj.optString("text")
                        map["timestamp"] = obj.optLong("timestamp")
                        list.add(map)
                    }
                    result.success(list)
                }
                "clearPendingNotifications" -> {
                    val prefs = getSharedPreferences(
                        TransactionNotificationListenerService.PREFS_NAME,
                        Context.MODE_PRIVATE
                    )
                    prefs.edit().putString(TransactionNotificationListenerService.KEY_NOTIFICATIONS, "[]").apply()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
