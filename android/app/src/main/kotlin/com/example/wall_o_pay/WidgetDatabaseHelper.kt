package com.example.wall_o_pay

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import java.io.File
import java.text.DecimalFormat
import java.text.DecimalFormatSymbols
import java.util.Calendar
import java.util.Locale
import java.util.UUID

data class WidgetWallet(
    val id: String,
    val name: String,
    val type: String,
)

data class WidgetCategory(
    val id: String,
    val name: String,
    val type: String,
)

sealed class TxInsertResult {
    data class Success(val newBalance: Long, val amount: Long) : TxInsertResult()
    data class Error(val message: String, val isDbMissing: Boolean = false) : TxInsertResult()
}

object WidgetDatabaseHelper {
    const val PREFS_NAME = "quick_finance_widget"
    const val KEY_SELECTED_TAB = "selected_tab"
    const val KEY_BALANCE = "total_balance"
    const val KEY_HIDE_BALANCE = "hide_balance"
    const val KEY_LOCALE = "locale"
    const val KEY_QUEUED_AMOUNT = "queued_amount"
    const val KEY_SELECTED_WALLET_ID = "selected_wallet_id"
    const val KEY_SELECTED_TO_WALLET_ID = "selected_to_wallet_id"
    const val KEY_SELECTED_INCOME_CAT_ID = "selected_income_cat_id"
    const val KEY_SELECTED_EXPENSE_CAT_ID = "selected_expense_cat_id"
    const val KEY_FEEDBACK_TEXT = "feedback_text"
    const val KEY_FEEDBACK_IS_ERROR = "feedback_is_error"
    const val KEY_NATIVE_DB_DIRTY = "native_db_dirty"

    private const val DB_FILE_NAME = "wall_o_pay.sqlite"
    private const val MAX_AMOUNT = 999_999_999_999L
    private val dbLock = Any()

    fun getLocale(context: Context): String {
        val widgetPrefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val cached = widgetPrefs.getString(KEY_LOCALE, null)
        if (cached == "id" || cached == "en") return cached

        // Fallback to Flutter SharedPreferences if widget hasn't synced locale yet
        val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val flutterLocale = flutterPrefs.getString("flutter.pref_locale", null)
        if (flutterLocale == "id" || flutterLocale == "en") return flutterLocale

        return if (Locale.getDefault().language == "id" || Locale.getDefault().language == "in") "id" else "en"
    }

    fun formatRupiah(amount: Long): String {
        val symbols = DecimalFormatSymbols(Locale("id", "ID"))
        val formatter = DecimalFormat("#,###", symbols)
        return "Rp ${formatter.format(amount)}"
    }

    fun formatCompactPreset(amount: Long): String {
        return when {
            amount >= 1_000_000L -> "+${amount / 1_000_000L}M"
            amount >= 1_000L -> "+${amount / 1_000L}k"
            else -> "+$amount"
        }
    }

    private fun getDatabaseFile(context: Context): File {
        val flutterDir = context.getDir("flutter", Context.MODE_PRIVATE)
        return File(flutterDir, DB_FILE_NAME)
    }

    fun isDatabaseReady(context: Context): Boolean {
        val dbFile = getDatabaseFile(context)
        if (!dbFile.exists() || dbFile.length() == 0L) return false
        return synchronized(dbLock) {
            try {
                SQLiteDatabase.openDatabase(
                    dbFile.absolutePath,
                    null,
                    SQLiteDatabase.OPEN_READONLY
                ).use { db ->
                    hasRequiredTables(db)
                }
            } catch (_: Exception) {
                false
            }
        }
    }

