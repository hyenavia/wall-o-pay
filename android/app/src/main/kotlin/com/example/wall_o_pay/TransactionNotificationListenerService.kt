package com.example.wall_o_pay

import android.app.Notification
import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

class TransactionNotificationListenerService : NotificationListenerService() {

    // Daftar paket aplikasi bank & dompet digital populer di Indonesia
    private val targetPackages = setOf(
        "com.bca",
        "id.co.bca.mybca",
        "com.bankmandiri.livin",
        "id.co.bri.brimo",
        "src.com.bni",
        "com.gojek.app",
        "id.dana",
        "ovo.id",
        "com.shopee.id"
    )

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return

        val pkg = sbn.packageName ?: return
        val extras = sbn.notification?.extras ?: return

        val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
            ?: extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
            ?: ""

        if (text.isBlank()) return

        val combined = "$title $text".lowercase()

        // Periksa apakah notifikasi berasal dari paket bank/e-wallet ATAU mengandung kata kunci transaksi
        val isTargetApp = targetPackages.contains(pkg) || targetPackages.any { pkg.contains(it) }
        val hasFinancialKeywords = combined.contains("rp") ||
                combined.contains("idr") ||
                combined.contains("berhasil") ||
                combined.contains("transfer") ||
                combined.contains("pembayaran") ||
                combined.contains("qris")

        if (isTargetApp || hasFinancialKeywords) {
            savePendingNotification(pkg, title, text, sbn.postTime)
        }
    }

    private fun savePendingNotification(pkg: String, title: String, text: String, postTime: Long) {
        try {
            val prefs = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val currentRaw = prefs.getString(KEY_NOTIFICATIONS, "[]") ?: "[]"
            val array = JSONArray(currentRaw)

            val item = JSONObject().apply {
                put("id", UUID.randomUUID().toString())
                put("package", pkg)
                put("title", title)
                put("text", text)
                put("timestamp", postTime)
            }

            array.put(item)
            prefs.edit().putString(KEY_NOTIFICATIONS, array.toString()).apply()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    companion object {
        const val PREFS_NAME = "wall_o_pay_notifications"
        const val KEY_NOTIFICATIONS = "pending_notification_list"
    }
}
