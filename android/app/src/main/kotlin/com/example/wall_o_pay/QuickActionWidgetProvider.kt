package com.example.wall_o_pay

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews

class QuickActionWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_UPDATE_BAR = "com.example.wall_o_pay.ACTION_BAR_UPDATE"
        const val ACTION_TOGGLE_PRIVACY = "com.example.wall_o_pay.ACTION_BAR_TOGGLE_PRIVACY"

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, QuickActionWidgetProvider::class.java)
            )
            if (ids.isNotEmpty()) {
                QuickActionWidgetProvider().onUpdate(context, manager, ids)
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
            ACTION_UPDATE_BAR -> {
                updateAllWidgets(context)
            }
            ACTION_TOGGLE_PRIVACY -> {
                WidgetSnapshotStore.toggleHideBalanceFromWidget(context)
            }
        }
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int) {
        val prefs = context.getSharedPreferences(WidgetDatabaseHelper.PREFS_NAME, Context.MODE_PRIVATE)
        val locale = WidgetDatabaseHelper.getLocale(context)
        val isId = locale == "id"
        val hideBalance = prefs.getBoolean(WidgetDatabaseHelper.KEY_HIDE_BALANCE, false)
        val dbReady = WidgetDatabaseHelper.isDatabaseReady(context)
        val balance = if (hideBalance) {
            0L
        } else if (dbReady) {
            WidgetDatabaseHelper.getTotalBalance(context)
                ?: prefs.getLong(WidgetDatabaseHelper.KEY_BALANCE, 0L)
        } else {
            prefs.getLong(WidgetDatabaseHelper.KEY_BALANCE, 0L)
        }

        val options = appWidgetManager.getAppWidgetOptions(widgetId)
        val isLandscape = context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250)
        val effectiveWidth = if (isLandscape) {
            options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, minWidth).takeIf { it > 0 } ?: minWidth
        } else {
            minWidth
        }
        val isCompact2x1 = effectiveWidth in 1..215
        val isWide = effectiveWidth >= 320

        val views = RemoteViews(context.packageName, R.layout.widget_quick_action)
        views.setInt(
            R.id.action_widget_root,
            "setBackgroundResource",
            WidgetSnapshotStore.resolveBackgroundRes(context, isActionBar = true)
        )

        // Responsive visibility for 2x1 vs 4x1
        views.setViewVisibility(R.id.action_brand_group, if (isCompact2x1) View.GONE else View.VISIBLE)
        views.setViewVisibility(R.id.action_btn_transfer, if (isCompact2x1) View.GONE else View.VISIBLE)
        views.setViewVisibility(R.id.action_btn_transfer_text, if (isWide) View.VISIBLE else View.GONE)

        views.setTextViewText(
            R.id.action_balance_text,
            if (hideBalance) "Rp ••••••" else WidgetDatabaseHelper.formatRupiah(balance)
        )
        views.setTextViewText(
            R.id.action_btn_income_text,
            if (isId) "Masuk" else "In"
        )
        views.setTextViewText(
            R.id.action_btn_expense_text,
            if (isId) "Keluar" else "Out"
        )
        views.setTextViewText(
            R.id.action_btn_transfer_text,
            if (isWide) "Transfer" else ""
        )

        val togglePrivacyIntent = Intent(context, QuickActionWidgetProvider::class.java).apply {
            action = ACTION_TOGGLE_PRIVACY
            setPackage(context.packageName)
        }
        views.setOnClickPendingIntent(
            R.id.action_brand_group,
            PendingIntent.getBroadcast(
                context,
                204,
                togglePrivacyIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        )

        views.setOnClickPendingIntent(
            R.id.action_btn_income,
            createQuickEntryPendingIntent(context, "income", 201)
        )
        views.setOnClickPendingIntent(
            R.id.action_btn_expense,
            createQuickEntryPendingIntent(context, "expense", 202)
        )
        views.setOnClickPendingIntent(
            R.id.action_btn_transfer,
            createQuickEntryPendingIntent(context, "transfer", 203)
        )

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun createQuickEntryPendingIntent(
        context: Context,
        txType: String,
        requestCode: Int,
    ): PendingIntent {
        val intent = Intent(context, QuickTransactionActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(QuickTransactionActivity.EXTRA_FROM_WIDGET, false)
            putExtra(QuickTransactionActivity.EXTRA_TYPE, txType)
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}

