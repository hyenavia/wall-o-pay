package com.example.wall_o_pay

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.wall_o_pay/notifications"
    private val SHARE_CHANNEL = "com.example.wall_o_pay/share"

    private var latestSharedData: Map<String, Any?>? = null
    private var shareChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleSendIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleSendIntent(intent)
        latestSharedData?.let {
            shareChannel?.invokeMethod("onShareReceived", it)
        }
    }

    private fun handleSendIntent(intent: Intent?) {
        if (intent == null || intent.action != Intent.ACTION_SEND) return

        val type = intent.type ?: return
        val map = mutableMapOf<String, Any?>()

        // Handle image stream
        if (type.startsWith("image/")) {
            val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
            }

            if (uri != null) {
                try {
                    val receiptsDir = File(filesDir, "shared_receipts").apply { mkdirs() }
                    val file = File(receiptsDir, "receipt_${System.currentTimeMillis()}.jpg")
                    contentResolver.openInputStream(uri)?.use { input ->
                        file.outputStream().use { output ->
                            input.copyTo(output)
                        }
                    }
                    if (file.exists() && file.length() > 0) {
                        map["imagePath"] = file.absolutePath
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }

        // Handle text / caption
        val text = intent.getStringExtra(Intent.EXTRA_TEXT) ?: intent.getStringExtra(Intent.EXTRA_SUBJECT)
        if (!text.isNullOrBlank()) {
            map["text"] = text
        }

        if (map.isNotEmpty()) {
            latestSharedData = map
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Channel untuk Share Intent (Struk / Transaksi dari aplikasi lain)
        shareChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSharedData" -> {
                        result.success(latestSharedData)
                    }
                    "clearSharedData" -> {
                        latestSharedData = null
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        // Channel untuk Notifikasi Otomatis
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
