package com.example.wall_o_pay

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews

class FavoriteTemplatesWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_TAP_TEMPLATE_0 = "com.example.wall_o_pay.FAV_TAP_0"
        const val ACTION_TAP_TEMPLATE_1 = "com.example.wall_o_pay.FAV_TAP_1"
        const val ACTION_TAP_TEMPLATE_2 = "com.example.wall_o_pay.FAV_TAP_2"
        const val ACTION_TAP_TEMPLATE_3 = "com.example.wall_o_pay.FAV_TAP_3"
        const val ACTION_UNDO_TEMPLATE = "com.example.wall_o_pay.FAV_UNDO"
        const val ACTION_DISMISS_FEEDBACK = "com.example.wall_o_pay.FAV_DISMISS_FEEDBACK"
        const val ACTION_AUTO_DISMISS_FEEDBACK = "com.example.wall_o_pay.FAV_AUTO_DISMISS_FEEDBACK"
        const val ACTION_TOGGLE_PRIVACY = "com.example.wall_o_pay.FAV_TOGGLE_PRIVACY"
        const val ACTION_UPDATE_TEMPLATES = "com.example.wall_o_pay.FAV_UPDATE"

        private const val EXTRA_TEMPLATE_ID = "template_id"
        private const val EXTRA_FEEDBACK_STAMP = "feedback_stamp"
        private const val KEY_FAV_FEEDBACK_TEXT = "fav_feedback_text"
        private const val KEY_FAV_FEEDBACK_IS_ERROR = "fav_feedback_is_error"
        private const val KEY_FAV_LAST_TX_ID = "fav_last_tx_id"
        private const val KEY_FAV_FEEDBACK_STAMP = "fav_feedback_stamp"
        private const val AUTO_DISMISS_DELAY_MS = 15_000L

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, FavoriteTemplatesWidgetProvider::class.java)
            )
            if (ids.isNotEmpty()) {
                FavoriteTemplatesWidgetProvider().onUpdate(context, manager, ids)
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
        val prefs = context.getSharedPreferences(WidgetDatabaseHelper.PREFS_NAME, Context.MODE_PRIVATE)
        val isId = WidgetDatabaseHelper.getLocale(context) == "id"

        when (intent.action) {
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCALE_CHANGED,
            ACTION_UPDATE_TEMPLATES -> {
                updateAllWidgets(context)
                WidgetMidnightWorker.scheduleIfNeeded(context)
            }
            ACTION_TOGGLE_PRIVACY -> {
                WidgetSnapshotStore.toggleHideBalanceFromWidget(context)
            }
            ACTION_DISMISS_FEEDBACK -> {
                cancelAutoDismiss(context)
                prefs.edit()
                    .remove(KEY_FAV_FEEDBACK_TEXT)
                    .remove(KEY_FAV_FEEDBACK_IS_ERROR)
                    .remove(KEY_FAV_LAST_TX_ID)
                    .remove(KEY_FAV_FEEDBACK_STAMP)
                    .apply()
                updateAllWidgets(context)
            }
            ACTION_AUTO_DISMISS_FEEDBACK -> {
                val expectedStamp = intent.getLongExtra(EXTRA_FEEDBACK_STAMP, 0L)
                val currentStamp = prefs.getLong(KEY_FAV_FEEDBACK_STAMP, 0L)
                if (expectedStamp == 0L || expectedStamp == currentStamp) {
                    prefs.edit()
                        .remove(KEY_FAV_FEEDBACK_TEXT)
                        .remove(KEY_FAV_FEEDBACK_IS_ERROR)
                        .remove(KEY_FAV_LAST_TX_ID)
                        .remove(KEY_FAV_FEEDBACK_STAMP)
                        .apply()
                    updateAllWidgets(context)
                }
            }
            ACTION_UNDO_TEMPLATE -> {
                cancelAutoDismiss(context)
                val lastTxId = prefs.getString(KEY_FAV_LAST_TX_ID, null)
                if (!lastTxId.isNullOrBlank()) {
                    WidgetDatabaseHelper.softDeleteTransaction(context, lastTxId)
                }
                prefs.edit()
                    .remove(KEY_FAV_LAST_TX_ID)
                    .remove(KEY_FAV_FEEDBACK_TEXT)
                    .remove(KEY_FAV_FEEDBACK_IS_ERROR)
                    .remove(KEY_FAV_FEEDBACK_STAMP)
                    .commit()
                WidgetSnapshotStore.refreshAllWidgets(context)
            }
            ACTION_TAP_TEMPLATE_0,
            ACTION_TAP_TEMPLATE_1,
            ACTION_TAP_TEMPLATE_2,
            ACTION_TAP_TEMPLATE_3 -> {
                val slotIndex = when (intent.action) {
                    ACTION_TAP_TEMPLATE_0 -> 0
                    ACTION_TAP_TEMPLATE_1 -> 1
                    ACTION_TAP_TEMPLATE_2 -> 2
                    else -> 3
                }
                val templateId = intent.getStringExtra(EXTRA_TEMPLATE_ID)
                val templates = WidgetDatabaseHelper.getActiveTemplates(context, limit = 4)
                val template = if (!templateId.isNullOrBlank()) {
                    templates.firstOrNull { it.id == templateId } ?: templates.getOrNull(slotIndex)
                } else {
                    templates.getOrNull(slotIndex)
                }

                if (template == null) {
                    prefs.edit()
                        .putString(
                            KEY_FAV_FEEDBACK_TEXT,
                            if (isId) "Template tidak ditemukan" else "Template not found"
                        )
                        .putBoolean(KEY_FAV_FEEDBACK_IS_ERROR, true)
                        .remove(KEY_FAV_LAST_TX_ID)
                        .apply()
                    updateAllWidgets(context)
                    return
                }

                val result = WidgetDatabaseHelper.insertTransaction(
                    context = context,
                    type = template.type,
                    amount = template.amount,
                    categoryId = template.categoryId,
                    walletId = template.walletId,
                    toWalletId = null,
                    note = template.note,
                    needWant = template.needWant,
                )

                when (result) {
                    is TxInsertResult.Success -> {
                        val hideBalance = prefs.getBoolean(WidgetDatabaseHelper.KEY_HIDE_BALANCE, false)
                        val signPrefix = if (template.type == "income") "+" else "-"
                        val amountText = if (hideBalance) {
                            "Rp ••••"
                        } else {
                            WidgetDatabaseHelper.formatCompactRupiah(template.amount, isId)
                        }
                        val stamp = System.currentTimeMillis()
                        prefs.edit()
                            .putString(KEY_FAV_LAST_TX_ID, result.txId)
                            .putString(KEY_FAV_FEEDBACK_TEXT, "✓ ${template.name} ($signPrefix$amountText)")
                            .putBoolean(KEY_FAV_FEEDBACK_IS_ERROR, false)
                            .putLong(KEY_FAV_FEEDBACK_STAMP, stamp)
                            .commit()
                        scheduleAutoDismiss(context, stamp)
                        WidgetSnapshotStore.refreshAllWidgets(context)
                        WidgetMidnightWorker.scheduleIfNeeded(context)
                    }
                    is TxInsertResult.Error -> {
                        val stamp = System.currentTimeMillis()
                        prefs.edit()
                            .remove(KEY_FAV_LAST_TX_ID)
                            .putString(KEY_FAV_FEEDBACK_TEXT, result.message)
                            .putBoolean(KEY_FAV_FEEDBACK_IS_ERROR, true)
                            .putLong(KEY_FAV_FEEDBACK_STAMP, stamp)
                            .commit()
                        scheduleAutoDismiss(context, stamp)
                        updateAllWidgets(context)
                    }
                }
            }
        }
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int) {
        val prefs = context.getSharedPreferences(WidgetDatabaseHelper.PREFS_NAME, Context.MODE_PRIVATE)
        val locale = WidgetDatabaseHelper.getLocale(context)
        val isId = locale == "id"
        val hideBalance = prefs.getBoolean(WidgetDatabaseHelper.KEY_HIDE_BALANCE, false)
        val templates = WidgetDatabaseHelper.getActiveTemplates(context, limit = 4)

        val feedbackText = prefs.getString(KEY_FAV_FEEDBACK_TEXT, null)
        val feedbackIsError = prefs.getBoolean(KEY_FAV_FEEDBACK_IS_ERROR, false)
        val lastTxId = prefs.getString(KEY_FAV_LAST_TX_ID, null)
        val hasFeedback = !feedbackText.isNullOrBlank()

        val options = appWidgetManager.getAppWidgetOptions(widgetId)
        val isLandscape = context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)
        val effectiveHeight = if (isLandscape) {
            options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 90)
        } else {
            minHeight
        }
        val isSingleRow = effectiveHeight in 1..95

        val views = RemoteViews(context.packageName, R.layout.widget_favorite_templates)
        views.setInt(R.id.fav_widget_root, "setBackgroundResource", WidgetSnapshotStore.resolveBackgroundRes(context))

        // Header localization
        views.setTextViewText(
            R.id.fav_title,
            if (isId) "Favorit Cepat" else "Quick Favorites"
        )
        views.setImageViewResource(
            R.id.fav_btn_privacy_icon,
            if (hideBalance) R.drawable.ic_widget_eye_off else R.drawable.ic_widget_eye_on
        )

        // Header vs Feedback visibility (in tight 4x1, collapse header to keep comfortable touch targets)
        views.setViewVisibility(R.id.fav_header, if (isSingleRow) View.GONE else View.VISIBLE)
        views.setViewVisibility(R.id.fav_feedback_banner, if (hasFeedback) View.VISIBLE else View.GONE)

        if (hasFeedback) {
            views.setTextViewText(R.id.fav_feedback_text, feedbackText)
            views.setInt(
                R.id.fav_feedback_banner,
                "setBackgroundResource",
                if (feedbackIsError) R.drawable.widget_error_bg else R.drawable.widget_success_bg
            )
            views.setViewVisibility(
                R.id.fav_btn_undo,
                if (!feedbackIsError && !lastTxId.isNullOrBlank()) View.VISIBLE else View.GONE
            )
            views.setTextViewText(R.id.fav_btn_undo, if (isId) "Urungkan" else "Undo")
        }

        // Empty state vs Grid
        if (templates.isEmpty()) {
            views.setViewVisibility(R.id.fav_empty_state, View.VISIBLE)
            views.setViewVisibility(R.id.fav_grid, View.GONE)
            views.setTextViewText(
                R.id.fav_empty_title,
                if (isId) "Belum ada template" else "No templates yet"
            )
            views.setTextViewText(
                R.id.fav_empty_hint,
                if (isId) "Ketuk untuk buat template di Wall o' Pay" else "Tap to create a saved template in Wall o' Pay"
            )
        } else {
            views.setViewVisibility(R.id.fav_empty_state, View.GONE)
            views.setViewVisibility(R.id.fav_grid, View.VISIBLE)
            views.setViewVisibility(
                R.id.fav_row_2,
                if (!isSingleRow && templates.size > 2) View.VISIBLE else View.GONE
            )

            val slotIds = listOf(
                Triple(R.id.fav_slot_0, R.id.fav_slot_0_name, R.id.fav_slot_0_amount),
                Triple(R.id.fav_slot_1, R.id.fav_slot_1_name, R.id.fav_slot_1_amount),
                Triple(R.id.fav_slot_2, R.id.fav_slot_2_name, R.id.fav_slot_2_amount),
                Triple(R.id.fav_slot_3, R.id.fav_slot_3_name, R.id.fav_slot_3_amount),
            )
            val tapActions = listOf(
                ACTION_TAP_TEMPLATE_0,
                ACTION_TAP_TEMPLATE_1,
                ACTION_TAP_TEMPLATE_2,
                ACTION_TAP_TEMPLATE_3,
            )

            for (i in 0 until 4) {
                val (containerId, nameId, amountId) = slotIds[i]
                val tmpl = templates.getOrNull(i)
                if (tmpl == null) {
                    views.setViewVisibility(containerId, View.INVISIBLE)
                    continue
                }
                views.setViewVisibility(containerId, View.VISIBLE)
                views.setTextViewText(nameId, tmpl.name)

                val prefix = when (tmpl.type) {
                    "income" -> "+"
                    "transfer" -> "⇄ "
                    else -> "-"
                }
                val amountLabel = if (hideBalance) {
                    "Rp ••••"
                } else {
                    WidgetDatabaseHelper.formatCompactRupiah(tmpl.amount, isId)
                }
                views.setTextViewText(amountId, "$prefix$amountLabel")

                val amountColor = when (tmpl.type) {
                    "income" -> resolveColor(context, R.color.widget_income_on_dark)
                    "transfer" -> resolveColor(context, R.color.widget_transfer_on_dark)
                    else -> resolveColor(context, R.color.widget_expense_on_dark)
                }
                views.setTextColor(amountId, amountColor)

                val tapIntent = Intent(context, FavoriteTemplatesWidgetProvider::class.java).apply {
                    action = tapActions[i]
                    setPackage(context.packageName)
                    putExtra(EXTRA_TEMPLATE_ID, tmpl.id)
                }
                val tapPending = PendingIntent.getBroadcast(
                    context,
                    200 + i,
                    tapIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(containerId, tapPending)
            }
        }

        // Undo & Dismiss Feedback clicks
        val undoIntent = Intent(context, FavoriteTemplatesWidgetProvider::class.java).apply {
            action = ACTION_UNDO_TEMPLATE
            setPackage(context.packageName)
        }
        views.setOnClickPendingIntent(
            R.id.fav_btn_undo,
            PendingIntent.getBroadcast(
                context,
                210,
                undoIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        )

        val dismissIntent = Intent(context, FavoriteTemplatesWidgetProvider::class.java).apply {
            action = ACTION_DISMISS_FEEDBACK
            setPackage(context.packageName)
        }
        views.setOnClickPendingIntent(
            R.id.fav_btn_dismiss_feedback,
            PendingIntent.getBroadcast(
                context,
                211,
                dismissIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        )

        // Privacy toggle
        val privacyIntent = Intent(context, FavoriteTemplatesWidgetProvider::class.java).apply {
            action = ACTION_TOGGLE_PRIVACY
            setPackage(context.packageName)
        }
        views.setOnClickPendingIntent(
            R.id.fav_btn_privacy,
            PendingIntent.getBroadcast(
                context,
                212,
                privacyIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        )

        // '+' button -> QuickTransactionActivity
        val quickAddIntent = Intent(context, QuickTransactionActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(QuickTransactionActivity.EXTRA_FROM_WIDGET, false)
            putExtra(QuickTransactionActivity.EXTRA_TYPE, "expense")
        }
        views.setOnClickPendingIntent(
            R.id.fav_btn_add,
            PendingIntent.getActivity(
                context,
                213,
                quickAddIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        )

        // Header -> MainActivity (Transactions tab)
        val openTxIntent = Intent(context, MainActivity::class.java).apply {
            action = "com.example.wall_o_pay.WIDGET_ROUTE_TRANSACTIONS"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(MainActivity.EXTRA_WIDGET_ROUTE, "tab_transactions")
        }
        val openTxPending = PendingIntent.getActivity(
            context,
            214,
            openTxIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.fav_logo, openTxPending)
        views.setOnClickPendingIntent(R.id.fav_title, openTxPending)

        // Empty state -> MainActivity (new transaction form to save a template)
        val newTxIntent = Intent(context, MainActivity::class.java).apply {
            action = "com.example.wall_o_pay.WIDGET_ROUTE_NEW_TX"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(MainActivity.EXTRA_WIDGET_ROUTE, "new_transaction")
        }
        views.setOnClickPendingIntent(
            R.id.fav_empty_state,
            PendingIntent.getActivity(
                context,
                215,
                newTxIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        )

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun scheduleAutoDismiss(context: Context, stamp: Long) {
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val intent = Intent(context, FavoriteTemplatesWidgetProvider::class.java).apply {
                action = ACTION_AUTO_DISMISS_FEEDBACK
                setPackage(context.packageName)
                putExtra(EXTRA_FEEDBACK_STAMP, stamp)
            }
            val pending = PendingIntent.getBroadcast(
                context,
                219,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pending)
            alarmManager.set(
                AlarmManager.ELAPSED_REALTIME,
                SystemClock.elapsedRealtime() + AUTO_DISMISS_DELAY_MS,
                pending
            )
        } catch (_: Exception) {
            // Non-critical if system declines alarm scheduling
        }
    }

    private fun cancelAutoDismiss(context: Context) {
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val intent = Intent(context, FavoriteTemplatesWidgetProvider::class.java).apply {
                action = ACTION_AUTO_DISMISS_FEEDBACK
                setPackage(context.packageName)
            }
            val pending = PendingIntent.getBroadcast(
                context,
                219,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pending)
        } catch (_: Exception) {
            // Ignore
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

