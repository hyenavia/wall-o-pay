package com.example.wall_o_pay

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

data class PulseSnapshot(
    val dbReady: Boolean,
    val hasSnapshot: Boolean,
    val hideBalance: Boolean,
    val locale: String,
    val totalBalance: Long,
    val dailyAllowance: Long,
    val todayExpense: Long,
    val tier: String,
    val fundingBasis: String,
    val daysLeft: Int,
)

data class BudgetCategoryItem(
    val id: String,
    val name: String,
    val spent: Long,
    val limit: Long,
    val pct: Int,
)

data class BudgetSnapshot(
    val dbReady: Boolean,
    val hasSnapshot: Boolean,
    val hasBudgetConfig: Boolean,
    val hideBalance: Boolean,
    val locale: String,
    val totalBudget: Long,
    val budgetSpent: Long,
    val budgetRemaining: Long,
    val budgetPct: Int,
    val alertLevel: String,
    val daysLeft: Int,
    val categories: List<BudgetCategoryItem>,
)

data class GoalSnapshotItem(
    val id: String,
    val name: String,
    val current: Long,
    val target: Long,
    val pct: Int,
    val remaining: Long,
)

data class BillSnapshotItem(
    val title: String,
    val amount: Long,
    val dueMs: Long,
    val daysUntil: Int,
    val isPending: Boolean,
)

data class GoalsAndBillsSnapshot(
    val dbReady: Boolean,
    val hasSnapshot: Boolean,
    val hideBalance: Boolean,
    val locale: String,
    val goals: List<GoalSnapshotItem>,
    val activeGoalCount: Int,
    val doneGoalCount: Int,
    val selectedGoalIndex: Int,
    val bills: List<BillSnapshotItem>,
    val billsDueCount: Int,
    val billsDueAmount: Long,
)

object WidgetSnapshotStore {
    const val KEY_HAS_SNAPSHOT = "has_snapshot"
    const val KEY_DAILY_ALLOWANCE = "daily_allowance"
    const val KEY_TODAY_EXPENSE = "today_expense"
    const val KEY_PULSE_TIER = "pulse_tier"
    const val KEY_PULSE_BASIS = "pulse_basis"
    const val KEY_DAYS_LEFT = "days_left"
    const val KEY_PERIOD_START_MS = "period_start_ms"
    const val KEY_PERIOD_END_MS = "period_end_ms"
    const val KEY_SNAPSHOT_DATE_YMD = "snapshot_date_ymd"
    const val KEY_SNAPSHOT_UPDATED_MS = "snapshot_updated_ms"
    const val KEY_NATIVE_HIDE_PENDING = "native_hide_balance_pending"

    const val KEY_BUDGET_HAS_CONFIG = "budget_has_config"
    const val KEY_TOTAL_BUDGET = "budget_total"
    const val KEY_BUDGET_SPENT = "budget_spent"
    const val KEY_BUDGET_PCT = "budget_pct"
    const val KEY_BUDGET_ALERT_LEVEL = "budget_alert_level"
    const val KEY_BUDGET_CATEGORIES_JSON = "budget_categories_json"

    const val KEY_GOALS_JSON = "goals_json"
    const val KEY_GOALS_ACTIVE_COUNT = "goals_active_count"
    const val KEY_GOALS_DONE_COUNT = "goals_done_count"
    const val KEY_GOALS_SELECTED_INDEX = "goals_selected_index"
    const val KEY_BILLS_JSON = "bills_json"
    const val KEY_BILLS_DUE_COUNT = "bills_due_count"
    const val KEY_BILLS_DUE_AMOUNT = "bills_due_amount"
    const val KEY_GLASS_STYLE = "widget_glass_style"

    fun getGlassStyle(context: Context): String {
        val prefs = context.getSharedPreferences(WidgetDatabaseHelper.PREFS_NAME, Context.MODE_PRIVATE)
        return when (prefs.getString(KEY_GLASS_STYLE, "deep")) {
            "frosted", "clear" -> prefs.getString(KEY_GLASS_STYLE, "deep") ?: "deep"
            else -> "deep"
        }
    }

