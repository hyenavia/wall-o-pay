package com.example.wall_o_pay

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
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

        // Channel untuk Sistem / Utilitas Aplikasi
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
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
                "setSecureScreen" -> {
                    val secure = call.argument<Boolean>("secure") ?: false
                    if (secure) {
                        window.setFlags(
                            WindowManager.LayoutParams.FLAG_SECURE,
                            WindowManager.LayoutParams.FLAG_SECURE
                        )
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(true)
                }
                "getAppVersion" -> {
                    try {
                        val pInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            packageManager.getPackageInfo(packageName, android.content.pm.PackageManager.PackageInfoFlags.of(0))
                        } else {
                            @Suppress("DEPRECATION")
                            packageManager.getPackageInfo(packageName, 0)
                        }
                        result.success(pInfo.versionName)
                    } catch (e: Exception) {
                        result.error("VERSION_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
