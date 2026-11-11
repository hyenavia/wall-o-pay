package com.example.wall_o_pay

import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
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
        setupQuickShortcuts()
        handleSendIntent(intent)
    }

    private fun setupQuickShortcuts() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N_MR1) return
        try {
            val shortcutManager = getSystemService(ShortcutManager::class.java) ?: return
            val icon = Icon.createWithResource(this, R.mipmap.ic_launcher)

            val expenseShortcut = ShortcutInfo.Builder(this, "add_expense")
                .setShortLabel(getString(R.string.shortcut_expense_short))
                .setLongLabel(getString(R.string.shortcut_expense_long))
                .setIcon(icon)
                .setRank(0)
                .setIntent(
                    Intent(this, MainActivity::class.java).apply {
                        action = "com.example.wall_o_pay.SHORTCUT_EXPENSE"
                    }
                )
                .build()

            val incomeShortcut = ShortcutInfo.Builder(this, "add_income")
                .setShortLabel(getString(R.string.shortcut_income_short))
                .setLongLabel(getString(R.string.shortcut_income_long))
                .setIcon(icon)
                .setRank(1)
                .setIntent(
                    Intent(this, MainActivity::class.java).apply {
                        action = "com.example.wall_o_pay.SHORTCUT_INCOME"
                    }
                )
                .build()

            val transferShortcut = ShortcutInfo.Builder(this, "transfer_funds")
                .setShortLabel(getString(R.string.shortcut_transfer_short))
                .setLongLabel(getString(R.string.shortcut_transfer_long))
                .setIcon(icon)
                .setRank(2)
                .setIntent(
                    Intent(this, MainActivity::class.java).apply {
                        action = "com.example.wall_o_pay.SHORTCUT_TRANSFER"
                    }
                )
                .build()

            shortcutManager.dynamicShortcuts = listOf(expenseShortcut, incomeShortcut, transferShortcut)
        } catch (e: Exception) {
            e.printStackTrace()
        }
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
        if (intent == null) return
        when (intent.action) {
            "com.example.wall_o_pay.QUICK_WIDGET_INCOME" -> {
                latestSharedData = mapOf("shortcutType" to "income")
                return
            }
            "com.example.wall_o_pay.QUICK_WIDGET_EXPENSE" -> {
                latestSharedData = mapOf("shortcutType" to "expense")
                return
            }
            "com.example.wall_o_pay.QUICK_WIDGET_TRANSFER" -> {
                latestSharedData = mapOf("shortcutType" to "transfer")
                return
            }
            "com.example.wall_o_pay.SHORTCUT_EXPENSE" -> {
                latestSharedData = mapOf("shortcutType" to "expense")
                return
            }
            "com.example.wall_o_pay.SHORTCUT_INCOME" -> {
                latestSharedData = mapOf("shortcutType" to "income")
                return
            }
            "com.example.wall_o_pay.SHORTCUT_TRANSFER" -> {
                latestSharedData = mapOf("shortcutType" to "transfer")
                return
            }
        }
        if (intent.action != Intent.ACTION_SEND) return

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

        // Channel for Quick Finance Widget data sync
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.wall_o_pay/widget").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateWidgetData" -> {
                        val balance = call.argument<Number>("balance")?.toLong() ?: 0L
                        val hideBalance = call.argument<Boolean>("hideBalance") ?: false
                        val prefs = getSharedPreferences("quick_finance_widget", MODE_PRIVATE)
                        prefs.edit()
                            .putLong("total_balance", balance)
                            .putBoolean("hide_balance", hideBalance)
                            .apply()
                        QuickFinanceWidgetProvider.updateAllWidgets(this@MainActivity)
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