    fun setGlassStyle(context: Context, style: String): String {
        val normalized = when (style) {
            "frosted", "clear" -> style
            else -> "deep"
        }
        val prefs = context.getSharedPreferences(WidgetDatabaseHelper.PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_GLASS_STYLE, normalized).apply()
        refreshAllWidgets(context)
        return normalized
    }

    fun resolveBackgroundRes(context: Context, isActionBar: Boolean = false): Int {
        return when (getGlassStyle(context)) {
            "frosted" -> if (isActionBar) R.drawable.widget_action_bar_bg_frosted else R.drawable.widget_background_frosted
            "clear" -> if (isActionBar) R.drawable.widget_action_bar_bg_clear else R.drawable.widget_background_clear
            else -> if (isActionBar) R.drawable.widget_action_bar_bg else R.drawable.widget_background
        }
    }

    fun todayYmd(): String {
        val fmt = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        return fmt.format(Date())
    }

    fun saveSnapshot(
        context: Context,
        balance: Long,
        hideBalance: Boolean,
        locale: String?,
        dailyAllowance: Long,
        todayExpense: Long,
        tier: String,
        fundingBasis: String,
        daysLeft: Int,
        periodStartMs: Long,
        periodEndMs: Long,
        dateYmd: String,
        updatedAtMs: Long,
        budgetHasConfig: Boolean = false,
        totalBudget: Long = 0L,
        budgetSpent: Long = 0L,
        budgetPct: Int = 0,
        budgetAlertLevel: String = "none",
        budgetCategoriesJson: String = "[]",
        goalsJson: String = "[]",
        goalsActiveCount: Int = 0,
        goalsDoneCount: Int = 0,
        billsJson: String = "[]",
        billsDueCount: Int = 0,
        billsDueAmount: Long = 0L,
    ) {
        val prefs = context.getSharedPreferences(WidgetDatabaseHelper.PREFS_NAME, Context.MODE_PRIVATE)
        val editor = prefs.edit()
            .putBoolean(KEY_HAS_SNAPSHOT, true)
            .putBoolean(WidgetDatabaseHelper.KEY_HIDE_BALANCE, hideBalance)
            .putString(KEY_PULSE_TIER, normalizeTier(tier))
            .putString(KEY_PULSE_BASIS, fundingBasis)
            .putInt(KEY_DAYS_LEFT, daysLeft.coerceAtLeast(0))
            .putLong(KEY_PERIOD_START_MS, periodStartMs)
            .putLong(KEY_PERIOD_END_MS, periodEndMs)
            .putString(KEY_SNAPSHOT_DATE_YMD, dateYmd)
            .putLong(KEY_SNAPSHOT_UPDATED_MS, updatedAtMs)
            .putBoolean(KEY_BUDGET_HAS_CONFIG, budgetHasConfig)
            .putInt(KEY_BUDGET_PCT, budgetPct.coerceIn(0, 999))
            .putString(KEY_BUDGET_ALERT_LEVEL, normalizeAlertLevel(budgetAlertLevel))
            .putString(KEY_BUDGET_CATEGORIES_JSON, budgetCategoriesJson)
            .putString(KEY_GOALS_JSON, goalsJson)
            .putInt(KEY_GOALS_ACTIVE_COUNT, goalsActiveCount.coerceAtLeast(0))
            .putInt(KEY_GOALS_DONE_COUNT, goalsDoneCount.coerceAtLeast(0))
            .putString(KEY_BILLS_JSON, billsJson)
            .putInt(KEY_BILLS_DUE_COUNT, billsDueCount.coerceAtLeast(0))

        if (hideBalance) {
            editor.remove(WidgetDatabaseHelper.KEY_BALANCE)
            editor.remove(KEY_DAILY_ALLOWANCE)
            editor.remove(KEY_TODAY_EXPENSE)
            editor.remove(KEY_TOTAL_BUDGET)
            editor.remove(KEY_BUDGET_SPENT)
            editor.remove(KEY_BILLS_DUE_AMOUNT)
        } else {
            editor.putLong(WidgetDatabaseHelper.KEY_BALANCE, balance)
            editor.putLong(KEY_DAILY_ALLOWANCE, dailyAllowance.coerceAtLeast(0L))
            editor.putLong(KEY_TODAY_EXPENSE, todayExpense.coerceAtLeast(0L))
            editor.putLong(KEY_TOTAL_BUDGET, totalBudget.coerceAtLeast(0L))
            editor.putLong(KEY_BUDGET_SPENT, budgetSpent.coerceAtLeast(0L))
            editor.putLong(KEY_BILLS_DUE_AMOUNT, billsDueAmount.coerceAtLeast(0L))
        }

        if (locale == "id" || locale == "en") {
            editor.putString(WidgetDatabaseHelper.KEY_LOCALE, locale)
        }
        editor.apply()
    }

