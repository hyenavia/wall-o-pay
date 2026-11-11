package com.example.wall_o_pay

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.text.DecimalFormat
import java.text.DecimalFormatSymbols
import java.util.Locale

class QuickFinanceWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val PREFS_NAME = "quick_finance_widget"
        private const val KEY_SELECTED_TAB = "selected_tab"
        private const val KEY_BALANCE = "total_balance"
        private const val KEY_HIDE_BALANCE = "hide_balance"

        const val ACTION_TAB_INCOME = "com.example.wall_o_pay.WIDGET_TAB_INCOME"
        const val ACTION_TAB_EXPENSE = "com.example.wall_o_pay.WIDGET_TAB_EXPENSE"
        const val ACTION_TAB_TRANSFER = "com.example.wall_o_pay.WIDGET_TAB_TRANSFER"
        const val ACTION_RECORD = "com.example.wall_o_pay.WIDGET_RECORD"
        const val ACTION_OPEN_APP = "com.example.wall_o_pay.WIDGET_OPEN_APP"
        const val ACTION_UPDATE_DATA = "com.example.wall_o_pay.WIDGET_UPDATE_DATA"

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, QuickFinanceWidgetProvider::class.java)
            )
            if (ids.isNotEmpty()) {
                val intent = Intent(context, QuickFinanceWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                }
                context.sendBroadcast(intent)
            }
        }

        private fun formatRupiah(amount: Long): String {
            val symbols = DecimalFormatSymbols(Locale("id", "ID"))
            val formatter = DecimalFormat("#,###", symbols)
            return "Rp ${formatter.format(amount)}"
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        when (intent.action) {
            ACTION_TAB_INCOME -> {
                prefs.edit().putString(KEY_SELECTED_TAB, "income").apply()
                updateAllWidgets(context)
            }
            ACTION_TAB_EXPENSE -> {
                prefs.edit().putString(KEY_SELECTED_TAB, "expense").apply()
                updateAllWidgets(context)
            }
            ACTION_TAB_TRANSFER -> {
                prefs.edit().putString(KEY_SELECTED_TAB, "transfer").apply()
                updateAllWidgets(context)
            }
            ACTION_RECORD -> {
                val selectedTab = prefs.getString(KEY_SELECTED_TAB, "income") ?: "income"
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    action = "com.example.wall_o_pay.QUICK_WIDGET_$selectedTab".uppercase()
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                context.startActivity(launchIntent)
            }
            ACTION_OPEN_APP -> {
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                context.startActivity(launchIntent)
            }
            ACTION_UPDATE_DATA -> {
                updateAllWidgets(context)
            }
        }
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val selectedTab = prefs.getString(KEY_SELECTED_TAB, "income") ?: "income"
        val balance = prefs.getLong(KEY_BALANCE, 0L)
        val hideBalance = prefs.getBoolean(KEY_HIDE_BALANCE, false)

        val views = RemoteViews(context.packageName, R.layout.widget_quick_finance)

        // Balance display
        if (hideBalance) {
            views.setTextViewText(R.id.widget_balance_value, context.getString(R.string.widget_balance_hidden))
        } else {
            views.setTextViewText(R.id.widget_balance_value, formatRupiah(balance))
        }

        // Tab states — reset all to inactive first
        views.setInt(R.id.tab_income, "setBackgroundResource", R.drawable.widget_tab_bg_inactive)
        views.setTextColor(R.id.tab_income_text, context.getColor(R.color.widget_text_secondary))
        views.setInt(R.id.tab_expense, "setBackgroundResource", R.drawable.widget_tab_bg_inactive)
        views.setTextColor(R.id.tab_expense_text, context.getColor(R.color.widget_text_secondary))
        views.setInt(R.id.tab_transfer, "setBackgroundResource", R.drawable.widget_tab_bg_inactive)
        views.setTextColor(R.id.tab_transfer_text, context.getColor(R.color.widget_text_secondary))

        // Activate selected tab
        when (selectedTab) {
            "income" -> {
                views.setInt(R.id.tab_income, "setBackgroundResource", R.drawable.widget_tab_bg_income)
                views.setTextColor(R.id.tab_income_text, context.getColor(R.color.widget_income_on_dark))
            }
            "expense" -> {
                views.setInt(R.id.tab_expense, "setBackgroundResource", R.drawable.widget_tab_bg_expense)
                views.setTextColor(R.id.tab_expense_text, context.getColor(R.color.widget_expense_on_dark))
            }
            "transfer" -> {
                views.setInt(R.id.tab_transfer, "setBackgroundResource", R.drawable.widget_tab_bg_transfer)
                views.setTextColor(R.id.tab_transfer_text, context.getColor(R.color.widget_dew_mint))
            }
        }

        // PendingIntents for tabs
        views.setOnClickPendingIntent(R.id.tab_income, getBroadcastIntent(context, ACTION_TAB_INCOME, 1))
        views.setOnClickPendingIntent(R.id.tab_expense, getBroadcastIntent(context, ACTION_TAB_EXPENSE, 2))
        views.setOnClickPendingIntent(R.id.tab_transfer, getBroadcastIntent(context, ACTION_TAB_TRANSFER, 3))

        // Record button
        views.setOnClickPendingIntent(R.id.btn_record, getBroadcastIntent(context, ACTION_RECORD, 4))

        // Open app (header logo & open icon)
        views.setOnClickPendingIntent(R.id.widget_logo, getBroadcastIntent(context, ACTION_OPEN_APP, 5))
        views.setOnClickPendingIntent(R.id.widget_open_app, getBroadcastIntent(context, ACTION_OPEN_APP, 6))
        views.setOnClickPendingIntent(R.id.widget_balance_value, getBroadcastIntent(context, ACTION_OPEN_APP, 7))

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun getBroadcastIntent(context: Context, action: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, QuickFinanceWidgetProvider::class.java).apply {
            this.action = action
        }
        return PendingIntent.getBroadcast(
            context, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
