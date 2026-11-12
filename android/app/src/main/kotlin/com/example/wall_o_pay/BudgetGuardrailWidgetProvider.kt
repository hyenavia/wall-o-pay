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
import kotlin.math.abs

class BudgetGuardrailWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_TOGGLE_PRIVACY = "com.example.wall_o_pay.BUDGET_TOGGLE_PRIVACY"
        const val ACTION_UPDATE_BUDGET = "com.example.wall_o_pay.BUDGET_UPDATE"

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, BudgetGuardrailWidgetProvider::class.java)
            )
            if (ids.isNotEmpty()) {
                BudgetGuardrailWidgetProvider().onUpdate(context, manager, ids)
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
            ACTION_UPDATE_BUDGET -> {
                updateAllWidgets(context)
                WidgetMidnightWorker.scheduleIfNeeded(context)
            }
            ACTION_TOGGLE_PRIVACY -> {
                WidgetSnapshotStore.toggleHideBalanceFromWidget(context)
            }
        }
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int) {
        val snap = WidgetSnapshotStore.loadBudgetSnapshot(context)
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
        val showCategories = !isCompact && minHeight >= 105 && snap.hasBudgetConfig && snap.categories.isNotEmpty()

        val views = RemoteViews(context.packageName, R.layout.widget_budget_guardrail)
        views.setInt(R.id.budget_widget_root, "setBackgroundResource", WidgetSnapshotStore.resolveBackgroundRes(context))

        views.setTextViewText(
            R.id.budget_title,
            when {
                isCompact && isId -> "Anggaran"
                isCompact -> "Budget"
                isId -> "Penjaga Anggaran"
                else -> "Budget Guardrail"
            }
        )
        views.setTextViewText(
            R.id.budget_remaining_label,
            when {
                isCompact && isId -> "Sisa"
                isCompact -> "Remaining"
                isId -> "Sisa Anggaran"
                else -> "Remaining Budget"
            }
        )
        views.setTextViewText(
            R.id.budget_days_left,
            if (isId) "${snap.daysLeft} hr" else "${snap.daysLeft}d left"
        )
        views.setImageViewResource(
            R.id.budget_btn_privacy_icon,
            if (snap.hideBalance) R.drawable.ic_widget_eye_off else R.drawable.ic_widget_eye_on
        )

        // Alert status pill
        val pctLabel = "${snap.budgetPct}%"
        val (pillText, pillBg, pillColor) = when {
            !snap.hasBudgetConfig -> Triple(
                if (isId) "Kosong" else "Unset",
                R.drawable.widget_pill_safe,
                resolveColor(context, R.color.widget_fresh_sage),
            )
            snap.alertLevel == "over" -> Triple(
                if (isCompact) pctLabel else (if (isId) "Lewat $pctLabel" else "Over $pctLabel"),
                R.drawable.widget_pill_limit,
                resolveColor(context, R.color.widget_expense_on_dark),
            )
            snap.alertLevel == "near" -> Triple(
                if (isCompact) pctLabel else (if (isId) "Hampir $pctLabel" else "Near $pctLabel"),
                R.drawable.widget_pill_caution,
                resolveColor(context, R.color.widget_warning_on_dark),
            )
            else -> Triple(
                if (isCompact) pctLabel else (if (isId) "Aman $pctLabel" else "Safe $pctLabel"),
                R.drawable.widget_pill_safe,
                resolveColor(context, R.color.widget_income_on_dark),
            )
        }
        views.setTextViewText(R.id.budget_alert_pill, pillText)
        views.setInt(R.id.budget_alert_pill, "setBackgroundResource", pillBg)
        views.setTextColor(R.id.budget_alert_pill, pillColor)

        val barPct = if (snap.hasBudgetConfig) snap.budgetPct.coerceIn(0, 100) else 0
        views.setViewVisibility(
            R.id.budget_progress_safe,
            if (snap.alertLevel != "near" && snap.alertLevel != "over") View.VISIBLE else View.GONE
        )
        views.setViewVisibility(
            R.id.budget_progress_caution,
            if (snap.alertLevel == "near") View.VISIBLE else View.GONE
        )
        views.setViewVisibility(
            R.id.budget_progress_limit,
            if (snap.alertLevel == "over") View.VISIBLE else View.GONE
        )
        views.setProgressBar(R.id.budget_progress_safe, 100, barPct, false)
        views.setProgressBar(R.id.budget_progress_caution, 100, barPct, false)
        views.setProgressBar(R.id.budget_progress_limit, 100, barPct, false)

        // Monetary hero value & subline
        when {
            snap.hideBalance -> {
                views.setTextViewText(R.id.budget_remaining_amount, "Rp ••••••••")
                views.setTextColor(R.id.budget_remaining_amount, resolveColor(context, R.color.widget_dew_mint))
                views.setTextViewText(
                    R.id.budget_spent_subline,
                    if (snap.hasBudgetConfig) {
                        if (isCompact) "$pctLabel • Rp ••••••"
                        else if (isId) "Terpakai $pctLabel (Rp ••••••)"
                        else "Used $pctLabel (Rp ••••••)"
                    } else {
                        if (isId) "Anggaran disembunyikan" else "Budget hidden"
                    }
                )
            }
            !snap.dbReady && !snap.hasSnapshot -> {
                views.setTextViewText(
                    R.id.budget_remaining_amount,
                    if (isId) "Buka app" else "Open app"
                )
                views.setTextColor(R.id.budget_remaining_amount, resolveColor(context, R.color.widget_fresh_sage))
                views.setTextViewText(
                    R.id.budget_spent_subline,
                    if (isId) "Ketuk untuk inisialisasi" else "Tap to initialize"
                )
            }
            !snap.hasBudgetConfig -> {
                views.setTextViewText(
                    R.id.budget_remaining_amount,
                    if (isId) "Belum ada anggaran" else "No budget set"
                )
                views.setTextColor(R.id.budget_remaining_amount, resolveColor(context, R.color.widget_fresh_sage))
                views.setTextViewText(
                    R.id.budget_spent_subline,
                    if (isId) "Ketuk untuk atur anggaran periode" else "Tap to set up your period budget"
                )
            }
            else -> {
                val remText = if (snap.budgetRemaining < 0L) {
                    "-${WidgetDatabaseHelper.formatRupiah(abs(snap.budgetRemaining))}"
                } else {
                    WidgetDatabaseHelper.formatRupiah(snap.budgetRemaining)
                }
                views.setTextViewText(R.id.budget_remaining_amount, remText)
                views.setTextColor(
                    R.id.budget_remaining_amount,
                    when (snap.alertLevel) {
                        "over" -> resolveColor(context, R.color.widget_expense_on_dark)
                        "near" -> resolveColor(context, R.color.widget_warning_on_dark)
                        else -> resolveColor(context, R.color.widget_soft_ivory)
                    }
                )
                val spentCompact = WidgetDatabaseHelper.formatCompactRupiah(snap.budgetSpent, isId)
                val totalCompact = WidgetDatabaseHelper.formatCompactRupiah(snap.totalBudget, isId)
                views.setTextViewText(
                    R.id.budget_spent_subline,
                    when {
                        isCompact -> "$spentCompact / $totalCompact"
                        isId -> "Terpakai $spentCompact dari $totalCompact"
                        else -> "Spent $spentCompact of $totalCompact"
                    }
                )
            }
        }

        // Expanded category breakdown rows (up to 3)
        views.setViewVisibility(R.id.budget_categories_container, if (showCategories) View.VISIBLE else View.GONE)
        if (showCategories) {
            val rowIds = listOf(
                R.id.budget_cat_row_0 to Triple(R.id.budget_cat_name_0, R.id.budget_cat_amount_0, R.id.budget_cat_pct_0),
                R.id.budget_cat_row_1 to Triple(R.id.budget_cat_name_1, R.id.budget_cat_amount_1, R.id.budget_cat_pct_1),
                R.id.budget_cat_row_2 to Triple(R.id.budget_cat_name_2, R.id.budget_cat_amount_2, R.id.budget_cat_pct_2),
            )
            val progIds = listOf(
                Triple(R.id.budget_cat_prog_safe_0, R.id.budget_cat_prog_caution_0, R.id.budget_cat_prog_limit_0),
                Triple(R.id.budget_cat_prog_safe_1, R.id.budget_cat_prog_caution_1, R.id.budget_cat_prog_limit_1),
                Triple(R.id.budget_cat_prog_safe_2, R.id.budget_cat_prog_caution_2, R.id.budget_cat_prog_limit_2),
            )

            for (i in 0 until 3) {
                val (rowId, textTriple) = rowIds[i]
                val (nameId, amountId, pctId) = textTriple
                val (safeProgId, cautionProgId, limitProgId) = progIds[i]
                val cat = snap.categories.getOrNull(i)
                if (cat == null) {
                    views.setViewVisibility(rowId, View.GONE)
                    continue
                }
                views.setViewVisibility(rowId, View.VISIBLE)
                views.setTextViewText(nameId, cat.name)
                views.setTextViewText(pctId, "${cat.pct}%")

                val amountLabel = when {
                    snap.hideBalance -> "Rp ••••"
                    cat.limit > 0L -> "${WidgetDatabaseHelper.formatCompactRupiah(cat.spent, isId)} / ${WidgetDatabaseHelper.formatCompactRupiah(cat.limit, isId)}"
                    else -> WidgetDatabaseHelper.formatCompactRupiah(cat.spent, isId)
                }
                views.setTextViewText(amountId, amountLabel)

                val catTier = when {
                    cat.pct >= 100 -> "over"
                    cat.pct >= 85 -> "near"
                    else -> "safe"
                }
                views.setTextColor(
                    pctId,
                    when (catTier) {
                        "over" -> resolveColor(context, R.color.widget_expense_on_dark)
                        "near" -> resolveColor(context, R.color.widget_warning_on_dark)
                        else -> resolveColor(context, R.color.widget_income_on_dark)
                    }
                )
                val catPctClamped = cat.pct.coerceIn(0, 100)
                views.setViewVisibility(safeProgId, if (catTier == "safe") View.VISIBLE else View.GONE)
                views.setViewVisibility(cautionProgId, if (catTier == "near") View.VISIBLE else View.GONE)
                views.setViewVisibility(limitProgId, if (catTier == "over") View.VISIBLE else View.GONE)
                views.setProgressBar(safeProgId, 100, catPctClamped, false)
                views.setProgressBar(cautionProgId, 100, catPctClamped, false)
                views.setProgressBar(limitProgId, 100, catPctClamped, false)
            }
        }

        // Click intents
        val privacyIntent = Intent(context, BudgetGuardrailWidgetProvider::class.java).apply {
            action = ACTION_TOGGLE_PRIVACY
            setPackage(context.packageName)
        }
        views.setOnClickPendingIntent(
            R.id.budget_btn_privacy,
            PendingIntent.getBroadcast(
                context,
                301,
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
            R.id.budget_btn_add,
            PendingIntent.getActivity(
                context,
                302,
                quickAddIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        )

        val openBudgetIntent = Intent(context, MainActivity::class.java).apply {
            action = "com.example.wall_o_pay.WIDGET_ROUTE_BUDGET"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(MainActivity.EXTRA_WIDGET_ROUTE, "tab_budget")
        }
        val openBudgetPending = PendingIntent.getActivity(
            context,
            303,
            openBudgetIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.budget_logo, openBudgetPending)
        views.setOnClickPendingIntent(R.id.budget_title, openBudgetPending)
        views.setOnClickPendingIntent(R.id.budget_summary_card, openBudgetPending)
        views.setOnClickPendingIntent(R.id.budget_categories_container, openBudgetPending)

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