    fun loadPulseSnapshot(context: Context): PulseSnapshot {
        val prefs = context.getSharedPreferences(WidgetDatabaseHelper.PREFS_NAME, Context.MODE_PRIVATE)
        val locale = WidgetDatabaseHelper.getLocale(context)
        val hideBalance = prefs.getBoolean(WidgetDatabaseHelper.KEY_HIDE_BALANCE, false)
        val dbReady = WidgetDatabaseHelper.isDatabaseReady(context)
        val hasSnapshot = prefs.getBoolean(KEY_HAS_SNAPSHOT, false)

        val today = todayYmd()
        val savedDate = prefs.getString(KEY_SNAPSHOT_DATE_YMD, null)
        val periodEndMs = prefs.getLong(KEY_PERIOD_END_MS, 0L)

        var daysLeft = prefs.getInt(KEY_DAYS_LEFT, 0).coerceAtLeast(0)
        if (periodEndMs > 0L) {
            daysLeft = computeDaysLeftFromEndMs(periodEndMs)
        } else if (!hasSnapshot) {
            daysLeft = computeRemainingDaysInMonth()
        }

        var todayExpense = if (hideBalance) 0L else prefs.getLong(KEY_TODAY_EXPENSE, 0L).coerceAtLeast(0L)
        var dailyAllowance = if (hideBalance) 0L else prefs.getLong(KEY_DAILY_ALLOWANCE, 0L).coerceAtLeast(0L)
        var tier = normalizeTier(prefs.getString(KEY_PULSE_TIER, "safe"))
        val basis = prefs.getString(KEY_PULSE_BASIS, "none") ?: "none"

        // Midnight rollover fallback when day changes before Flutter app is opened
        if (savedDate != null && savedDate != today && dbReady) {
            val freshTodayExpense = WidgetDatabaseHelper.getTodayExpense(context)
            val editor = prefs.edit()
                .putString(KEY_SNAPSHOT_DATE_YMD, today)
                .putInt(KEY_DAYS_LEFT, daysLeft)
            if (!hideBalance) {
                todayExpense = freshTodayExpense
                editor.putLong(KEY_TODAY_EXPENSE, freshTodayExpense)
                if (tier == "caution" && dailyAllowance > 0L && freshTodayExpense <= dailyAllowance) {
                    tier = "safe"
                    editor.putString(KEY_PULSE_TIER, tier)
                }
            } else {
                editor.remove(KEY_TODAY_EXPENSE)
            }
            editor.apply()
        }

        val totalBalance = if (hideBalance) {
            0L
        } else if (dbReady) {
            WidgetDatabaseHelper.getTotalBalance(context)
                ?: prefs.getLong(WidgetDatabaseHelper.KEY_BALANCE, 0L)
        } else {
            prefs.getLong(WidgetDatabaseHelper.KEY_BALANCE, 0L)
        }

        if (!hideBalance && dbReady && !hasSnapshot) {
            todayExpense = WidgetDatabaseHelper.getTodayExpense(context)
            val safeDays = daysLeft.coerceAtLeast(1)
            dailyAllowance = if (totalBalance > 0L) totalBalance / safeDays else 0L
            tier = when {
                totalBalance <= 0L -> "limit"
                dailyAllowance > 0L && todayExpense > dailyAllowance -> "caution"
                else -> "safe"
            }
        }

        return PulseSnapshot(
            dbReady = dbReady,
            hasSnapshot = hasSnapshot,
            hideBalance = hideBalance,
            locale = locale,
            totalBalance = totalBalance,
            dailyAllowance = dailyAllowance,
            todayExpense = todayExpense,
            tier = tier,
            fundingBasis = basis,
            daysLeft = daysLeft,
        )
    }

