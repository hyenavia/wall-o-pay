package com.example.wall_o_pay

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.View
import android.view.WindowManager
import android.view.inputmethod.InputMethodManager
import android.widget.ArrayAdapter
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.Spinner
import android.widget.TextView
import android.widget.Toast
import java.text.DecimalFormat
import java.text.DecimalFormatSymbols
import java.util.Locale

class QuickTransactionActivity : Activity() {

    companion object {
        const val EXTRA_TYPE = "extra_type"
        const val EXTRA_AMOUNT = "extra_amount"
        const val EXTRA_CATEGORY_ID = "extra_category_id"
        const val EXTRA_WALLET_ID = "extra_wallet_id"
        const val EXTRA_TO_WALLET_ID = "extra_to_wallet_id"
    }

    private var currentType: String = "expense"
    private var locale: String = "en"
    private var isSaving: Boolean = false
    private var isFormattingAmount: Boolean = false

    private var wallets: List<WidgetWallet> = emptyList()
    private var incomeCategories: List<WidgetCategory> = emptyList()
    private var expenseCategories: List<WidgetCategory> = emptyList()
    private var displayedCategories: List<WidgetCategory> = emptyList()

    private lateinit var tabIncome: FrameLayout
    private lateinit var tabIncomeText: TextView
    private lateinit var tabExpense: FrameLayout
    private lateinit var tabExpenseText: TextView
    private lateinit var tabTransfer: FrameLayout
    private lateinit var tabTransferText: TextView

