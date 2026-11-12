package com.example.wall_o_pay

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews

class DailyPulseWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_TOGGLE_PRIVACY = "com.example.wall_o_pay.PULSE_TOGGLE_PRIVACY"
        const val ACTION_UPDATE_PULSE = "com.example.wall_o_pay.PULSE_UPDATE"

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, DailyPulseWidgetProvider::class.java)
            )
            if (ids.isNotEmpty()) {
                DailyPulseWidgetProvider().onUpdate(context, manager, ids)
            }
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateWidget(context, appWidgetManager, appWidgetId)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        updateAllWidgets(context)
        WidgetMidnightWorker.scheduleIfNeeded(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        WidgetMidnightWorker.cancelIfNoWidgets(context)
    }

    override fun onRestored(context: Context, oldWidgetIds: IntArray, newWidgetIds: IntArray) {
        super.onRestored(context, oldWidgetIds, newWidgetIds)
        updateAllWidgets(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCALE_CHANGED,
            ACTION_UPDATE_PULSE -> {
                updateAllWidgets(context)
                WidgetMidnightWorker.scheduleIfNeeded(context)
            }
            ACTION_TOGGLE_PRIVACY -> {
                WidgetSnapshotStore.toggleHideBalanceFromWidget(context)
            }
        }
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int) {
        val snap = WidgetSnapshotStore.loadPulseSnapshot(context)
        val isId = snap.locale == "id"

        val options = appWidgetManager.getAppWidgetOptions(widgetId)
        val isLandscape = context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 240)
        val effectiveWidth = if (isLandscape) {
            options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, minWidth).takeIf { it > 0 } ?: minWidth
        } else {
            minWidth
        }
        val isCompact = effectiveWidth in 1..205

        val views = RemoteViews(context.packageName, R.layout.widget_daily_pulse)
        views.setInt(R.id.pulse_widget_root, "setBackgroundResource", WidgetSnapshotStore.resolveBackgroundRes(context))

        // Header localization & responsive adaptation
        views.setTextViewText(
            R.id.pulse_title,
            if (isCompact) "Pulse" else "Daily Pulse"
        )
        views.setTextViewText(
            R.id.pulse_quota_label,
            when {
                isCompact && isId -> "Kuota/Hari"
                isCompact -> "Daily Quota"
                isId -> "Kuota Aman / Hari"
                else -> "Safe Daily Quota"
            }
        )

        // Privacy icon
        views.setImageViewResource(
            R.id.pulse_btn_privacy_icon,
            if (snap.hideBalance) R.drawable.ic_widget_eye_off else R.drawable.ic_widget_eye_on
        )

        // Status pill & progress bar styling per tier
        val (statusText, statusBg, statusColor) = when (snap.tier) {
            "limit" -> Triple(
                if (isId) "Batas" else "Limit",
                R.drawable.widget_pill_limit,
                resolveColor(context, R.color.widget_expense_on_dark),
            )
            "caution" -> Triple(
                if (isId) "Waspada" else "Caution",
                R.drawable.widget_pill_caution,
                resolveColor(context, R.color.widget_warning_on_dark),
            )
            else -> Triple(
                if (isId) "Aman" else "Safe",
                R.drawable.widget_pill_safe,
                resolveColor(context, R.color.widget_income_on_dark),
            )
        }
        views.setTextViewText(R.id.pulse_status_pill, statusText)
        views.setInt(R.id.pulse_status_pill, "setBackgroundResource", statusBg)
        views.setTextColor(R.id.pulse_status_pill, statusColor)

        val progressPct = when {
            snap.hideBalance -> 0
            snap.dailyAllowance <= 0L && snap.todayExpense > 0L -> 100
            snap.dailyAllowance <= 0L -> 0
            else -> ((snap.todayExpense * 100L) / snap.dailyAllowance).toInt().coerceIn(0, 100)
        }

        views.setViewVisibility(R.id.pulse_progress_safe, if (snap.tier == "safe") View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.pulse_progress_caution, if (snap.tier == "caution") View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.pulse_progress_limit, if (snap.tier == "limit") View.VISIBLE else View.GONE)
        views.setProgressBar(R.id.pulse_progress_safe, 100, progressPct, false)
        views.setProgressBar(R.id.pulse_progress_caution, 100, progressPct, false)
        views.setProgressBar(R.id.pulse_progress_limit, 100, progressPct, false)

        // Monetary values
        if (snap.hideBalance) {
            views.setTextViewText(R.id.pulse_quota_amount, "Rp ••••••••")
            views.setTextColor(R.id.pulse_quota_amount, resolveColor(context, R.color.widget_dew_mint))
            views.setTextViewText(
                R.id.pulse_spent_today,
                if (isId) "Terpakai hari ini: Rp ••••••" else "Spent today: Rp ••••••"
            )
            views.setTextViewText(
                R.id.pulse_balance_text,
                if (isCompact) "Rp ••••••" else (if (isId) "Saldo: Rp ••••••••" else "Balance: Rp ••••••••")
            )
        } else if (!snap.dbReady && !snap.hasSnapshot) {
            views.setTextViewText(
                R.id.pulse_quota_amount,
                if (isId) "Buka app" else "Open app"
            )
            views.setTextColor(R.id.pulse_quota_amount, resolveColor(context, R.color.widget_fresh_sage))
            views.setTextViewText(
                R.id.pulse_spent_today,
                if (isId) "Ketuk untuk inisialisasi" else "Tap to initialize"
            )
            views.setTextViewText(R.id.pulse_balance_text, "Wall o' Pay")
        } else {
            views.setTextViewText(R.id.pulse_quota_amount, WidgetDatabaseHelper.formatRupiah(snap.dailyAllowance))
            views.setTextColor(
                R.id.pulse_quota_amount,
                when (snap.tier) {
                    "limit" -> resolveColor(context, R.color.widget_expense_on_dark)
                    "caution" -> resolveColor(context, R.color.widget_warning_on_dark)
                    else -> resolveColor(context, R.color.widget_soft_ivory)
                }
            )
            val spentFormatted = WidgetDatabaseHelper.formatRupiah(snap.todayExpense)
            views.setTextViewText(
                R.id.pulse_spent_today,
                when {
                    isCompact && isId -> "Hari ini: $spentFormatted"
                    isCompact -> "Today: $spentFormatted"
                    isId -> "Terpakai hari ini: $spentFormatted"
                    else -> "Spent today: $spentFormatted"
                }
            )
            val balFormatted = WidgetDatabaseHelper.formatRupiah(snap.totalBalance)
            views.setTextViewText(
                R.id.pulse_balance_text,
                when {
                    isCompact -> balFormatted
                    isId -> "Saldo: $balFormatted"
                    else -> "Balance: $balFormatted"
                }
            )
        }

        views.setTextViewText(
            R.id.pulse_days_left,
            if (isId) "${snap.daysLeft} hr" else "${snap.daysLeft}d left"
        )

        // Click intents
        val privacyIntent = Intent(context, DailyPulseWidgetProvider::class.java).apply {
            action = ACTION_TOGGLE_PRIVACY
            setPackage(context.packageName)
        }
        val privacyPending = PendingIntent.getBroadcast(
            context,
            101,
            privacyIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.pulse_btn_privacy, privacyPending)

        val quickAddIntent = Intent(context, QuickTransactionActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(QuickTransactionActivity.EXTRA_FROM_WIDGET, false)
            putExtra(QuickTransactionActivity.EXTRA_TYPE, "expense")
        }
        val quickAddPending = PendingIntent.getActivity(
            context,
            102,
            quickAddIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.pulse_btn_add, quickAddPending)

        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            action = "com.example.wall_o_pay.WIDGET_ROUTE_HOME"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(MainActivity.EXTRA_WIDGET_ROUTE, "tab_home")
        }
        val openAppPending = PendingIntent.getActivity(
            context,
            103,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.pulse_logo, openAppPending)
        views.setOnClickPendingIntent(R.id.pulse_title, openAppPending)
        views.setOnClickPendingIntent(R.id.pulse_body_card, openAppPending)
        views.setOnClickPendingIntent(R.id.pulse_footer, openAppPending)

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    @Suppress("DEPRECATION")
    private fun resolveColor(context: Context, resId: Int): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            context.getColor(resId)
        } else {
            context.resources.getColor(resId)
        }
    }
}