    fun loadBudgetSnapshot(context: Context): BudgetSnapshot {
        val prefs = context.getSharedPreferences(WidgetDatabaseHelper.PREFS_NAME, Context.MODE_PRIVATE)
        val locale = WidgetDatabaseHelper.getLocale(context)
        val hideBalance = prefs.getBoolean(WidgetDatabaseHelper.KEY_HIDE_BALANCE, false)
        val dbReady = WidgetDatabaseHelper.isDatabaseReady(context)
        val hasSnapshot = prefs.getBoolean(KEY_HAS_SNAPSHOT, false)
        val hasBudgetConfig = prefs.getBoolean(KEY_BUDGET_HAS_CONFIG, false)

        val periodEndMs = prefs.getLong(KEY_PERIOD_END_MS, 0L)
        val daysLeft = when {
            periodEndMs > 0L -> computeDaysLeftFromEndMs(periodEndMs)
            !hasSnapshot -> computeRemainingDaysInMonth()
            else -> prefs.getInt(KEY_DAYS_LEFT, 0).coerceAtLeast(0)
        }

        val totalBudget = if (hideBalance) 0L else prefs.getLong(KEY_TOTAL_BUDGET, 0L).coerceAtLeast(0L)
        val budgetSpent = if (hideBalance) 0L else prefs.getLong(KEY_BUDGET_SPENT, 0L).coerceAtLeast(0L)
        val budgetRemaining = if (hideBalance) 0L else (totalBudget - budgetSpent)
        val budgetPct = if (!hideBalance && totalBudget > 0L) {
            ((budgetSpent * 100L) / totalBudget).toInt().coerceIn(0, 999)
        } else {
            prefs.getInt(KEY_BUDGET_PCT, 0).coerceIn(0, 999)
        }
        val alertLevel = when {
            !hasBudgetConfig -> "none"
            budgetPct >= 100 -> "over"
            budgetPct >= 85 -> "near"
            else -> normalizeAlertLevel(prefs.getString(KEY_BUDGET_ALERT_LEVEL, "none"))
        }

        val categories = mutableListOf<BudgetCategoryItem>()
        val rawJson = prefs.getString(KEY_BUDGET_CATEGORIES_JSON, "[]") ?: "[]"
        try {
            val arr = JSONArray(rawJson)
            for (i in 0 until minOf(arr.length(), 3)) {
                val obj = arr.optJSONObject(i) ?: continue
                val id = obj.optString("id", "")
                val name = obj.optString("name", "")
                if (name.isBlank()) continue
                val spent = if (hideBalance) 0L else obj.optLong("spent", 0L).coerceAtLeast(0L)
                val limit = if (hideBalance) 0L else obj.optLong("limit", 0L).coerceAtLeast(0L)
                val pct = obj.optInt("pct", 0).coerceIn(0, 999)
                categories.add(
                    BudgetCategoryItem(
                        id = id,
                        name = WidgetDatabaseHelper.localizeLabel(name, locale),
                        spent = spent,
                        limit = limit,
                        pct = pct,
                    )
                )
            }
        } catch (_: Exception) {
            // Keep empty list on malformed JSON
        }

        return BudgetSnapshot(
            dbReady = dbReady,
            hasSnapshot = hasSnapshot,
            hasBudgetConfig = hasBudgetConfig,
            hideBalance = hideBalance,
            locale = locale,
            totalBudget = totalBudget,
            budgetSpent = budgetSpent,
            budgetRemaining = budgetRemaining,
            budgetPct = budgetPct,
            alertLevel = alertLevel,
            daysLeft = daysLeft,
            categories = categories,
        )
    }

