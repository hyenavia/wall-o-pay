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

class GoalsAndBillsWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_TOGGLE_PRIVACY = "com.example.wall_o_pay.GB_TOGGLE_PRIVACY"
        const val ACTION_CYCLE_GOAL = "com.example.wall_o_pay.GB_CYCLE_GOAL"
        const val ACTION_UPDATE_GOALS_BILLS = "com.example.wall_o_pay.GB_UPDATE"

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, GoalsAndBillsWidgetProvider::class.java)
            )
            if (ids.isNotEmpty()) {
                GoalsAndBillsWidgetProvider().onUpdate(context, manager, ids)
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
            ACTION_UPDATE_GOALS_BILLS -> {
                updateAllWidgets(context)
                WidgetMidnightWorker.scheduleIfNeeded(context)
            }
            ACTION_TOGGLE_PRIVACY -> {
                WidgetSnapshotStore.toggleHideBalanceFromWidget(context)
            }
            ACTION_CYCLE_GOAL -> {
                WidgetSnapshotStore.cycleSelectedGoalFromWidget(context)
            }
        }
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int) {
        val snap = WidgetSnapshotStore.loadGoalsAndBillsSnapshot(context)
        val isId = snap.locale == "id"

        val options = appWidgetManager.getAppWidgetOptions(widgetId)
        val isLandscape = context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 240)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 120)
        val effectiveWidth = if (isLandscape) {
            options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, minWidth).takeIf { it > 0 } ?: minWidth
        } else {
            minWidth
        }
        val isCompact = effectiveWidth in 1..205
        val showCompactFooter = isCompact && minHeight >= 115 && snap.bills.isNotEmpty()

        val views = RemoteViews(context.packageName, R.layout.widget_goals_bills)
        views.setInt(R.id.gb_widget_root, "setBackgroundResource", WidgetSnapshotStore.resolveBackgroundRes(context))

        views.setTextViewText(
            R.id.gb_title,
            when {
                isCompact && isId -> "Target"
                isCompact -> "Goals"
                isId -> "Target & Tagihan"
                else -> "Goals & Bills"
            }
        )
        views.setImageViewResource(
            R.id.gb_btn_privacy_icon,
            if (snap.hideBalance) R.drawable.ic_widget_eye_off else R.drawable.ic_widget_eye_on
        )

        // Header status pill highlighting urgent bills or active goals
        val hasOverdue = snap.bills.any { it.daysUntil < 0 }
        val hasDueToday = snap.bills.any { it.daysUntil == 0 }
        val (pillText, pillBg, pillColor) = when {
            hasOverdue -> Triple(
                if (isId) "Terlambat" else "Overdue",
                R.drawable.widget_pill_limit,
                resolveColor(context, R.color.widget_expense_on_dark),
            )
            hasDueToday -> Triple(
                if (isId) "Hari ini" else "Today",
                R.drawable.widget_pill_caution,
                resolveColor(context, R.color.widget_warning_on_dark),
            )
            snap.billsDueCount > 0 -> Triple(
                when {
                    isCompact && isId -> "${snap.billsDueCount} tgh"
                    isCompact -> "${snap.billsDueCount} due"
                    isId -> "${snap.billsDueCount} tagihan"
                    else -> "${snap.billsDueCount} due"
                },
                R.drawable.widget_pill_caution,
                resolveColor(context, R.color.widget_warning_on_dark),
            )
            snap.activeGoalCount > 0 -> Triple(
                if (isCompact) "${snap.activeGoalCount}"
                else if (isId) "${snap.activeGoalCount} target"
                else "${snap.activeGoalCount} goals",
                R.drawable.widget_pill_safe,
                resolveColor(context, R.color.widget_income_on_dark),
            )
            else -> Triple(
                if (isId) "Siap" else "Ready",
                R.drawable.widget_pill_safe,
                resolveColor(context, R.color.widget_income_on_dark),
            )
        }
        views.setTextViewText(R.id.gb_status_pill, pillText)
        views.setInt(R.id.gb_status_pill, "setBackgroundResource", pillBg)
        views.setTextColor(R.id.gb_status_pill, pillColor)

        // Left Card: Savings Goal Tracker
        val hasGoals = snap.goals.isNotEmpty()
        views.setViewVisibility(R.id.gb_goal_btn_cycle, if (snap.goals.size > 1) View.VISIBLE else View.GONE)

        if (hasGoals) {
            val goal = snap.goals[snap.selectedGoalIndex]
            val kicker = if (snap.goals.size > 1) {
                if (isId) "TARGET ${snap.selectedGoalIndex + 1}/${snap.goals.size}"
                else "GOAL ${snap.selectedGoalIndex + 1}/${snap.goals.size}"
            } else {
                if (isId) "TARGET TABUNGAN" else "SAVINGS GOAL"
            }
            views.setTextViewText(R.id.gb_goal_kicker, kicker)
            views.setTextViewText(R.id.gb_goal_name, goal.name)
            views.setProgressBar(R.id.gb_goal_progress, 100, goal.pct.coerceIn(0, 100), false)
            views.setTextViewText(R.id.gb_goal_pct, "${goal.pct}%")
            views.setTextViewText(
                R.id.gb_goal_subline,
                if (snap.hideBalance) {
                    if (isId) "Terkumpul: Rp ••••••" else "Saved: Rp ••••••"
                } else {
                    val cur = WidgetDatabaseHelper.formatCompactRupiah(goal.current, isId)
                    val tgt = WidgetDatabaseHelper.formatCompactRupiah(goal.target, isId)
                    "$cur / $tgt"
                }
            )
        } else {
            views.setTextViewText(
                R.id.gb_goal_kicker,
                if (isId) "TARGET TABUNGAN" else "SAVINGS GOAL"
            )
            when {
                !snap.dbReady && !snap.hasSnapshot -> {
                    views.setTextViewText(
                        R.id.gb_goal_name,
                        if (isId) "Buka app" else "Open app"
                    )
                    views.setProgressBar(R.id.gb_goal_progress, 100, 0, false)
                    views.setTextViewText(R.id.gb_goal_pct, "0%")
                    views.setTextViewText(
                        R.id.gb_goal_subline,
                        if (isId) "Ketuk untuk sinkron" else "Tap to sync"
                    )
                }
                snap.doneGoalCount > 0 -> {
                    views.setTextViewText(
                        R.id.gb_goal_name,
                        if (isId) "${snap.doneGoalCount} target tercapai"
                        else "${snap.doneGoalCount} goals reached"
                    )
                    views.setProgressBar(R.id.gb_goal_progress, 100, 100, false)
                    views.setTextViewText(R.id.gb_goal_pct, "100%")
                    views.setTextViewText(
                        R.id.gb_goal_subline,
                        if (isId) "Buat target baru" else "Create a new goal"
                    )
                }
                else -> {
                    views.setTextViewText(
                        R.id.gb_goal_name,
                        if (isId) "Belum ada target" else "No active goals"
                    )
                    views.setProgressBar(R.id.gb_goal_progress, 100, 0, false)
                    views.setTextViewText(R.id.gb_goal_pct, "0%")
                    views.setTextViewText(
                        R.id.gb_goal_subline,
                        if (snap.hideBalance) {
                            if (isId) "Nominal disembunyikan" else "Amounts hidden"
                        } else if (isId) {
                            "Ketuk untuk buat target"
                        } else {
                            "Tap to add a goal"
                        }
                    )
                }
            }
        }

        // Right Card (4x2+): Upcoming Bills
        views.setViewVisibility(R.id.gb_bills_card, if (!isCompact) View.VISIBLE else View.GONE)
        if (!isCompact) {
            views.setTextViewText(
                R.id.gb_bills_kicker,
                if (isId) "TAGIHAN BERIKUTNYA" else "UPCOMING BILLS"
            )
            val totalBadge = when {
                snap.bills.isEmpty() -> ""
                snap.hideBalance -> "Rp ••••"
                snap.billsDueAmount > 0L -> WidgetDatabaseHelper.formatCompactRupiah(snap.billsDueAmount, isId)
                else -> ""
            }
            views.setViewVisibility(R.id.gb_bills_total_badge, if (totalBadge.isNotEmpty()) View.VISIBLE else View.GONE)
            views.setTextViewText(R.id.gb_bills_total_badge, totalBadge)

            if (snap.bills.isEmpty()) {
                views.setViewVisibility(R.id.gb_bills_empty, View.VISIBLE)
                views.setTextViewText(
                    R.id.gb_bills_empty,
                    if (isId) "Tidak ada tagihan dalam 30 hari" else "No bills due in 30 days"
                )
                views.setViewVisibility(R.id.gb_bill_row_0, View.GONE)
                views.setViewVisibility(R.id.gb_bill_row_1, View.GONE)
            } else {
                views.setViewVisibility(R.id.gb_bills_empty, View.GONE)
                val rows = listOf(
                    Triple(R.id.gb_bill_row_0, R.id.gb_bill_title_0, R.id.gb_bill_due_0) to R.id.gb_bill_amount_0,
                    Triple(R.id.gb_bill_row_1, R.id.gb_bill_title_1, R.id.gb_bill_due_1) to R.id.gb_bill_amount_1,
                )
                for (i in 0 until 2) {
                    val (rowTuple, amountId) = rows[i]
                    val (rowId, titleId, dueId) = rowTuple
                    val bill = snap.bills.getOrNull(i)
                    if (bill == null) {
                        views.setViewVisibility(rowId, View.GONE)
                        continue
                    }
                    views.setViewVisibility(rowId, View.VISIBLE)
                    views.setTextViewText(titleId, bill.title)
                    views.setTextViewText(dueId, formatDueLabel(bill.daysUntil, isId))
                    views.setTextColor(dueId, resolveDueColor(context, bill.daysUntil))
                    views.setTextViewText(
                        amountId,
                        if (snap.hideBalance) "Rp ••••••"
                        else WidgetDatabaseHelper.formatRupiah(bill.amount)
                    )
                }
            }
        }

        // Compact 2x2 Next Bill Footer
        views.setViewVisibility(R.id.gb_compact_bill_footer, if (showCompactFooter) View.VISIBLE else View.GONE)
        if (showCompactFooter) {
            val nextBill = snap.bills.first()
            val amtText = if (snap.hideBalance) {
                "Rp ••••"
            } else {
                WidgetDatabaseHelper.formatCompactRupiah(nextBill.amount, isId)
            }
            views.setTextViewText(R.id.gb_compact_bill_text, "${nextBill.title} • $amtText")
            views.setTextViewText(R.id.gb_compact_bill_due, formatDueLabel(nextBill.daysUntil, isId))
            views.setTextColor(R.id.gb_compact_bill_due, resolveDueColor(context, nextBill.daysUntil))
        }

        // Click Intents
        val privacyIntent = Intent(context, GoalsAndBillsWidgetProvider::class.java).apply {
            action = ACTION_TOGGLE_PRIVACY
            setPackage(context.packageName)
        }
        views.setOnClickPendingIntent(
            R.id.gb_btn_privacy,
            PendingIntent.getBroadcast(
                context,
                401,
                privacyIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        )

        val quickAddIntent = Intent(context, QuickTransactionActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(QuickTransactionActivity.EXTRA_FROM_WIDGET, false)
            putExtra(QuickTransactionActivity.EXTRA_TYPE, "expense")
        }
        views.setOnClickPendingIntent(
            R.id.gb_btn_add,
            PendingIntent.getActivity(
                context,
                402,
                quickAddIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        )

        val cycleGoalIntent = Intent(context, GoalsAndBillsWidgetProvider::class.java).apply {
            action = ACTION_CYCLE_GOAL
            setPackage(context.packageName)
        }
        views.setOnClickPendingIntent(
            R.id.gb_goal_btn_cycle,
            PendingIntent.getBroadcast(
                context,
                403,
                cycleGoalIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        )

        val openGoalsIntent = Intent(context, MainActivity::class.java).apply {
            action = "com.example.wall_o_pay.WIDGET_ROUTE_GOALS"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(MainActivity.EXTRA_WIDGET_ROUTE, "route_goals")
        }
        val openGoalsPending = PendingIntent.getActivity(
            context,
            404,
            openGoalsIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.gb_logo, openGoalsPending)
        views.setOnClickPendingIntent(R.id.gb_title, openGoalsPending)
        views.setOnClickPendingIntent(R.id.gb_goal_card, openGoalsPending)

        val openRecurringIntent = Intent(context, MainActivity::class.java).apply {
            action = "com.example.wall_o_pay.WIDGET_ROUTE_RECURRING"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(MainActivity.EXTRA_WIDGET_ROUTE, "route_recurring")
        }
        val openRecurringPending = PendingIntent.getActivity(
            context,
            405,
            openRecurringIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.gb_bills_card, openRecurringPending)
        views.setOnClickPendingIntent(R.id.gb_compact_bill_footer, openRecurringPending)

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun formatDueLabel(daysUntil: Int, isId: Boolean): String {
        return when {
            daysUntil < 0 -> if (isId) "Terlambat" else "Overdue"
            daysUntil == 0 -> if (isId) "Hari ini" else "Today"
            daysUntil == 1 -> if (isId) "Besok" else "Tomorrow"
            else -> if (isId) "${daysUntil} hr" else "${daysUntil}d"
        }
    }

    private fun resolveDueColor(context: Context, daysUntil: Int): Int {
        return when {
            daysUntil < 0 -> resolveColor(context, R.color.widget_expense_on_dark)
            daysUntil <= 2 -> resolveColor(context, R.color.widget_warning_on_dark)
            else -> resolveColor(context, R.color.widget_income_on_dark)
        }
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

