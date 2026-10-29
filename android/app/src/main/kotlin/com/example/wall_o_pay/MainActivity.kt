package com.example.wall_o_pay

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.wall_o_pay/notifications"

    companion object {
        private const val UPDATE_CHANNEL_ID = "wall_o_pay_updates"
        private const val UPDATE_NOTIFICATION_ID = 202610
        private const val NOTIF_PERMISSION_REQUEST_CODE = 1002
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        createNotificationChannels()

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
                "openAppSettings" -> {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.fromParts("package", packageName, null)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    result.success(true)
                }
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    if (!url.isNullOrEmpty()) {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.error("INVALID_URL", "URL is null or empty", null)
                    }
                }
                "areNotificationsEnabled" -> {
                    val enabled = NotificationManagerCompat.from(this).areNotificationsEnabled()
                    result.success(enabled)
                }
                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        val granted = ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.POST_NOTIFICATIONS
                        ) == PackageManager.PERMISSION_GRANTED
                        if (!granted) {
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                                NOTIF_PERMISSION_REQUEST_CODE
                            )
                        }
                        result.success(granted)
                    } else {
                        result.success(true)
                    }
                }
                "postUpdateNotification" -> {
                    val title = call.argument<String>("title") ?: "Wall o' Pay Update"
                    val body = call.argument<String>("body") ?: "A new update is available."
                    val downloadUrl = call.argument<String>("downloadUrl") ?: "https://github.com/hyenavia/wall-o-pay/releases/latest"
                    val actionText = call.argument<String>("actionText") ?: "Download"

                    val posted = postUpdateNotification(title, body, downloadUrl, actionText)
                    result.success(posted)
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

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "App Updates"
            val descriptionText = "Notifications for new Wall o' Pay updates and releases"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(UPDATE_CHANNEL_ID, name, importance).apply {
                description = descriptionText
                enableVibration(true)
                setShowBadge(true)
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun postUpdateNotification(title: String, body: String, downloadUrl: String, actionText: String): Boolean {
        createNotificationChannels()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    NOTIF_PERMISSION_REQUEST_CODE
                )
                return false
            }
        }

        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(downloadUrl)).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val pendingIntent = PendingIntent.getActivity(this, 0, intent, flags)

        val builder = NotificationCompat.Builder(this, UPDATE_CHANNEL_ID)
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_RECOMMENDATION)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .addAction(android.R.drawable.stat_sys_download, actionText, pendingIntent)

        val notificationManager = NotificationManagerCompat.from(this)
        try {
            notificationManager.notify(UPDATE_NOTIFICATION_ID, builder.build())
            return true
        } catch (e: SecurityException) {
            return false
        }
    }
}