    fun loadGoalsAndBillsSnapshot(context: Context): GoalsAndBillsSnapshot {
        val prefs = context.getSharedPreferences(WidgetDatabaseHelper.PREFS_NAME, Context.MODE_PRIVATE)
        val locale = WidgetDatabaseHelper.getLocale(context)
        val hideBalance = prefs.getBoolean(WidgetDatabaseHelper.KEY_HIDE_BALANCE, false)
        val dbReady = WidgetDatabaseHelper.isDatabaseReady(context)
        val hasSnapshot = prefs.getBoolean(KEY_HAS_SNAPSHOT, false)

        val goals = mutableListOf<GoalSnapshotItem>()
        val rawGoals = prefs.getString(KEY_GOALS_JSON, "[]") ?: "[]"
        try {
            val arr = JSONArray(rawGoals)
            for (i in 0 until arr.length()) {
                val obj = arr.optJSONObject(i) ?: continue
                val id = obj.optString("id", "")
                val name = obj.optString("name", "")
                if (name.isBlank()) continue
                val current = if (hideBalance) 0L else obj.optLong("current", 0L).coerceAtLeast(0L)
                val target = if (hideBalance) 0L else obj.optLong("target", 0L).coerceAtLeast(0L)
                val pct = obj.optInt("pct", 0).coerceIn(0, 100)
                val remaining = if (hideBalance) 0L else obj.optLong("remaining", 0L).coerceAtLeast(0L)
                goals.add(
                    GoalSnapshotItem(
                        id = id,
                        name = name,
                        current = current,
                        target = target,
                        pct = pct,
                        remaining = remaining,
                    )
                )
            }
        } catch (_: Exception) {
            // Keep empty goals list on malformed JSON
        }

        val activeGoalCount = maxOf(prefs.getInt(KEY_GOALS_ACTIVE_COUNT, goals.size), goals.size)
        val doneGoalCount = prefs.getInt(KEY_GOALS_DONE_COUNT, 0).coerceAtLeast(0)
        val rawSelectedIdx = prefs.getInt(KEY_GOALS_SELECTED_INDEX, 0).coerceAtLeast(0)
        val selectedGoalIndex = if (goals.isEmpty()) 0 else rawSelectedIdx % goals.size

        val bills = mutableListOf<BillSnapshotItem>()
        val rawBills = prefs.getString(KEY_BILLS_JSON, "[]") ?: "[]"
        try {
            val arr = JSONArray(rawBills)
            for (i in 0 until arr.length()) {
                val obj = arr.optJSONObject(i) ?: continue
                val title = obj.optString("title", "")
                if (title.isBlank()) continue
                val amount = if (hideBalance) 0L else obj.optLong("amount", 0L).coerceAtLeast(0L)
                val dueMs = obj.optLong("dueMs", 0L)
                val daysUntil = if (dueMs > 0L) computeSignedDaysUntil(dueMs) else obj.optInt("daysUntil", 0)
                val isPending = obj.optBoolean("isPending", false)
                bills.add(
                    BillSnapshotItem(
                        title = title,
                        amount = amount,
                        dueMs = dueMs,
                        daysUntil = daysUntil,
                        isPending = isPending,
                    )
                )
            }
        } catch (_: Exception) {
            // Keep empty bills list on malformed JSON
        }

        val billsDueCount = prefs.getInt(KEY_BILLS_DUE_COUNT, 0).coerceAtLeast(0)
        val billsDueAmount = if (hideBalance) 0L else prefs.getLong(KEY_BILLS_DUE_AMOUNT, 0L).coerceAtLeast(0L)

        return GoalsAndBillsSnapshot(
            dbReady = dbReady,
            hasSnapshot = hasSnapshot,
            hideBalance = hideBalance,
            locale = locale,
            goals = goals,
            activeGoalCount = activeGoalCount,
            doneGoalCount = doneGoalCount,
            selectedGoalIndex = selectedGoalIndex,
            bills = bills,
            billsDueCount = billsDueCount,
            billsDueAmount = billsDueAmount,
        )
    }

