package com.example.wall_o_pay

import android.content.Context
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.Calendar
import java.util.concurrent.TimeUnit

class WidgetMidnightWorker(
    appContext: Context,
    params: WorkerParameters,
) : Worker(appContext, params) {

    override fun doWork(): Result {
        if (!WidgetSnapshotStore.hasAnyActiveWidget(applicationContext)) {
            WorkManager.getInstance(applicationContext).cancelUniqueWork(WORK_NAME)
            return Result.success()
        }
        WidgetSnapshotStore.refreshAllWidgets(applicationContext)
        return Result.success()
    }

    companion object {
        private const val WORK_NAME = "wall_o_pay_widget_midnight_rollover"

        fun scheduleIfNeeded(context: Context) {
            val wm = WorkManager.getInstance(context)
            if (!WidgetSnapshotStore.hasAnyActiveWidget(context)) {
                wm.cancelUniqueWork(WORK_NAME)
                return
            }

            val now = Calendar.getInstance()
            val nextMidnight = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, 1)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 5)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val initialDelayMs = (nextMidnight.timeInMillis - now.timeInMillis).coerceAtLeast(60_000L)

            val request = PeriodicWorkRequestBuilder<WidgetMidnightWorker>(24, TimeUnit.HOURS)
                .setInitialDelay(initialDelayMs, TimeUnit.MILLISECONDS)
                .build()

            wm.enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request,
            )
        }

        fun cancelIfNoWidgets(context: Context) {
            if (!WidgetSnapshotStore.hasAnyActiveWidget(context)) {
                WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
            }
        }
    }
}