    private fun hasRequiredTables(db: SQLiteDatabase): Boolean {
        val required = setOf("transactions", "wallets", "categories")
        var found = 0
        db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('transactions','wallets','categories')",
            null
        ).use { cursor ->
            while (cursor.moveToNext()) {
                if (required.contains(cursor.getString(0))) found++
            }
        }
        return found == required.size
    }

    fun getActiveWallets(context: Context): List<WidgetWallet> {
        val dbFile = getDatabaseFile(context)
        if (!dbFile.exists()) return emptyList()
        return synchronized(dbLock) {
            try {
                SQLiteDatabase.openDatabase(
                    dbFile.absolutePath,
                    null,
                    SQLiteDatabase.OPEN_READONLY
                ).use { db ->
                    if (!hasRequiredTables(db)) return@synchronized emptyList()
                    val result = mutableListOf<WidgetWallet>()
                    db.rawQuery(
                        """
                        SELECT id, name, type FROM wallets
                        WHERE deleted_at IS NULL
                        ORDER BY
                          CASE LOWER(type)
                            WHEN 'bank' THEN 0
                            WHEN 'digital' THEN 1
                            WHEN 'ewallet' THEN 2
                            WHEN 'cash' THEN 3
                            ELSE 99
                          END ASC,
                          created_at ASC
                        """.trimIndent(),
                        null
                    ).use { cursor ->
                        while (cursor.moveToNext()) {
                            result.add(
                                WidgetWallet(
                                    id = cursor.getString(0),
                                    name = cursor.getString(1),
                                    type = cursor.getString(2),
                                )
                            )
                        }
                    }
                    result
                }
            } catch (_: Exception) {
                emptyList()
            }
        }
    }

    fun getActiveCategories(context: Context, txType: String): List<WidgetCategory> {
        val dbFile = getDatabaseFile(context)
        if (!dbFile.exists()) return emptyList()
        return synchronized(dbLock) {
            try {
                SQLiteDatabase.openDatabase(
                    dbFile.absolutePath,
                    null,
                    SQLiteDatabase.OPEN_READONLY
                ).use { db ->
                    if (!hasRequiredTables(db)) return@synchronized emptyList()
                    val result = mutableListOf<WidgetCategory>()
                    db.rawQuery(
                        """
                        SELECT c.id, c.name, c.type, COALESCE(u.cnt, 0) AS usage_cnt
                        FROM categories c
                        LEFT JOIN (
                            SELECT category_id, COUNT(*) AS cnt
                            FROM transactions
                            WHERE deleted_at IS NULL
                            GROUP BY category_id
                        ) u ON u.category_id = c.id
                        WHERE c.deleted_at IS NULL AND c.type = ?
                        ORDER BY usage_cnt DESC, c.name ASC
                        """.trimIndent(),
                        arrayOf(txType)
                    ).use { cursor ->
                        while (cursor.moveToNext()) {
                            result.add(
                                WidgetCategory(
                                    id = cursor.getString(0),
                                    name = cursor.getString(1),
                                    type = cursor.getString(2),
                                )
                            )
                        }
                    }
                    result
                }
            } catch (_: Exception) {
                emptyList()
            }
        }
    }

    fun getTotalBalance(context: Context): Long? {
        val dbFile = getDatabaseFile(context)
        if (!dbFile.exists()) return null
        return synchronized(dbLock) {
            try {
                SQLiteDatabase.openDatabase(
                    dbFile.absolutePath,
                    null,
                    SQLiteDatabase.OPEN_READONLY
                ).use { db ->
                    if (!hasRequiredTables(db)) return@synchronized null
                    queryTotalBalance(db)
                }
            } catch (_: Exception) {
                null
            }
        }
    }

    private fun queryTotalBalance(db: SQLiteDatabase): Long {
        var initialSum = 0L
        db.rawQuery(
            "SELECT COALESCE(SUM(initial_balance), 0) FROM wallets WHERE deleted_at IS NULL",
            null
        ).use { c ->
            if (c.moveToFirst()) initialSum = c.getLong(0)
        }

        var netFlowSum = 0L
        db.rawQuery(
            """
            SELECT COALESCE(SUM(
                CASE
                    WHEN t.type = 'income' AND t.wallet_id IN (SELECT id FROM wallets WHERE deleted_at IS NULL) THEN t.amount
                    WHEN t.type = 'expense' AND t.wallet_id IN (SELECT id FROM wallets WHERE deleted_at IS NULL) THEN -t.amount
                    WHEN t.type = 'transfer' THEN
                        (CASE WHEN t.to_wallet_id IN (SELECT id FROM wallets WHERE deleted_at IS NULL) THEN t.amount ELSE 0 END)
                        - (CASE WHEN t.wallet_id IN (SELECT id FROM wallets WHERE deleted_at IS NULL) THEN t.amount ELSE 0 END)
                    ELSE 0
                END
            ), 0)
            FROM transactions t
            WHERE t.deleted_at IS NULL
            """.trimIndent(),
            null
        ).use { c ->
            if (c.moveToFirst()) netFlowSum = c.getLong(0)
        }

        return initialSum + netFlowSum
    }

    fun insertTransaction(
        context: Context,
        type: String,
        amount: Long,
        categoryId: String?,
        walletId: String?,
        toWalletId: String?,
        note: String,
    ): TxInsertResult {
        val locale = getLocale(context)
        val isId = locale == "id"

        if (amount <= 0L) {
            return TxInsertResult.Error(
                if (isId) "Nominal harus lebih dari 0." else "Amount must be greater than 0."
            )
        }
        if (amount > MAX_AMOUNT) {
            return TxInsertResult.Error(
                if (isId) "Nominal terlalu besar." else "Amount exceeds maximum limit."
            )
        }
        if (type != "income" && type != "expense" && type != "transfer") {
            return TxInsertResult.Error(
                if (isId) "Jenis transaksi tidak valid." else "Invalid transaction type."
            )
        }

        val dbFile = getDatabaseFile(context)
        if (!dbFile.exists() || dbFile.length() == 0L) {
            return TxInsertResult.Error(
                if (isId) "Buka aplikasi sekali untuk inisialisasi database." else "Open Wall o' Pay once to initialize database.",
                isDbMissing = true
            )
        }

        return synchronized(dbLock) {
            try {
                SQLiteDatabase.openDatabase(
                    dbFile.absolutePath,
                    null,
                    SQLiteDatabase.OPEN_READWRITE
                ).use { db ->
                    db.rawQuery("PRAGMA busy_timeout = 3000", null).use { it.moveToFirst() }

                    if (!hasRequiredTables(db)) {
                        return@synchronized TxInsertResult.Error(
                            if (isId) "Database belum siap. Buka aplikasi terlebih dahulu." else "Database not initialized yet. Open app first.",
                            isDbMissing = true
                        )
                    }

                    // Validate source/primary wallet
                    if (walletId.isNullOrBlank() || !existsActiveRow(db, "wallets", walletId)) {
                        return@synchronized TxInsertResult.Error(
                            if (isId) "Akun tidak ditemukan." else "Account not found."
                        )
                    }

                    val effectiveCategoryId: String
                    var effectiveToWalletId: String? = null

                    if (type == "transfer") {
                        if (toWalletId.isNullOrBlank() || !existsActiveRow(db, "wallets", toWalletId)) {
                            return@synchronized TxInsertResult.Error(
                                if (isId) "Akun tujuan tidak ditemukan." else "Destination account not found."
                            )
                        }
                        if (walletId == toWalletId) {
                            return@synchronized TxInsertResult.Error(
                                if (isId) "Akun sumber dan tujuan tidak boleh sama." else "Source and destination accounts must be different."
                            )
                        }
                        effectiveCategoryId = "cat-tra-transfer"
                        effectiveToWalletId = toWalletId
                    } else {
                        if (categoryId.isNullOrBlank() || !existsActiveCategory(db, categoryId, type)) {
                            return@synchronized TxInsertResult.Error(
                                if (isId) "Kategori tidak valid atau tidak ditemukan." else "Category is invalid or not found."
                            )
                        }
                        effectiveCategoryId = categoryId
                    }

                    val nowSeconds = System.currentTimeMillis() / 1000L
                    val dayCal = Calendar.getInstance().apply {
                        set(Calendar.HOUR_OF_DAY, 0)
                        set(Calendar.MINUTE, 0)
                        set(Calendar.SECOND, 0)
                        set(Calendar.MILLISECOND, 0)
                    }
                    val daySeconds = dayCal.timeInMillis / 1000L

                    val txId = UUID.randomUUID().toString()
                    val values = ContentValues().apply {
                        put("id", txId)
                        put("created_at", nowSeconds)
                        put("updated_at", nowSeconds)
                        putNull("deleted_at")
                        put("amount", amount)
                        put("type", type)
                        put("category_id", effectiveCategoryId)
                        put("note", note.trim())
                        put("date", daySeconds)
                        put("wallet_id", walletId)
                        if (effectiveToWalletId != null) {
                            put("to_wallet_id", effectiveToWalletId)
                        } else {
                            putNull("to_wallet_id")
                        }
                        putNull("receipt_path")
                        putNull("need_want")
                    }

                    db.beginTransaction()
                    try {
                        val rowId = db.insertOrThrow("transactions", null, values)
                        if (rowId == -1L) {
                            throw IllegalStateException("Insert returned -1")
                        }
                        db.setTransactionSuccessful()
                    } finally {
                        db.endTransaction()
                    }

                    val newBalance = queryTotalBalance(db)

                    val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    val hideBalance = prefs.getBoolean(KEY_HIDE_BALANCE, false)
                    val editor = prefs.edit()
                        .putBoolean(KEY_NATIVE_DB_DIRTY, true)
                    if (!hideBalance) {
                        editor.putLong(KEY_BALANCE, newBalance)
                    } else {
                        editor.remove(KEY_BALANCE)
                    }
                    editor.apply()

                    TxInsertResult.Success(newBalance = newBalance, amount = amount)
                }
            } catch (e: Exception) {
                TxInsertResult.Error(
                    if (isId) "Gagal menyimpan transaksi: ${e.localizedMessage ?: "kesalahan"}"
                    else "Failed to save transaction: ${e.localizedMessage ?: "error"}"
                )
            }
        }
    }

    private fun existsActiveRow(db: SQLiteDatabase, table: String, id: String): Boolean {
        db.rawQuery(
            "SELECT 1 FROM $table WHERE id = ? AND deleted_at IS NULL LIMIT 1",
            arrayOf(id)
        ).use { c ->
            return c.moveToFirst()
        }
    }

    private fun existsActiveCategory(db: SQLiteDatabase, id: String, type: String): Boolean {
        db.rawQuery(
            "SELECT 1 FROM categories WHERE id = ? AND type = ? AND deleted_at IS NULL LIMIT 1",
            arrayOf(id, type)
        ).use { c ->
            return c.moveToFirst()
        }
    }

    fun localizeLabel(raw: String, locale: String): String {
        if (locale != "id") {
            return when (raw) {
                "Rekening Utama" -> "Main Account"
                "Bank Konvensional" -> "Commercial Bank"
                "Bank Digital" -> "Digital Bank"
                "Tunai" -> "Cash"
                "Makanan", "Makan & minum", "Makanan & Minuman" -> "Food & Drinks"
                "Transportasi" -> "Transport"
                "Kos & tagihan", "Sewa & Tagihan" -> "Rent & Bills"
                "Kuliah", "Pendidikan" -> "Education"
                "Belanja" -> "Shopping"
                "Hiburan" -> "Entertainment"
                "Kesehatan" -> "Health"
                "Lainnya" -> "Other"
                "Kiriman orang tua", "Kiriman Orang Tua" -> "Parents' allowance"
                "Beasiswa" -> "Scholarship"
                "Part-time", "Kerja paruh waktu", "Paruh Waktu" -> "Part-time job"
                else -> raw
            }
        }
        return when (raw) {
            "Main Account" -> "Rekening Utama"
            "Commercial Bank" -> "Bank Konvensional"
            "Digital Bank" -> "Bank Digital"
            "Cash" -> "Tunai"
            "Food & Drinks" -> "Makanan & Minuman"
            "Transport" -> "Transportasi"
            "Rent & Bills" -> "Sewa & Tagihan"
            "Education" -> "Pendidikan"
            "Shopping" -> "Belanja"
            "Entertainment" -> "Hiburan"
            "Health" -> "Kesehatan"
            "Other" -> "Lainnya"
            "Parents' allowance" -> "Kiriman orang tua"
            "Scholarship" -> "Beasiswa"
            "Part-time job" -> "Kerja paruh waktu"
            "Transfer" -> "Transfer"
            else -> raw
        }
    }
}