    fun cycleSelectedGoalFromWidget(context: Context) {
        val prefs = context.getSharedPreferences(WidgetDatabaseHelper.PREFS_NAME, Context.MODE_PRIVATE)
        val rawGoals = prefs.getString(KEY_GOALS_JSON, "[]") ?: "[]"
        val count = try {
            JSONArray(rawGoals).length()
        } catch (_: Exception) {
            0
        }
        if (count > 1) {
            val currentIdx = prefs.getInt(KEY_GOALS_SELECTED_INDEX, 0).coerceAtLeast(0)
            val nextIdx = (currentIdx + 1) % count
            prefs.edit().putInt(KEY_GOALS_SELECTED_INDEX, nextIdx).commit()
        }
        GoalsAndBillsWidgetProvider.updateAllWidgets(context)
    }

    fun adjustBudgetOnNativeTx(
        prefs: SharedPreferences,
        editor: SharedPreferences.Editor,
        amountDelta: Long,
        categoryId: String,
        txDateSec: Long,
    ) {
        if (amountDelta == 0L) return
        if (!prefs.getBoolean(KEY_BUDGET_HAS_CONFIG, false)) return

        val periodStartSec = prefs.getLong(KEY_PERIOD_START_MS, 0L) / 1000L
        val periodEndSec = prefs.getLong(KEY_PERIOD_END_MS, 0L) / 1000L
        val inPeriod = periodStartSec <= 0L || (txDateSec >= periodStartSec && txDateSec < periodEndSec)
        if (!inPeriod) return

        val totalBudget = prefs.getLong(KEY_TOTAL_BUDGET, 0L).coerceAtLeast(0L)
        val updatedSpent = (prefs.getLong(KEY_BUDGET_SPENT, 0L) + amountDelta).coerceAtLeast(0L)
        editor.putLong(KEY_BUDGET_SPENT, updatedSpent)

        if (totalBudget > 0L) {
            val pct = ((updatedSpent * 100L) / totalBudget).toInt().coerceIn(0, 999)
            editor.putInt(KEY_BUDGET_PCT, pct)
            editor.putString(
                KEY_BUDGET_ALERT_LEVEL,
                when {
                    pct >= 100 -> "over"
                    pct >= 85 -> "near"
                    else -> "none"
                }
            )
        }

        val rawJson = prefs.getString(KEY_BUDGET_CATEGORIES_JSON, null)
        if (!rawJson.isNullOrBlank() && categoryId.isNotBlank()) {
            try {
                val arr = JSONArray(rawJson)
                var modified = false
                for (i in 0 until arr.length()) {
                    val obj = arr.optJSONObject(i) ?: continue
                    if (obj.optString("id") == categoryId) {
                        val nextCatSpent = (obj.optLong("spent", 0L) + amountDelta).coerceAtLeast(0L)
                        val limit = obj.optLong("limit", 0L).coerceAtLeast(0L)
                        val nextPct = when {
                            limit > 0L -> ((nextCatSpent * 100L) / limit).toInt().coerceIn(0, 999)
                            totalBudget > 0L -> ((nextCatSpent * 100L) / totalBudget).toInt().coerceIn(0, 999)
                            else -> obj.optInt("pct", 0)
                        }
                        obj.put("spent", nextCatSpent)
                        obj.put("pct", nextPct)
                        modified = true
                        break
                    }
                }
                if (modified) {
                    editor.putString(KEY_BUDGET_CATEGORIES_JSON, arr.toString())
                }
            } catch (_: Exception) {
                // Skip category JSON update if malformed
            }
        }
    }

