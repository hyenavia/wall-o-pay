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

data class WidgetTemplate(
    val id: String,
    val name: String,
    val type: String,
    val amount: Long,
    val categoryId: String,
    val walletId: String?,
    val needWant: String?,
    val note: String,
)

sealed class TxInsertResult {
    data class Success(val newBalance: Long, val amount: Long, val txId: String = "") : TxInsertResult()
    data class Error(val message: String, val isDbMissing: Boolean = false) : TxInsertResult()
}

data class WidgetSnapshot(
    val dbReady: Boolean,
    val totalBalance: Long?,
    val wallets: List<WidgetWallet>,
    val categories: List<WidgetCategory>,
)

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

    fun formatCompactRupiah(value: Long, isId: Boolean): String {
        val absVal = kotlin.math.abs(value)
        val sign = if (value < 0L) "-" else ""

        fun fmt(n: Double): String {
            val rounded = kotlin.math.round(n * 10.0) / 10.0
            val str = if (rounded == kotlin.math.round(rounded)) {
                rounded.toLong().toString()
            } else {
                String.format(Locale.US, "%.1f", rounded)
            }
            return if (isId) str.replace('.', ',') else str
        }

        return when {
            absVal >= 1_000_000_000L -> "${sign}Rp ${fmt(absVal / 1_000_000_000.0)}${if (isId) "M" else "B"}"
            absVal >= 1_000_000L -> "${sign}Rp ${fmt(absVal / 1_000_000.0)}${if (isId) "jt" else "M"}"
            absVal >= 10_000L -> "${sign}Rp ${fmt(absVal / 1_000.0)}${if (isId) "rb" else "K"}"
            absVal >= 1_000L && absVal % 1_000L == 0L -> "${sign}Rp ${absVal / 1_000L}${if (isId) "rb" else "K"}"
            else -> "${sign}${formatRupiah(absVal)}"
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

    fun loadWidgetSnapshot(
        context: Context,
        txType: String,
        includeBalance: Boolean,
    ): WidgetSnapshot {
        val dbFile = getDatabaseFile(context)
        if (!dbFile.exists() || dbFile.length() == 0L) {
            return WidgetSnapshot(
                dbReady = false,
                totalBalance = null,
                wallets = emptyList(),
                categories = emptyList(),
            )
        }
        return synchronized(dbLock) {
            try {
                SQLiteDatabase.openDatabase(
                    dbFile.absolutePath,
                    null,
                    SQLiteDatabase.OPEN_READONLY
                ).use { db ->
                    if (!hasRequiredTables(db)) {
                        return@synchronized WidgetSnapshot(
                            dbReady = false,
                            totalBalance = null,
                            wallets = emptyList(),
                            categories = emptyList(),
                        )
                    }
                    val totalBalance = if (includeBalance) queryTotalBalance(db) else null
                    val wallets = queryActiveWallets(db)
                    val categories = if (txType == "income" || txType == "expense") {
                        queryActiveCategories(db, txType)
                    } else {
                        emptyList()
                    }
                    WidgetSnapshot(
                        dbReady = true,
                        totalBalance = totalBalance,
                        wallets = wallets,
                        categories = categories,
                    )
                }
            } catch (_: Exception) {
                WidgetSnapshot(
                    dbReady = false,
                    totalBalance = null,
                    wallets = emptyList(),
                    categories = emptyList(),
                )
            }
        }
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
                    queryActiveWallets(db)
                }
            } catch (_: Exception) {
                emptyList()
            }
        }
    }

    private fun queryActiveWallets(db: SQLiteDatabase): List<WidgetWallet> {
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
        return result
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
                    queryActiveCategories(db, txType)
                }
            } catch (_: Exception) {
                emptyList()
            }
        }
    }

    private fun queryActiveCategories(db: SQLiteDatabase, txType: String): List<WidgetCategory> {
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
        return result
    }

    fun getActiveTemplates(context: Context, limit: Int = 4): List<WidgetTemplate> {
        val dbFile = getDatabaseFile(context)
        if (!dbFile.exists() || dbFile.length() == 0L) return emptyList()
        return synchronized(dbLock) {
            try {
                SQLiteDatabase.openDatabase(
                    dbFile.absolutePath,
                    null,
                    SQLiteDatabase.OPEN_READONLY
                ).use { db ->
                    if (!hasRequiredTables(db)) return@synchronized emptyList()
                    var hasTemplatesTable = false
                    db.rawQuery(
                        "SELECT 1 FROM sqlite_master WHERE type='table' AND name='tx_templates' LIMIT 1",
                        null
                    ).use { c -> hasTemplatesTable = c.moveToFirst() }
                    if (!hasTemplatesTable) return@synchronized emptyList()
                    queryActiveTemplates(db, limit)
                }
            } catch (_: Exception) {
                emptyList()
            }
        }
    }

    private fun queryActiveTemplates(db: SQLiteDatabase, limit: Int): List<WidgetTemplate> {
        val result = mutableListOf<WidgetTemplate>()
        db.rawQuery(
            """
            SELECT id, name, type, amount, category_id, wallet_id, need_want, note
            FROM tx_templates
            WHERE deleted_at IS NULL
            ORDER BY LOWER(name) ASC, created_at ASC
            LIMIT ?
            """.trimIndent(),
            arrayOf(limit.toString())
        ).use { cursor ->
            while (cursor.moveToNext()) {
                result.add(
                    WidgetTemplate(
                        id = cursor.getString(0),
                        name = cursor.getString(1),
                        type = cursor.getString(2),
                        amount = cursor.getLong(3),
                        categoryId = cursor.getString(4),
                        walletId = if (cursor.isNull(5)) null else cursor.getString(5),
                        needWant = if (cursor.isNull(6)) null else cursor.getString(6),
                        note = if (cursor.isNull(7)) "" else cursor.getString(7),
                    )
                )
            }
        }
        return result
    }

    fun getTodayExpense(context: Context): Long {
        val dbFile = getDatabaseFile(context)
        if (!dbFile.exists()) return 0L
        return synchronized(dbLock) {
            try {
                SQLiteDatabase.openDatabase(
                    dbFile.absolutePath,
                    null,
                    SQLiteDatabase.OPEN_READONLY
                ).use { db ->
                    if (!hasRequiredTables(db)) return@synchronized 0L
                    queryTodayExpense(db)
                }
            } catch (_: Exception) {
                0L
            }
        }
    }

    private fun queryTodayExpense(db: SQLiteDatabase): Long {
        val startCal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startSec = startCal.timeInMillis / 1000L
        val endSec = startSec + 86400L
        db.rawQuery(
            """
            SELECT COALESCE(SUM(amount), 0)
            FROM transactions
            WHERE deleted_at IS NULL
              AND type = 'expense'
              AND date >= ?
              AND date < ?
            """.trimIndent(),
            arrayOf(startSec.toString(), endSec.toString())
        ).use { c ->
            return if (c.moveToFirst()) c.getLong(0) else 0L
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
        needWant: String? = null,
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

                    // Validate source/primary wallet (or resolve fallback first active wallet when omitted)
                    val resolvedWalletId = if (!walletId.isNullOrBlank() && existsActiveRow(db, "wallets", walletId)) {
                        walletId
                    } else if (walletId.isNullOrBlank()) {
                        queryActiveWallets(db).firstOrNull()?.id
                    } else {
                        null
                    }
                    if (resolvedWalletId.isNullOrBlank()) {
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
                        if (resolvedWalletId == toWalletId) {
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
                        put("wallet_id", resolvedWalletId)
                        if (effectiveToWalletId != null) {
                            put("to_wallet_id", effectiveToWalletId)
                        } else {
                            putNull("to_wallet_id")
                        }
                        putNull("receipt_path")
                        if (!needWant.isNullOrBlank() && (needWant == "need" || needWant == "want") && type == "expense") {
                            put("need_want", needWant)
                        } else {
                            putNull("need_want")
                        }
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
                    val newTodayExpense = queryTodayExpense(db)

                    val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    val hideBalance = prefs.getBoolean(KEY_HIDE_BALANCE, false)
                    val editor = prefs.edit()
                        .putBoolean(KEY_NATIVE_DB_DIRTY, true)
                    if (!hideBalance) {
                        editor.putLong(KEY_BALANCE, newBalance)
                        editor.putLong(WidgetSnapshotStore.KEY_TODAY_EXPENSE, newTodayExpense)
                        editor.putString(WidgetSnapshotStore.KEY_SNAPSHOT_DATE_YMD, WidgetSnapshotStore.todayYmd())
                    } else {
                        editor.remove(KEY_BALANCE)
                        editor.remove(WidgetSnapshotStore.KEY_TODAY_EXPENSE)
                    }
                    val dailyAllowance = prefs.getLong(WidgetSnapshotStore.KEY_DAILY_ALLOWANCE, 0L)
                    val currentTier = prefs.getString(WidgetSnapshotStore.KEY_PULSE_TIER, "safe")
                    if (!hideBalance && type == "expense" && dailyAllowance > 0L && newTodayExpense > dailyAllowance && currentTier == "safe") {
                        editor.putString(WidgetSnapshotStore.KEY_PULSE_TIER, "caution")
                    }
                    if (!hideBalance && type == "expense") {
                        WidgetSnapshotStore.adjustBudgetOnNativeTx(
                            prefs = prefs,
                            editor = editor,
                            amountDelta = amount,
                            categoryId = effectiveCategoryId,
                            txDateSec = daySeconds,
                        )
                    }
                    editor.commit()

                    TxInsertResult.Success(newBalance = newBalance, amount = amount, txId = txId)
                }
            } catch (e: Exception) {
                TxInsertResult.Error(
                    if (isId) "Gagal menyimpan transaksi: ${e.localizedMessage ?: "kesalahan"}"
                    else "Failed to save transaction: ${e.localizedMessage ?: "error"}"
                )
            }
        }
    }

    fun softDeleteTransaction(context: Context, txId: String): Boolean {
        if (txId.isBlank()) return false
        val dbFile = getDatabaseFile(context)
        if (!dbFile.exists() || dbFile.length() == 0L) return false
        return synchronized(dbLock) {
            try {
                SQLiteDatabase.openDatabase(
                    dbFile.absolutePath,
                    null,
                    SQLiteDatabase.OPEN_READWRITE
                ).use { db ->
                    db.rawQuery("PRAGMA busy_timeout = 3000", null).use { it.moveToFirst() }
                    if (!hasRequiredTables(db)) return@synchronized false

                    var txType: String? = null
                    var txAmount = 0L
                    var txCatId = ""
                    var txDateSec = 0L
                    db.rawQuery(
                        "SELECT type, amount, category_id, date FROM transactions WHERE id = ? AND deleted_at IS NULL LIMIT 1",
                        arrayOf(txId)
                    ).use { c ->
                        if (c.moveToFirst()) {
                            txType = c.getString(0)
                            txAmount = c.getLong(1)
                            txCatId = c.getString(2)
                            txDateSec = c.getLong(3)
                        }
                    }
                    if (txType == null) return@synchronized false

                    val nowSeconds = System.currentTimeMillis() / 1000L
                    val values = ContentValues().apply {
                        put("deleted_at", nowSeconds)
                        put("updated_at", nowSeconds)
                    }
                    val updatedRows = db.update("transactions", values, "id = ? AND deleted_at IS NULL", arrayOf(txId))
                    if (updatedRows <= 0) return@synchronized false

                    val newBalance = queryTotalBalance(db)
                    val newTodayExpense = queryTodayExpense(db)

                    val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    val hideBalance = prefs.getBoolean(KEY_HIDE_BALANCE, false)
                    val editor = prefs.edit().putBoolean(KEY_NATIVE_DB_DIRTY, true)
                    if (!hideBalance) {
                        editor.putLong(KEY_BALANCE, newBalance)
                        editor.putLong(WidgetSnapshotStore.KEY_TODAY_EXPENSE, newTodayExpense)
                        editor.putString(WidgetSnapshotStore.KEY_SNAPSHOT_DATE_YMD, WidgetSnapshotStore.todayYmd())
                        val dailyAllowance = prefs.getLong(WidgetSnapshotStore.KEY_DAILY_ALLOWANCE, 0L)
                        val currentTier = prefs.getString(WidgetSnapshotStore.KEY_PULSE_TIER, "safe")
                        if (txType == "expense" && dailyAllowance > 0L && newTodayExpense <= dailyAllowance && currentTier == "caution") {
                            editor.putString(WidgetSnapshotStore.KEY_PULSE_TIER, "safe")
                        }
                        if (txType == "expense") {
                            WidgetSnapshotStore.adjustBudgetOnNativeTx(
                                prefs = prefs,
                                editor = editor,
                                amountDelta = -txAmount,
                                categoryId = txCatId,
                                txDateSec = txDateSec,
                            )
                        }
                    } else {
                        editor.remove(KEY_BALANCE)
                        editor.remove(WidgetSnapshotStore.KEY_TODAY_EXPENSE)
                    }
                    editor.commit()
                    true
                }
            } catch (_: Exception) {
                false
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
                "Biaya Admin" -> "Admin Fee"
                "Setoran Tabungan" -> "Savings Deposit"
                "Penarikan Tabungan" -> "Savings Withdrawal"
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
            "Admin Fee" -> "Biaya Admin"
            "Savings Deposit" -> "Setoran Tabungan"
            "Savings Withdrawal" -> "Penarikan Tabungan"
            "Other" -> "Lainnya"
            "Parents' allowance" -> "Kiriman orang tua"
            "Scholarship" -> "Beasiswa"
            "Part-time job" -> "Kerja paruh waktu"
            "Transfer" -> "Transfer"
            else -> raw
        }
    }
}
