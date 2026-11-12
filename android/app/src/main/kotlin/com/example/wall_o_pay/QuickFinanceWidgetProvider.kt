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
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews

class QuickFinanceWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_TAB_INCOME = "com.example.wall_o_pay.WIDGET_TAB_INCOME"
        const val ACTION_TAB_EXPENSE = "com.example.wall_o_pay.WIDGET_TAB_EXPENSE"
        const val ACTION_TAB_TRANSFER = "com.example.wall_o_pay.WIDGET_TAB_TRANSFER"

        const val ACTION_PRESET_10K = "com.example.wall_o_pay.WIDGET_PRESET_10K"
        const val ACTION_PRESET_20K = "com.example.wall_o_pay.WIDGET_PRESET_20K"
        const val ACTION_PRESET_50K = "com.example.wall_o_pay.WIDGET_PRESET_50K"
        const val ACTION_PRESET_100K = "com.example.wall_o_pay.WIDGET_PRESET_100K"
        const val ACTION_CLEAR_AMOUNT = "com.example.wall_o_pay.WIDGET_CLEAR_AMOUNT"

        const val ACTION_CYCLE_CATEGORY = "com.example.wall_o_pay.WIDGET_CYCLE_CATEGORY"
        const val ACTION_CYCLE_WALLET_FROM = "com.example.wall_o_pay.WIDGET_CYCLE_WALLET_FROM"
        const val ACTION_CYCLE_WALLET_TO = "com.example.wall_o_pay.WIDGET_CYCLE_WALLET_TO"

        const val ACTION_RECORD = "com.example.wall_o_pay.WIDGET_RECORD"
        const val ACTION_DISMISS_FEEDBACK = "com.example.wall_o_pay.WIDGET_DISMISS_FEEDBACK"
        const val ACTION_UPDATE_DATA = "com.example.wall_o_pay.WIDGET_UPDATE_DATA"

        private const val MAX_QUEUED_AMOUNT = 999_999_999_999L
        private val saveLock = Any()
        @Volatile
        private var lastSaveElapsedMs: Long = 0L

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, QuickFinanceWidgetProvider::class.java)
            )
            if (ids.isNotEmpty()) {
                QuickFinanceWidgetProvider().onUpdate(context, manager, ids)
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
    }

    override fun onRestored(context: Context, oldWidgetIds: IntArray, newWidgetIds: IntArray) {
        super.onRestored(context, oldWidgetIds, newWidgetIds)
        updateAllWidgets(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        val prefs = context.getSharedPreferences(WidgetDatabaseHelper.PREFS_NAME, Context.MODE_PRIVATE)
        val locale = WidgetDatabaseHelper.getLocale(context)
        val isId = locale == "id"

        when (intent.action) {
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCALE_CHANGED,
            ACTION_UPDATE_DATA -> {
                updateAllWidgets(context)
            }
            ACTION_TAB_INCOME -> {
                prefs.edit()
                    .putString(WidgetDatabaseHelper.KEY_SELECTED_TAB, "income")
                    .remove(WidgetDatabaseHelper.KEY_FEEDBACK_TEXT)
                    .apply()
                updateAllWidgets(context)
            }
            ACTION_TAB_EXPENSE -> {
                prefs.edit()
                    .putString(WidgetDatabaseHelper.KEY_SELECTED_TAB, "expense")
                    .remove(WidgetDatabaseHelper.KEY_FEEDBACK_TEXT)
                    .apply()
                updateAllWidgets(context)
            }
            ACTION_TAB_TRANSFER -> {
                prefs.edit()
                    .putString(WidgetDatabaseHelper.KEY_SELECTED_TAB, "transfer")
                    .remove(WidgetDatabaseHelper.KEY_FEEDBACK_TEXT)
                    .apply()
                updateAllWidgets(context)
            }
            ACTION_PRESET_10K -> addPresetAmount(context, 10_000L)
            ACTION_PRESET_20K -> addPresetAmount(context, 20_000L)
            ACTION_PRESET_50K -> addPresetAmount(context, 50_000L)
            ACTION_PRESET_100K -> addPresetAmount(context, 100_000L)
            ACTION_CLEAR_AMOUNT -> {
                prefs.edit()
                    .putLong(WidgetDatabaseHelper.KEY_QUEUED_AMOUNT, 0L)
                    .remove(WidgetDatabaseHelper.KEY_FEEDBACK_TEXT)
                    .apply()
                updateAllWidgets(context)
            }
            ACTION_CYCLE_CATEGORY -> {
                cycleCategory(context)
                updateAllWidgets(context)
            }
            ACTION_CYCLE_WALLET_FROM -> {
                cycleWallet(context, isDestination = false)
                updateAllWidgets(context)
            }
            ACTION_CYCLE_WALLET_TO -> {
                cycleWallet(context, isDestination = true)
                updateAllWidgets(context)
            }
            ACTION_DISMISS_FEEDBACK -> {
                prefs.edit().remove(WidgetDatabaseHelper.KEY_FEEDBACK_TEXT).apply()
                updateAllWidgets(context)
            }
            ACTION_RECORD -> {
                handleDirectSave(context, isId)
                updateAllWidgets(context)
            }
        }
    }

    private fun addPresetAmount(context: Context, delta: Long) {
        val prefs = context.getSharedPreferences(WidgetDatabaseHelper.PREFS_NAME, Context.MODE_PRIVATE)
        val current = prefs.getLong(WidgetDatabaseHelper.KEY_QUEUED_AMOUNT, 0L).coerceAtLeast(0L)
        val next = (current + delta).coerceAtMost(MAX_QUEUED_AMOUNT)
        prefs.edit()
            .putLong(WidgetDatabaseHelper.KEY_QUEUED_AMOUNT, next)
            .remove(WidgetDatabaseHelper.KEY_FEEDBACK_TEXT)
            .apply()
        updateAllWidgets(context)
    }

    private fun cycleCategory(context: Context) {
        val prefs = context.getSharedPreferences(WidgetDatabaseHelper.PREFS_NAME, Context.MODE_PRIVATE)
        val selectedTab = prefs.getString(WidgetDatabaseHelper.KEY_SELECTED_TAB, "expense") ?: "expense"
        if (selectedTab != "income" && selectedTab != "expense") return

        val categories = WidgetDatabaseHelper.getActiveCategories(context, selectedTab)
        if (categories.isEmpty()) return

        val key = if (selectedTab == "income") {
            WidgetDatabaseHelper.KEY_SELECTED_INCOME_CAT_ID
        } else {
            WidgetDatabaseHelper.KEY_SELECTED_EXPENSE_CAT_ID
        }
        val currentId = prefs.getString(key, null)
        val currentIndex = categories.indexOfFirst { it.id == currentId }
        val nextIndex = if (currentIndex < 0) 0 else (currentIndex + 1) % categories.size
        prefs.edit()
            .putString(key, categories[nextIndex].id)
            .remove(WidgetDatabaseHelper.KEY_FEEDBACK_TEXT)
            .apply()
    }

    private fun cycleWallet(context: Context, isDestination: Boolean) {
        val prefs = context.getSharedPreferences(WidgetDatabaseHelper.PREFS_NAME, Context.MODE_PRIVATE)
        val wallets = WidgetDatabaseHelper.getActiveWallets(context)
        if (wallets.isEmpty()) return

        val selectedTab = prefs.getString(WidgetDatabaseHelper.KEY_SELECTED_TAB, "expense") ?: "expense"
        val currentFromId = resolveWallet(wallets, prefs.getString(WidgetDatabaseHelper.KEY_SELECTED_WALLET_ID, null))?.id
        val currentToId = resolveToWallet(wallets, currentFromId, prefs.getString(WidgetDatabaseHelper.KEY_SELECTED_TO_WALLET_ID, null))?.id

        if (!isDestination) {
            val idx = wallets.indexOfFirst { it.id == currentFromId }
            val nextWallet = wallets[(idx + 1) % wallets.size]
            val editor = prefs.edit()
                .putString(WidgetDatabaseHelper.KEY_SELECTED_WALLET_ID, nextWallet.id)
                .remove(WidgetDatabaseHelper.KEY_FEEDBACK_TEXT)

            if (selectedTab == "transfer" && wallets.size > 1 && nextWallet.id == currentToId) {
                val nextToIdx = (wallets.indexOfFirst { it.id == nextWallet.id } + 1) % wallets.size
                editor.putString(WidgetDatabaseHelper.KEY_SELECTED_TO_WALLET_ID, wallets[nextToIdx].id)
            }
            editor.apply()
        } else {
            if (wallets.size <= 1) return
            val idx = wallets.indexOfFirst { it.id == currentToId }
            var nextIdx = (idx + 1) % wallets.size
            if (wallets[nextIdx].id == currentFromId) {
                nextIdx = (nextIdx + 1) % wallets.size
            }
            prefs.edit()
                .putString(WidgetDatabaseHelper.KEY_SELECTED_TO_WALLET_ID, wallets[nextIdx].id)
                .remove(WidgetDatabaseHelper.KEY_FEEDBACK_TEXT)
                .apply()
        }
    }

    private fun handleDirectSave(context: Context, isId: Boolean) {
        synchronized(saveLock) {
            val nowElapsed = SystemClock.elapsedRealtime()
            if (nowElapsed - lastSaveElapsedMs < 1200L) {
                return
            }

            val prefs = context.getSharedPreferences(WidgetDatabaseHelper.PREFS_NAME, Context.MODE_PRIVATE)
            val selectedTab = prefs.getString(WidgetDatabaseHelper.KEY_SELECTED_TAB, "expense") ?: "expense"
            val amount = prefs.getLong(WidgetDatabaseHelper.KEY_QUEUED_AMOUNT, 0L)

            if (amount <= 0L) {
                val msg = if (isId) "Pilih nominal atau ketuk Detail" else "Select amount or tap Detail"
                prefs.edit()
                    .putString(WidgetDatabaseHelper.KEY_FEEDBACK_TEXT, msg)
                    .putBoolean(WidgetDatabaseHelper.KEY_FEEDBACK_IS_ERROR, true)
                    .apply()
                return
            }

            if (!WidgetDatabaseHelper.isDatabaseReady(context)) {
                val msg = if (isId) "Buka Wall o' Pay sekali dulu" else "Open Wall o' Pay once first"
                prefs.edit()
                    .putString(WidgetDatabaseHelper.KEY_FEEDBACK_TEXT, msg)
                    .putBoolean(WidgetDatabaseHelper.KEY_FEEDBACK_IS_ERROR, true)
                    .apply()
                return
            }

            val wallets = WidgetDatabaseHelper.getActiveWallets(context)
            val fromWallet = resolveWallet(wallets, prefs.getString(WidgetDatabaseHelper.KEY_SELECTED_WALLET_ID, null))
            if (fromWallet == null) {
                val msg = if (isId) "Akun tidak ditemukan" else "No active account found"
                prefs.edit()
                    .putString(WidgetDatabaseHelper.KEY_FEEDBACK_TEXT, msg)
                    .putBoolean(WidgetDatabaseHelper.KEY_FEEDBACK_IS_ERROR, true)
                    .apply()
                return
            }

            var categoryId: String? = null
            var toWalletId: String? = null

            if (selectedTab == "transfer") {
                if (wallets.size < 2) {
                    val msg = if (isId) "Butuh min. 2 akun untuk transfer" else "Need 2+ accounts for transfer"
                    prefs.edit()
                        .putString(WidgetDatabaseHelper.KEY_FEEDBACK_TEXT, msg)
                        .putBoolean(WidgetDatabaseHelper.KEY_FEEDBACK_IS_ERROR, true)
                        .apply()
                    return
                }
                val toWallet = resolveToWallet(wallets, fromWallet.id, prefs.getString(WidgetDatabaseHelper.KEY_SELECTED_TO_WALLET_ID, null))
                if (toWallet == null || toWallet.id == fromWallet.id) {
                    val msg = if (isId) "Akun sumber & tujuan harus beda" else "Source & dest accounts must differ"
                    prefs.edit()
                        .putString(WidgetDatabaseHelper.KEY_FEEDBACK_TEXT, msg)
                        .putBoolean(WidgetDatabaseHelper.KEY_FEEDBACK_IS_ERROR, true)
                        .apply()
                    return
                }
                toWalletId = toWallet.id
            } else {
                val cats = WidgetDatabaseHelper.getActiveCategories(context, selectedTab)
                val key = if (selectedTab == "income") {
                    WidgetDatabaseHelper.KEY_SELECTED_INCOME_CAT_ID
                } else {
                    WidgetDatabaseHelper.KEY_SELECTED_EXPENSE_CAT_ID
                }
                val cat = resolveCategory(cats, prefs.getString(key, null))
                if (cat == null) {
                    val msg = if (isId) "Kategori tidak ditemukan" else "Category not found"
                    prefs.edit()
                        .putString(WidgetDatabaseHelper.KEY_FEEDBACK_TEXT, msg)
                        .putBoolean(WidgetDatabaseHelper.KEY_FEEDBACK_IS_ERROR, true)
                        .apply()
                    return
                }
                categoryId = cat.id
            }

            lastSaveElapsedMs = nowElapsed

            when (val result = WidgetDatabaseHelper.insertTransaction(
                context = context,
                type = selectedTab,
                amount = amount,
                categoryId = categoryId,
                walletId = fromWallet.id,
                toWalletId = toWalletId,
                note = "",
            )) {
                is TxInsertResult.Success -> {
                    val okMsg = if (isId) {
                        "✓ Tersimpan ${WidgetDatabaseHelper.formatRupiah(result.amount)}"
                    } else {
                        "✓ Saved ${WidgetDatabaseHelper.formatRupiah(result.amount)}"
                    }
                    prefs.edit()
                        .putLong(WidgetDatabaseHelper.KEY_QUEUED_AMOUNT, 0L)
                        .putString(WidgetDatabaseHelper.KEY_FEEDBACK_TEXT, okMsg)
                        .putBoolean(WidgetDatabaseHelper.KEY_FEEDBACK_IS_ERROR, false)
                        .commit()
                }
                is TxInsertResult.Error -> {
                    prefs.edit()
                        .putString(WidgetDatabaseHelper.KEY_FEEDBACK_TEXT, result.message)
                        .putBoolean(WidgetDatabaseHelper.KEY_FEEDBACK_IS_ERROR, true)
                        .apply()
                }
            }
        }
    }

    private fun resolveWallet(wallets: List<WidgetWallet>, preferredId: String?): WidgetWallet? {
        if (wallets.isEmpty()) return null
        return wallets.firstOrNull { it.id == preferredId } ?: wallets.first()
    }

    private fun resolveToWallet(
        wallets: List<WidgetWallet>,
        fromId: String?,
        preferredToId: String?,
    ): WidgetWallet? {
        if (wallets.size < 2) return wallets.firstOrNull()
        val candidate = wallets.firstOrNull { it.id == preferredToId && it.id != fromId }
        if (candidate != null) return candidate
        return wallets.firstOrNull { it.id != fromId } ?: wallets.first()
    }

    private fun resolveCategory(cats: List<WidgetCategory>, preferredId: String?): WidgetCategory? {
        if (cats.isEmpty()) return null
        return cats.firstOrNull { it.id == preferredId } ?: cats.first()
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int) {
        val prefs = context.getSharedPreferences(WidgetDatabaseHelper.PREFS_NAME, Context.MODE_PRIVATE)
        val locale = WidgetDatabaseHelper.getLocale(context)
        val isId = locale == "id"

        val selectedTab = (prefs.getString(WidgetDatabaseHelper.KEY_SELECTED_TAB, "expense") ?: "expense").let {
            if (it == "income" || it == "expense" || it == "transfer") it else "expense"
        }
        val hideBalance = prefs.getBoolean(WidgetDatabaseHelper.KEY_HIDE_BALANCE, false)
        val queuedAmount = prefs.getLong(WidgetDatabaseHelper.KEY_QUEUED_AMOUNT, 0L).coerceAtLeast(0L)
        val feedbackText = prefs.getString(WidgetDatabaseHelper.KEY_FEEDBACK_TEXT, null)
        val feedbackIsError = prefs.getBoolean(WidgetDatabaseHelper.KEY_FEEDBACK_IS_ERROR, false)

        val snapshot = WidgetDatabaseHelper.loadWidgetSnapshot(
            context = context,
            txType = selectedTab,
            includeBalance = !hideBalance,
        )
        val dbReady = snapshot.dbReady
        val liveBalance = if (!hideBalance && dbReady) {
            snapshot.totalBalance ?: prefs.getLong(WidgetDatabaseHelper.KEY_BALANCE, 0L)
        } else {
            prefs.getLong(WidgetDatabaseHelper.KEY_BALANCE, 0L)
        }

        val views = RemoteViews(context.packageName, R.layout.widget_quick_finance)
        val options = appWidgetManager.getAppWidgetOptions(widgetId)
        val isLandscape = context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 280)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 240)
        val effectiveWidth = if (isLandscape) {
            options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, minWidth).takeIf { it > 0 } ?: minWidth
        } else {
            minWidth
        }
        val effectiveHeight = if (isLandscape) {
            minHeight
        } else {
            options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, minHeight).takeIf { it > 0 } ?: minHeight
        }
        val isNarrow = effectiveWidth in 1..265
        val isUltraNarrow = effectiveWidth in 1..215
        val iconVis = if (isUltraNarrow) View.GONE else View.VISIBLE

        // Localization & width-responsive labels (icons carry +, -, swap semantics)
        views.setTextViewText(R.id.widget_title, "Quick Finance")
        views.setViewVisibility(R.id.tab_income_icon, iconVis)
        views.setViewVisibility(R.id.tab_expense_icon, iconVis)
        views.setViewVisibility(R.id.tab_transfer_icon, iconVis)
        views.setViewVisibility(R.id.btn_detail_icon, iconVis)
        views.setViewVisibility(R.id.btn_record_icon, iconVis)

        views.setTextViewText(
            R.id.tab_income_text,
            when {
                isNarrow && isId -> "Masuk"
                isNarrow -> "In"
                isId -> "Pemasukan"
                else -> "Income"
            }
        )
        views.setTextViewText(
            R.id.tab_expense_text,
            when {
                isNarrow && isId -> "Keluar"
                isNarrow -> "Out"
                isId -> "Pengeluaran"
                else -> "Expense"
            }
        )
        views.setTextViewText(R.id.tab_transfer_text, "Transfer")
        views.setTextViewText(R.id.widget_queued_label, "Nominal")
        views.setTextViewText(R.id.btn_detail_text, "Detail")
        views.setTextViewText(
            R.id.btn_record_text,
            when {
                isUltraNarrow && isId -> "Simpan"
                isUltraNarrow -> "Save"
                isId -> "Simpan Transaksi"
                else -> "Save Transaction"
            }
        )

        // Balance header display
        if (hideBalance) {
            views.setTextViewText(R.id.widget_balance_value, "Rp ••••••••")
        } else {
            views.setTextViewText(R.id.widget_balance_value, WidgetDatabaseHelper.formatRupiah(liveBalance))
        }

        // Feedback banner
        if (!feedbackText.isNullOrBlank()) {
            views.setViewVisibility(R.id.widget_feedback, View.VISIBLE)
            views.setTextViewText(R.id.widget_feedback, feedbackText)
            if (feedbackIsError) {
                views.setInt(R.id.widget_feedback, "setBackgroundResource", R.drawable.widget_error_bg)
                views.setTextColor(R.id.widget_feedback, resolveColor(context, R.color.widget_expense_on_dark))
            } else {
                views.setInt(R.id.widget_feedback, "setBackgroundResource", R.drawable.widget_success_bg)
                views.setTextColor(R.id.widget_feedback, resolveColor(context, R.color.widget_income_on_dark))
            }
        } else {
            views.setViewVisibility(R.id.widget_feedback, View.GONE)
        }

        // Queued amount
        views.setTextViewText(R.id.widget_queued_amount, WidgetDatabaseHelper.formatRupiah(queuedAmount))
        views.setViewVisibility(R.id.btn_clear_amount, if (queuedAmount > 0L) View.VISIBLE else View.GONE)

        // Reset segmented tabs to calm inactive Glasshouse track style
        views.setInt(R.id.tab_income, "setBackgroundResource", R.drawable.widget_tab_bg_inactive)
        views.setImageViewResource(R.id.tab_income_icon, R.drawable.ic_widget_income_off)
        views.setTextColor(R.id.tab_income_text, resolveColor(context, R.color.widget_fresh_sage))

        views.setInt(R.id.tab_expense, "setBackgroundResource", R.drawable.widget_tab_bg_inactive)
        views.setImageViewResource(R.id.tab_expense_icon, R.drawable.ic_widget_expense_off)
        views.setTextColor(R.id.tab_expense_text, resolveColor(context, R.color.widget_fresh_sage))

        views.setInt(R.id.tab_transfer, "setBackgroundResource", R.drawable.widget_tab_bg_inactive)
        views.setImageViewResource(R.id.tab_transfer_icon, R.drawable.ic_widget_transfer_off)
        views.setTextColor(R.id.tab_transfer_text, resolveColor(context, R.color.widget_fresh_sage))

        // Activate selected tab (Emerald Leaf + Dew Mint rim), semantic amount & TransactionForm CTA gradient
        when (selectedTab) {
            "income" -> {
                views.setInt(R.id.tab_income, "setBackgroundResource", R.drawable.widget_tab_bg_income)
                views.setImageViewResource(R.id.tab_income_icon, R.drawable.ic_widget_income_on)
                views.setTextColor(R.id.tab_income_text, resolveColor(context, R.color.widget_soft_ivory))
                views.setTextColor(R.id.widget_queued_amount, resolveColor(context, R.color.widget_income_on_dark))
                views.setInt(R.id.btn_record, "setBackgroundResource", R.drawable.widget_btn_record_income)
            }
            "expense" -> {
                views.setInt(R.id.tab_expense, "setBackgroundResource", R.drawable.widget_tab_bg_expense)
                views.setImageViewResource(R.id.tab_expense_icon, R.drawable.ic_widget_expense_on)
                views.setTextColor(R.id.tab_expense_text, resolveColor(context, R.color.widget_soft_ivory))
                views.setTextColor(R.id.widget_queued_amount, resolveColor(context, R.color.widget_expense_on_dark))
                views.setInt(R.id.btn_record, "setBackgroundResource", R.drawable.widget_btn_record_expense)
            }
            "transfer" -> {
                views.setInt(R.id.tab_transfer, "setBackgroundResource", R.drawable.widget_tab_bg_transfer)
                views.setImageViewResource(R.id.tab_transfer_icon, R.drawable.ic_widget_transfer_on)
                views.setTextColor(R.id.tab_transfer_text, resolveColor(context, R.color.widget_soft_ivory))
                views.setTextColor(R.id.widget_queued_amount, resolveColor(context, R.color.widget_transfer_on_dark))
                views.setInt(R.id.btn_record, "setBackgroundResource", R.drawable.widget_btn_record_transfer)
            }
        }

        // Dynamic context chips
        var resolvedCategoryId: String? = null
        var resolvedFromWalletId: String? = null
        var resolvedToWalletId: String? = null

        if (!dbReady) {
            views.setViewVisibility(R.id.chip_category, View.VISIBLE)
            views.setViewVisibility(R.id.chip_wallet_from, View.GONE)
            views.setViewVisibility(R.id.transfer_arrow, View.GONE)
            views.setViewVisibility(R.id.chip_wallet_to, View.GONE)
            views.setTextViewText(
                R.id.chip_category_text,
                if (isId) "Buka aplikasi untuk inisialisasi" else "Open app to initialize"
            )
        } else {
            val wallets = snapshot.wallets
            val fromWallet = resolveWallet(wallets, prefs.getString(WidgetDatabaseHelper.KEY_SELECTED_WALLET_ID, null))
            resolvedFromWalletId = fromWallet?.id
            val fromLabel = fromWallet?.let { WidgetDatabaseHelper.localizeLabel(it.name, locale) }
                ?: (if (isId) "Akun" else "Account")

            if (selectedTab == "transfer") {
                views.setViewVisibility(R.id.chip_category, View.GONE)
                views.setViewVisibility(R.id.chip_wallet_from, View.VISIBLE)
                views.setViewVisibility(R.id.transfer_arrow, View.VISIBLE)
                views.setViewVisibility(R.id.chip_wallet_to, View.VISIBLE)

                val toWallet = resolveToWallet(
                    wallets,
                    fromWallet?.id,
                    prefs.getString(WidgetDatabaseHelper.KEY_SELECTED_TO_WALLET_ID, null)
                )
                resolvedToWalletId = toWallet?.id
                val toLabel = if (wallets.size < 2) {
                    if (isId) "Butuh 2 Akun" else "Need 2 Accounts"
                } else {
                    toWallet?.let { WidgetDatabaseHelper.localizeLabel(it.name, locale) }
                        ?: (if (isId) "Tujuan" else "Dest")
                }

                views.setTextViewText(R.id.chip_wallet_from_text, fromLabel)
                views.setTextViewText(R.id.chip_wallet_to_text, toLabel)
            } else {
                views.setViewVisibility(R.id.chip_category, View.VISIBLE)
                views.setViewVisibility(R.id.chip_wallet_from, View.VISIBLE)
                views.setViewVisibility(R.id.transfer_arrow, View.GONE)
                views.setViewVisibility(R.id.chip_wallet_to, View.GONE)

                val cats = snapshot.categories
                val key = if (selectedTab == "income") {
                    WidgetDatabaseHelper.KEY_SELECTED_INCOME_CAT_ID
                } else {
                    WidgetDatabaseHelper.KEY_SELECTED_EXPENSE_CAT_ID
                }
                val cat = resolveCategory(cats, prefs.getString(key, null))
                resolvedCategoryId = cat?.id
                val catLabel = cat?.let { WidgetDatabaseHelper.localizeLabel(it.name, locale) }
                    ?: (if (isId) "Kategori" else "Category")

                views.setTextViewText(R.id.chip_category_text, catLabel)
                views.setTextViewText(R.id.chip_wallet_from_text, fromLabel)
            }
        }

        // Responsive height sizing: adapt seamlessly across compact, medium, and expanded widgets
        val hideContext = effectiveHeight in 1..195
        val hidePresets = effectiveHeight in 1..242
        views.setViewVisibility(
            R.id.presets_row,
            if (hidePresets) View.GONE else View.VISIBLE
        )
        views.setViewVisibility(
            R.id.widget_card_divider,
            if (hideContext) View.GONE else View.VISIBLE
        )
        views.setViewVisibility(
            R.id.context_row,
            if (hideContext) View.GONE else View.VISIBLE
        )

        // PendingIntents
        views.setOnClickPendingIntent(R.id.tab_income, getBroadcastIntent(context, ACTION_TAB_INCOME, 1))
        views.setOnClickPendingIntent(R.id.tab_expense, getBroadcastIntent(context, ACTION_TAB_EXPENSE, 2))
        views.setOnClickPendingIntent(R.id.tab_transfer, getBroadcastIntent(context, ACTION_TAB_TRANSFER, 3))

        views.setOnClickPendingIntent(R.id.btn_preset_10k, getBroadcastIntent(context, ACTION_PRESET_10K, 10))
        views.setOnClickPendingIntent(R.id.btn_preset_20k, getBroadcastIntent(context, ACTION_PRESET_20K, 11))
        views.setOnClickPendingIntent(R.id.btn_preset_50k, getBroadcastIntent(context, ACTION_PRESET_50K, 12))
        views.setOnClickPendingIntent(R.id.btn_preset_100k, getBroadcastIntent(context, ACTION_PRESET_100K, 13))
        views.setOnClickPendingIntent(R.id.btn_clear_amount, getBroadcastIntent(context, ACTION_CLEAR_AMOUNT, 14))

        views.setOnClickPendingIntent(R.id.chip_category, getBroadcastIntent(context, ACTION_CYCLE_CATEGORY, 20))
        views.setOnClickPendingIntent(R.id.chip_wallet_from, getBroadcastIntent(context, ACTION_CYCLE_WALLET_FROM, 21))
        views.setOnClickPendingIntent(R.id.chip_wallet_to, getBroadcastIntent(context, ACTION_CYCLE_WALLET_TO, 22))

        views.setOnClickPendingIntent(R.id.widget_feedback, getBroadcastIntent(context, ACTION_DISMISS_FEEDBACK, 25))
        views.setOnClickPendingIntent(
            R.id.widget_nominal_row,
            getDetailActivityIntent(
                context = context,
                selectedTab = selectedTab,
                queuedAmount = queuedAmount,
                categoryId = resolvedCategoryId,
                fromWalletId = resolvedFromWalletId,
                toWalletId = resolvedToWalletId,
                requestCode = 29,
            )
        )
        views.setOnClickPendingIntent(
            R.id.widget_queued_amount,
            getDetailActivityIntent(
                context = context,
                selectedTab = selectedTab,
                queuedAmount = queuedAmount,
                categoryId = resolvedCategoryId,
                fromWalletId = resolvedFromWalletId,
                toWalletId = resolvedToWalletId,
                requestCode = 30,
            )
        )
        views.setOnClickPendingIntent(
            R.id.btn_detail,
            getDetailActivityIntent(
                context = context,
                selectedTab = selectedTab,
                queuedAmount = queuedAmount,
                categoryId = resolvedCategoryId,
                fromWalletId = resolvedFromWalletId,
                toWalletId = resolvedToWalletId,
                requestCode = 31,
            )
        )
        views.setOnClickPendingIntent(R.id.btn_record, getBroadcastIntent(context, ACTION_RECORD, 32))

        views.setOnClickPendingIntent(R.id.widget_logo, getMainAppActivityIntent(context, 40))
        views.setOnClickPendingIntent(R.id.widget_open_app, getMainAppActivityIntent(context, 41))
        views.setOnClickPendingIntent(R.id.widget_balance_value, getMainAppActivityIntent(context, 42))

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun getBroadcastIntent(context: Context, action: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, QuickFinanceWidgetProvider::class.java).apply {
            this.action = action
            setPackage(context.packageName)
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun getDetailActivityIntent(
        context: Context,
        selectedTab: String,
        queuedAmount: Long,
        categoryId: String?,
        fromWalletId: String?,
        toWalletId: String?,
        requestCode: Int,
    ): PendingIntent {
        val intent = Intent(context, QuickTransactionActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(QuickTransactionActivity.EXTRA_FROM_WIDGET, true)
            putExtra(QuickTransactionActivity.EXTRA_TYPE, selectedTab)
            putExtra(QuickTransactionActivity.EXTRA_AMOUNT, queuedAmount)
            if (categoryId != null) putExtra(QuickTransactionActivity.EXTRA_CATEGORY_ID, categoryId)
            if (fromWalletId != null) putExtra(QuickTransactionActivity.EXTRA_WALLET_ID, fromWalletId)
            if (toWalletId != null) putExtra(QuickTransactionActivity.EXTRA_TO_WALLET_ID, toWalletId)
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun getMainAppActivityIntent(context: Context, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
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