    private lateinit var inputAmount: EditText
    private lateinit var categoryContainer: LinearLayout
    private lateinit var labelCategory: TextView
    private lateinit var spinnerCategory: Spinner
    private lateinit var labelWalletFrom: TextView
    private lateinit var spinnerWalletFrom: Spinner
    private lateinit var walletToContainer: LinearLayout
    private lateinit var labelWalletTo: TextView
    private lateinit var spinnerWalletTo: Spinner
    private lateinit var labelNote: TextView
    private lateinit var inputNote: EditText
    private lateinit var errorText: TextView
    private lateinit var btnSave: FrameLayout
    private lateinit var btnSaveText: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.dialog_quick_transaction)

        locale = WidgetDatabaseHelper.getLocale(this)
        val isId = locale == "id"

        bindViews()
        applyStaticLocalization(isId)
        setupAmountFormatter()
        setupListeners()
        applyIntentState(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        locale = WidgetDatabaseHelper.getLocale(this)
        applyStaticLocalization(locale == "id")
        applyIntentState(intent)
    }

    private fun applyIntentState(sourceIntent: Intent) {
        isSaving = false
        btnSave.isEnabled = true
        btnSaveText.text = if (locale == "id") "Simpan Transaksi" else "Save Transaction"

        val prefs = getSharedPreferences(WidgetDatabaseHelper.PREFS_NAME, Context.MODE_PRIVATE)
        currentType = sourceIntent.getStringExtra(EXTRA_TYPE)
            ?: prefs.getString(WidgetDatabaseHelper.KEY_SELECTED_TAB, "expense")
            ?: "expense"
        if (currentType != "income" && currentType != "expense" && currentType != "transfer") {
            currentType = "expense"
        }

        val initialAmount = sourceIntent.getLongExtra(EXTRA_AMOUNT, 0L)
        val initialCategoryId = sourceIntent.getStringExtra(EXTRA_CATEGORY_ID)
        val initialWalletId = sourceIntent.getStringExtra(EXTRA_WALLET_ID)
        val initialToWalletId = sourceIntent.getStringExtra(EXTRA_TO_WALLET_ID)

        loadDatabaseOptions()

        if (initialAmount > 0L) {
            val formatted = formatThousands(initialAmount)
            inputAmount.setText(formatted)
            inputAmount.setSelection(formatted.length)
        } else {
            inputAmount.setText("")
        }

        selectTab(currentType, initialCategoryId)
        selectInitialWallets(initialWalletId, initialToWalletId)

        if (initialAmount <= 0L) {
            inputAmount.requestFocus()
            window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_VISIBLE)
        }
    }

    private fun bindViews() {
        val backdrop = findViewById<FrameLayout>(R.id.dialog_backdrop)
        val btnClose = findViewById<TextView>(R.id.dialog_btn_close)

        backdrop.setOnClickListener { finish() }
        btnClose.setOnClickListener { finish() }

        tabIncome = findViewById(R.id.dialog_tab_income)
        tabIncomeText = findViewById(R.id.dialog_tab_income_text)
        tabExpense = findViewById(R.id.dialog_tab_expense)
        tabExpenseText = findViewById(R.id.dialog_tab_expense_text)
        tabTransfer = findViewById(R.id.dialog_tab_transfer)
        tabTransferText = findViewById(R.id.dialog_tab_transfer_text)

        inputAmount = findViewById(R.id.dialog_input_amount)
        categoryContainer = findViewById(R.id.dialog_category_container)
        labelCategory = findViewById(R.id.dialog_label_category)
        spinnerCategory = findViewById(R.id.dialog_spinner_category)
        labelWalletFrom = findViewById(R.id.dialog_label_wallet_from)
        spinnerWalletFrom = findViewById(R.id.dialog_spinner_wallet_from)
        walletToContainer = findViewById(R.id.dialog_wallet_to_container)
        labelWalletTo = findViewById(R.id.dialog_label_wallet_to)
        spinnerWalletTo = findViewById(R.id.dialog_spinner_wallet_to)
        labelNote = findViewById(R.id.dialog_label_note)
        inputNote = findViewById(R.id.dialog_input_note)
        errorText = findViewById(R.id.dialog_error_text)
        btnSave = findViewById(R.id.dialog_btn_save)
        btnSaveText = findViewById(R.id.dialog_btn_save_text)
    }

    private fun applyStaticLocalization(isId: Boolean) {
        findViewById<TextView>(R.id.dialog_title).text = "Quick Finance"
        tabIncomeText.text = if (isId) "+ Pemasukan" else "+ Income"
        tabExpenseText.text = if (isId) "- Pengeluaran" else "- Expense"
        tabTransferText.text = "⇄ Transfer"
        findViewById<TextView>(R.id.dialog_label_amount).text =
            if (isId) "Nominal Transaksi" else "Transaction Amount"
        labelWalletTo.text = if (isId) "Akun Tujuan" else "Destination Account"
        labelNote.text = if (isId) "Keterangan (Opsional)" else "Description (Optional)"
        btnSaveText.text = if (isId) "Simpan Transaksi" else "Save Transaction"
    }

    private fun loadDatabaseOptions() {
        wallets = WidgetDatabaseHelper.getActiveWallets(this)
        incomeCategories = WidgetDatabaseHelper.getActiveCategories(this, "income")
        expenseCategories = WidgetDatabaseHelper.getActiveCategories(this, "expense")

        if (!WidgetDatabaseHelper.isDatabaseReady(this)) {
            val isId = locale == "id"
            showError(
                if (isId) "Database belum siap. Buka aplikasi Wall o' Pay sekali terlebih dahulu."
                else "Database not initialized. Please open Wall o' Pay once first."
            )
            return
        }

        val walletLabels = wallets.map { WidgetDatabaseHelper.localizeLabel(it.name, locale) }
        val fromAdapter = ArrayAdapter(this, R.layout.spinner_item_dark, walletLabels).apply {
            setDropDownViewResource(R.layout.spinner_dropdown_item_dark)
        }
        val toAdapter = ArrayAdapter(this, R.layout.spinner_item_dark, walletLabels).apply {
            setDropDownViewResource(R.layout.spinner_dropdown_item_dark)
        }
        spinnerWalletFrom.adapter = fromAdapter
        spinnerWalletTo.adapter = toAdapter
    }

    private fun selectInitialWallets(fromId: String?, toId: String?) {
        if (wallets.isEmpty()) return
        val fromIdx = if (fromId != null) wallets.indexOfFirst { it.id == fromId }.coerceAtLeast(0) else 0
        spinnerWalletFrom.setSelection(fromIdx)

        var toIdx = if (toId != null) wallets.indexOfFirst { it.id == toId } else -1
        if (toIdx < 0 || toIdx == fromIdx) {
            toIdx = if (wallets.size > 1) (fromIdx + 1) % wallets.size else 0
        }
        spinnerWalletTo.setSelection(toIdx)
    }

    private fun selectTab(type: String, preferredCategoryId: String? = null) {
        currentType = type
        hideError()
        val isId = locale == "id"

        // Reset tab styles
        tabIncome.setBackgroundResource(R.drawable.widget_tab_bg_inactive)
        tabIncomeText.setTextColor(resolveColor(R.color.widget_text_secondary))
        tabExpense.setBackgroundResource(R.drawable.widget_tab_bg_inactive)
        tabExpenseText.setTextColor(resolveColor(R.color.widget_text_secondary))
        tabTransfer.setBackgroundResource(R.drawable.widget_tab_bg_inactive)
        tabTransferText.setTextColor(resolveColor(R.color.widget_text_secondary))

        when (type) {
            "income" -> {
                tabIncome.setBackgroundResource(R.drawable.widget_tab_bg_income)
                tabIncomeText.setTextColor(resolveColor(R.color.widget_income_on_dark))
                inputAmount.setTextColor(resolveColor(R.color.widget_income_on_dark))
                categoryContainer.visibility = View.VISIBLE
                walletToContainer.visibility = View.GONE
                labelCategory.text = if (isId) "Kategori Pemasukan" else "Income Category"
                labelWalletFrom.text = if (isId) "Akun Tujuan" else "Destination Account"
                inputNote.hint = if (isId) "contoh: Uang bulanan, Gaji" else "e.g. Monthly allowance, Salary"
                bindCategories(incomeCategories, preferredCategoryId)
            }
            "expense" -> {
                tabExpense.setBackgroundResource(R.drawable.widget_tab_bg_expense)
                tabExpenseText.setTextColor(resolveColor(R.color.widget_expense_on_dark))
                inputAmount.setTextColor(resolveColor(R.color.widget_expense_on_dark))
                categoryContainer.visibility = View.VISIBLE
                walletToContainer.visibility = View.GONE
                labelCategory.text = if (isId) "Kategori Pengeluaran" else "Expense Category"
                labelWalletFrom.text = if (isId) "Akun Sumber" else "Source Account"
                inputNote.hint = if (isId) "contoh: Makan siang, Pembelian buku" else "e.g. Lunch, Book purchase"
                bindCategories(expenseCategories, preferredCategoryId)
            }
            "transfer" -> {
                tabTransfer.setBackgroundResource(R.drawable.widget_tab_bg_transfer)
                tabTransferText.setTextColor(resolveColor(R.color.widget_dew_mint))
                inputAmount.setTextColor(resolveColor(R.color.widget_dew_mint))
                categoryContainer.visibility = View.GONE
                walletToContainer.visibility = View.VISIBLE
                labelWalletFrom.text = if (isId) "Akun Sumber" else "Source Account"
                inputNote.hint = if (isId) "contoh: Transfer ke tabungan" else "e.g. Transfer to savings"
            }
        }
    }

    private fun bindCategories(list: List<WidgetCategory>, preferredId: String?) {
        displayedCategories = list
        val labels = list.map { WidgetDatabaseHelper.localizeLabel(it.name, locale) }
        val adapter = ArrayAdapter(this, R.layout.spinner_item_dark, labels).apply {
            setDropDownViewResource(R.layout.spinner_dropdown_item_dark)
        }
        spinnerCategory.adapter = adapter
        if (preferredId != null && list.isNotEmpty()) {
            val idx = list.indexOfFirst { it.id == preferredId }
            if (idx >= 0) spinnerCategory.setSelection(idx)
        }
    }

    private fun setupAmountFormatter() {
        inputAmount.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                if (isFormattingAmount) return
                isFormattingAmount = true
                try {
                    val digits = s?.toString()?.replace(Regex("[^0-9]"), "") ?: ""
                    if (digits.isEmpty()) {
                        s?.replace(0, s.length, "")
                    } else {
                        val value = digits.toLongOrNull() ?: 0L
                        val formatted = if (value > 0L) formatThousands(value) else ""
                        s?.replace(0, s.length, formatted)
                    }
                    hideError()
                } finally {
                    isFormattingAmount = false
                }
            }
        })
    }

    private fun formatThousands(value: Long): String {
        val symbols = DecimalFormatSymbols(Locale("id", "ID"))
        val formatter = DecimalFormat("#,###", symbols)
        return formatter.format(value)
    }

    private fun parseAmount(): Long {
        val digits = inputAmount.text.toString().replace(Regex("[^0-9]"), "")
        return digits.toLongOrNull() ?: 0L
    }

    private fun setupListeners() {
        tabIncome.setOnClickListener { selectTab("income") }
        tabExpense.setOnClickListener { selectTab("expense") }
        tabTransfer.setOnClickListener { selectTab("transfer") }
        btnSave.setOnClickListener { handleSave() }
    }

    private fun handleSave() {
        if (isSaving) return
        val isId = locale == "id"

        if (!WidgetDatabaseHelper.isDatabaseReady(this)) {
            showError(
                if (isId) "Database belum siap. Buka aplikasi Wall o' Pay sekali terlebih dahulu."
                else "Database not initialized. Open Wall o' Pay once first."
            )
            return
        }

        val amount = parseAmount()
        if (amount <= 0L) {
            showError(
                if (isId) "Masukkan nominal transaksi lebih dari 0."
                else "Please enter an amount greater than 0."
            )
            inputAmount.requestFocus()
            return
        }

        if (wallets.isEmpty()) {
            showError(if (isId) "Akun tidak ditemukan." else "No active accounts found.")
            return
        }

        val fromIdx = spinnerWalletFrom.selectedItemPosition
        val fromWallet = wallets.getOrNull(fromIdx)
        if (fromWallet == null) {
            showError(if (isId) "Pilih akun yang valid." else "Please select a valid account.")
            return
        }

        var categoryId: String? = null
        var toWalletId: String? = null

        if (currentType == "transfer") {
            if (wallets.size < 2) {
                showError(
                    if (isId) "Minimal 2 akun diperlukan untuk melakukan transfer."
                    else "At least 2 accounts are required for transfer."
                )
                return
            }
            val toIdx = spinnerWalletTo.selectedItemPosition
            val toWallet = wallets.getOrNull(toIdx)
            if (toWallet == null) {
                showError(if (isId) "Akun tujuan tidak ditemukan." else "Destination account not found.")
                return
            }
            if (fromWallet.id == toWallet.id) {
                showError(
                    if (isId) "Akun sumber dan tujuan tidak boleh sama."
                    else "Source and destination accounts must be different."
                )
                return
            }
            toWalletId = toWallet.id
        } else {
            val catIdx = spinnerCategory.selectedItemPosition
            val cat = displayedCategories.getOrNull(catIdx)
            if (cat == null) {
                showError(if (isId) "Pilih kategori transaksi." else "Please choose a category.")
                return
            }
            categoryId = cat.id
        }

        isSaving = true
        btnSave.isEnabled = false
        btnSaveText.text = if (isId) "Menyimpan..." else "Saving..."

        val note = inputNote.text.toString().trim()
        val result = WidgetDatabaseHelper.insertTransaction(
            context = this,
            type = currentType,
            amount = amount,
            categoryId = categoryId,
            walletId = fromWallet.id,
            toWalletId = toWalletId,
            note = note,
        )

        when (result) {
            is TxInsertResult.Success -> {
                val prefs = getSharedPreferences(WidgetDatabaseHelper.PREFS_NAME, Context.MODE_PRIVATE)
                val successMsg = if (isId) {
                    "✓ Tersimpan ${WidgetDatabaseHelper.formatRupiah(result.amount)}"
                } else {
                    "✓ Saved ${WidgetDatabaseHelper.formatRupiah(result.amount)}"
                }
                prefs.edit()
                    .putString(WidgetDatabaseHelper.KEY_SELECTED_TAB, currentType)
                    .putLong(WidgetDatabaseHelper.KEY_QUEUED_AMOUNT, 0L)
                    .putString(WidgetDatabaseHelper.KEY_SELECTED_WALLET_ID, fromWallet.id)
                    .apply {
                        if (toWalletId != null) putString(WidgetDatabaseHelper.KEY_SELECTED_TO_WALLET_ID, toWalletId)
                        if (categoryId != null) {
                            val key = if (currentType == "income") {
                                WidgetDatabaseHelper.KEY_SELECTED_INCOME_CAT_ID
                            } else {
                                WidgetDatabaseHelper.KEY_SELECTED_EXPENSE_CAT_ID
                            }
                            putString(key, categoryId)
                        }
                    }
                    .putString(WidgetDatabaseHelper.KEY_FEEDBACK_TEXT, successMsg)
                    .putBoolean(WidgetDatabaseHelper.KEY_FEEDBACK_IS_ERROR, false)
                    .apply()

                QuickFinanceWidgetProvider.updateAllWidgets(this)
                hideKeyboard()
                Toast.makeText(this, successMsg, Toast.LENGTH_SHORT).show()
                finish()
            }
            is TxInsertResult.Error -> {
                isSaving = false
                btnSave.isEnabled = true
                btnSaveText.text = if (isId) "Simpan Transaksi" else "Save Transaction"
                showError(result.message)
            }
        }
    }

    private fun showError(msg: String) {
        errorText.text = msg
        errorText.visibility = View.VISIBLE
    }

    private fun hideError() {
        errorText.visibility = View.GONE
    }

    @Suppress("DEPRECATION")
    private fun resolveColor(resId: Int): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            getColor(resId)
        } else {
            resources.getColor(resId)
        }
    }

    private fun hideKeyboard() {
        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
        imm?.hideSoftInputFromWindow(inputAmount.windowToken, 0)
    }
}
