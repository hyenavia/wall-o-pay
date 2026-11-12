package com.example.wall_o_pay

import android.appwidget.AppWidgetManager
import android.content.ComponentName
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
    companion object {
        const val EXTRA_WIDGET_ROUTE = "widget_route"
    }

    private val CHANNEL = "com.example.wall_o_pay/notifications"
    private val SHARE_CHANNEL = "com.example.wall_o_pay/share"

    private var latestSharedData: Map<String, Any?>? = null
    private var pendingWidgetRoute: String? = null
    private var shareChannel: MethodChannel? = null
    private var widgetChannel: MethodChannel? = null

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
        pendingWidgetRoute?.let {
            widgetChannel?.invokeMethod("onWidgetRoute", it)
        }
    }

    private fun handleSendIntent(intent: Intent?) {
        if (intent == null) return
        val widgetRoute = intent.getStringExtra(EXTRA_WIDGET_ROUTE)
        if (!widgetRoute.isNullOrBlank()) {
            pendingWidgetRoute = widgetRoute
            return
        }
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

        // Channel for Quick Finance & Ecosystem Widget data sync
        widgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.wall_o_pay/widget").apply {
            setMethodCallHandler { call, result ->
                val prefs = getSharedPreferences(WidgetDatabaseHelper.PREFS_NAME, MODE_PRIVATE)
                when (call.method) {
                    "updateWidgetData" -> {
                        val balance = call.argument<Number>("balance")?.toLong() ?: 0L
                        val hideBalance = call.argument<Boolean>("hideBalance") ?: false
                        val locale = call.argument<String>("locale")
                        val editor = prefs.edit()
                            .putBoolean(WidgetDatabaseHelper.KEY_HIDE_BALANCE, hideBalance)
                        if (hideBalance) {
                            editor.remove(WidgetDatabaseHelper.KEY_BALANCE)
                        } else {
                            editor.putLong(WidgetDatabaseHelper.KEY_BALANCE, balance)
                        }
                        if (locale == "id" || locale == "en") {
                            editor.putString(WidgetDatabaseHelper.KEY_LOCALE, locale)
                        }
                        editor.apply()
                        WidgetSnapshotStore.refreshAllWidgets(this@MainActivity)
                        WidgetMidnightWorker.scheduleIfNeeded(this@MainActivity)
                        result.success(true)
                    }
                    "updateWidgetSnapshot" -> {
                        val balance = call.argument<Number>("balance")?.toLong() ?: 0L
                        val hideBalance = call.argument<Boolean>("hideBalance") ?: false
                        val locale = call.argument<String>("locale")
                        val dailyAllowance = call.argument<Number>("dailyAllowance")?.toLong() ?: 0L
                        val todayExpense = call.argument<Number>("todayExpense")?.toLong() ?: 0L
                        val tier = call.argument<String>("tier") ?: "safe"
                        val fundingBasis = call.argument<String>("fundingBasis") ?: "none"
                        val daysLeft = call.argument<Number>("daysLeft")?.toInt() ?: 0
                        val periodStartMs = call.argument<Number>("periodStartMs")?.toLong() ?: 0L
                        val periodEndMs = call.argument<Number>("periodEndMs")?.toLong() ?: 0L
                        val dateYmd = call.argument<String>("dateYmd") ?: WidgetSnapshotStore.todayYmd()
                        val updatedAtMs = call.argument<Number>("updatedAtMs")?.toLong() ?: System.currentTimeMillis()

                        val budgetHasConfig = call.argument<Boolean>("budgetHasConfig") ?: false
                        val totalBudget = call.argument<Number>("totalBudget")?.toLong() ?: 0L
                        val budgetSpent = call.argument<Number>("budgetSpent")?.toLong() ?: 0L
                        val budgetPct = call.argument<Number>("budgetPct")?.toInt() ?: 0
                        val budgetAlertLevel = call.argument<String>("budgetAlertLevel") ?: "none"
                        val budgetCategoriesJson = call.argument<String>("budgetCategoriesJson") ?: "[]"

                        val goalsJson = call.argument<String>("goalsJson") ?: "[]"
                        val goalsActiveCount = call.argument<Number>("goalsActiveCount")?.toInt() ?: 0
                        val goalsDoneCount = call.argument<Number>("goalsDoneCount")?.toInt() ?: 0
                        val billsJson = call.argument<String>("billsJson") ?: "[]"
                        val billsDueCount = call.argument<Number>("billsDueCount")?.toInt() ?: 0
                        val billsDueAmount = call.argument<Number>("billsDueAmount")?.toLong() ?: 0L

                        WidgetSnapshotStore.saveSnapshot(
                            context = this@MainActivity,
                            balance = balance,
                            hideBalance = hideBalance,
                            locale = locale,
                            dailyAllowance = dailyAllowance,
                            todayExpense = todayExpense,
                            tier = tier,
                            fundingBasis = fundingBasis,
                            daysLeft = daysLeft,
                            periodStartMs = periodStartMs,
                            periodEndMs = periodEndMs,
                            dateYmd = dateYmd,
                            updatedAtMs = updatedAtMs,
                            budgetHasConfig = budgetHasConfig,
                            totalBudget = totalBudget,
                            budgetSpent = budgetSpent,
                            budgetPct = budgetPct,
                            budgetAlertLevel = budgetAlertLevel,
                            budgetCategoriesJson = budgetCategoriesJson,
                            goalsJson = goalsJson,
                            goalsActiveCount = goalsActiveCount,
                            goalsDoneCount = goalsDoneCount,
                            billsJson = billsJson,
                            billsDueCount = billsDueCount,
                            billsDueAmount = billsDueAmount,
                        )
                        WidgetSnapshotStore.refreshAllWidgets(this@MainActivity)
                        WidgetMidnightWorker.scheduleIfNeeded(this@MainActivity)
                        result.success(true)
                    }
                    "consumeNativeHideBalance" -> {
                        result.success(WidgetSnapshotStore.consumeNativeHideBalancePending(this@MainActivity))
                    }
                    "consumeNativeDbDirty" -> {
                        val isDirty = prefs.getBoolean(WidgetDatabaseHelper.KEY_NATIVE_DB_DIRTY, false)
                        if (isDirty) {
                            prefs.edit().putBoolean(WidgetDatabaseHelper.KEY_NATIVE_DB_DIRTY, false).apply()
                        }
                        result.success(isDirty)
                    }
                    "getPendingWidgetRoute" -> {
                        result.success(pendingWidgetRoute)
                    }
                    "clearWidgetRoute" -> {
                        pendingWidgetRoute = null
                        result.success(true)
                    }
                    "getActiveWidgetCounts" -> {
                        val manager = AppWidgetManager.getInstance(this@MainActivity)
                        val counts = mapOf(
                            "quick_finance" to manager.getAppWidgetIds(
                                ComponentName(this@MainActivity, QuickFinanceWidgetProvider::class.java)
                            ).size,
                            "daily_pulse" to manager.getAppWidgetIds(
                                ComponentName(this@MainActivity, DailyPulseWidgetProvider::class.java)
                            ).size,
                            "quick_action" to manager.getAppWidgetIds(
                                ComponentName(this@MainActivity, QuickActionWidgetProvider::class.java)
                            ).size,
                            "favorite_templates" to manager.getAppWidgetIds(
                                ComponentName(this@MainActivity, FavoriteTemplatesWidgetProvider::class.java)
                            ).size,
                            "budget_guardrail" to manager.getAppWidgetIds(
                                ComponentName(this@MainActivity, BudgetGuardrailWidgetProvider::class.java)
                            ).size,
                            "goals_bills" to manager.getAppWidgetIds(
                                ComponentName(this@MainActivity, GoalsAndBillsWidgetProvider::class.java)
                            ).size,
                        )
                        result.success(counts)
                    }
                    "isPinWidgetSupported" -> {
                        val supported = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            AppWidgetManager.getInstance(this@MainActivity).isRequestPinAppWidgetSupported
                        } else {
                            false
                        }
                        result.success(supported)
                    }
                    "requestPinWidget" -> {
                        val key = call.argument<String>("key")
                        val component = when (key) {
                            "quick_finance" -> ComponentName(this@MainActivity, QuickFinanceWidgetProvider::class.java)
                            "daily_pulse" -> ComponentName(this@MainActivity, DailyPulseWidgetProvider::class.java)
                            "quick_action" -> ComponentName(this@MainActivity, QuickActionWidgetProvider::class.java)
                            "favorite_templates" -> ComponentName(this@MainActivity, FavoriteTemplatesWidgetProvider::class.java)
                            "budget_guardrail" -> ComponentName(this@MainActivity, BudgetGuardrailWidgetProvider::class.java)
                            "goals_bills" -> ComponentName(this@MainActivity, GoalsAndBillsWidgetProvider::class.java)
                            else -> null
                        }
                        if (component == null) {
                            result.success(false)
                        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val manager = AppWidgetManager.getInstance(this@MainActivity)
                            val pinned = if (manager.isRequestPinAppWidgetSupported) {
                                manager.requestPinAppWidget(component, null, null)
                            } else {
                                false
                            }
                            result.success(pinned)
                        } else {
                            result.success(false)
                        }
                    }
                    "getWidgetGlassStyle" -> {
                        result.success(WidgetSnapshotStore.getGlassStyle(this@MainActivity))
                    }
                    "setWidgetGlassStyle" -> {
                        val style = call.argument<String>("style") ?: "deep"
                        result.success(WidgetSnapshotStore.setGlassStyle(this@MainActivity, style))
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