    fun toggleHideBalanceFromWidget(context: Context): Boolean {
        val prefs = context.getSharedPreferences(WidgetDatabaseHelper.PREFS_NAME, Context.MODE_PRIVATE)
        val nextHide = !prefs.getBoolean(WidgetDatabaseHelper.KEY_HIDE_BALANCE, false)
        val editor = prefs.edit()
            .putBoolean(WidgetDatabaseHelper.KEY_HIDE_BALANCE, nextHide)
            .putString(KEY_NATIVE_HIDE_PENDING, nextHide.toString())

        if (nextHide) {
            editor.remove(WidgetDatabaseHelper.KEY_BALANCE)
            editor.remove(KEY_TODAY_EXPENSE)
            editor.remove(KEY_TOTAL_BUDGET)
            editor.remove(KEY_BUDGET_SPENT)
            editor.remove(KEY_BILLS_DUE_AMOUNT)
        } else if (WidgetDatabaseHelper.isDatabaseReady(context)) {
            WidgetDatabaseHelper.getTotalBalance(context)?.let {
                editor.putLong(WidgetDatabaseHelper.KEY_BALANCE, it)
            }
            editor.putLong(KEY_TODAY_EXPENSE, WidgetDatabaseHelper.getTodayExpense(context))
        }
        editor.commit()

        refreshAllWidgets(context)
        return nextHide
    }

    fun consumeNativeHideBalancePending(context: Context): Boolean? {
        val prefs = context.getSharedPreferences(WidgetDatabaseHelper.PREFS_NAME, Context.MODE_PRIVATE)
        val raw = prefs.getString(KEY_NATIVE_HIDE_PENDING, null) ?: return null
        prefs.edit().remove(KEY_NATIVE_HIDE_PENDING).apply()
        return when (raw) {
            "true" -> true
            "false" -> false
            else -> null
        }
    }

    fun refreshAllWidgets(context: Context) {
        QuickFinanceWidgetProvider.updateAllWidgets(context)
        DailyPulseWidgetProvider.updateAllWidgets(context)
        QuickActionWidgetProvider.updateAllWidgets(context)
        FavoriteTemplatesWidgetProvider.updateAllWidgets(context)
        BudgetGuardrailWidgetProvider.updateAllWidgets(context)
        GoalsAndBillsWidgetProvider.updateAllWidgets(context)
    }

    fun hasAnyActiveWidget(context: Context): Boolean {
        val manager = AppWidgetManager.getInstance(context)
        val providers = listOf(
            ComponentName(context, QuickFinanceWidgetProvider::class.java),
            ComponentName(context, DailyPulseWidgetProvider::class.java),
            ComponentName(context, QuickActionWidgetProvider::class.java),
            ComponentName(context, FavoriteTemplatesWidgetProvider::class.java),
            ComponentName(context, BudgetGuardrailWidgetProvider::class.java),
            ComponentName(context, GoalsAndBillsWidgetProvider::class.java),
        )
        return providers.any { manager.getAppWidgetIds(it).isNotEmpty() }
    }

    private fun normalizeTier(raw: String?): String {
        return when (raw) {
            "safe", "caution", "limit" -> raw
            else -> "safe"
        }
    }

    private fun normalizeAlertLevel(raw: String?): String {
        return when (raw) {
            "none", "near", "over" -> raw
            else -> "none"
        }
    }

    private fun computeDaysLeftFromEndMs(endMs: Long): Int {
        return computeSignedDaysUntil(endMs).coerceAtLeast(0)
    }

    private fun computeSignedDaysUntil(targetMs: Long): Int {
        val nowCal = Calendar.getInstance()
        val targetCal = Calendar.getInstance().apply { timeInMillis = targetMs }

        val nowUtc = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
            clear()
            set(nowCal.get(Calendar.YEAR), nowCal.get(Calendar.MONTH), nowCal.get(Calendar.DAY_OF_MONTH))
        }
        val targetUtc = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
            clear()
            set(targetCal.get(Calendar.YEAR), targetCal.get(Calendar.MONTH), targetCal.get(Calendar.DAY_OF_MONTH))
        }
        return ((targetUtc.timeInMillis - nowUtc.timeInMillis) / 86_400_000L).toInt()
    }

    private fun computeRemainingDaysInMonth(): Int {
        val now = Calendar.getInstance()
        val maxDay = now.getActualMaximum(Calendar.DAY_OF_MONTH)
        val today = now.get(Calendar.DAY_OF_MONTH)
        return (maxDay - today + 1).coerceAtLeast(1)
    }
}

