package com.kintsugi.amica

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import kotlin.math.max

/**
 * Waits out a scheduled Fake Call and then opens the incoming call screen.
 *
 * Fake Call works as a deterrent when the user can arm it *before* the risky
 * moment — schedule a call, put the phone away, get in the vehicle — so the
 * wait has to survive the app being backgrounded or the screen being locked.
 * A Dart `Timer` dies with the screen, so the countdown is held here in a
 * foreground service with a partial wake lock, mirroring how
 * [EmergencySafetyMonitorService] keeps a journey timer alive.
 *
 * When the schedule fires, the call screen is launched directly and a
 * full-screen call-style notification is posted as a fallback, because Android
 * blocks background activity launches on some versions and battery modes.
 */
class FakeCallSchedulerService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var scheduledCall: Runnable? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var callerName = DEFAULT_CALLER_NAME

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return when (intent?.action) {
            ACTION_START -> {
                startScheduling(
                    triggerAtMillis = intent.getLongExtra(
                        EXTRA_TRIGGER_AT_MILLIS,
                        0L,
                    ),
                    callerName = intent.getStringExtra(EXTRA_CALLER_NAME),
                )
                START_STICKY
            }
            ACTION_STOP -> {
                cancelScheduling()
                START_NOT_STICKY
            }
            // Android restarted the sticky service with no intent. Re-arm from
            // the persisted trigger so a pending call is never silently lost
            // while the app still shows a countdown for it.
            else -> {
                restoreScheduling()
                START_STICKY
            }
        }
    }

    override fun onDestroy() {
        cancelScheduledCall()
        releaseWakeLock()
        super.onDestroy()
    }

    private fun startScheduling(triggerAtMillis: Long, callerName: String?) {
        cancelScheduledCall()

        this.callerName = callerName?.takeIf { it.isNotBlank() }
            ?: DEFAULT_CALLER_NAME

        // Go foreground before any early return: Android kills the process if
        // startForegroundService() is not followed by startForeground().
        createNotificationChannels()
        startForegroundCompat(buildSchedulingNotification(triggerAtMillis))

        if (triggerAtMillis <= System.currentTimeMillis()) {
            cancelScheduling()
            return
        }

        saveScheduledTrigger(this, triggerAtMillis, this.callerName)
        acquireWakeLockUntil(triggerAtMillis)

        val runnable = Runnable {
            clearScheduledTrigger(this)
            openCallScreen()
            stopScheduling()
        }
        scheduledCall = runnable
        handler.postDelayed(
            runnable,
            max(0L, triggerAtMillis - System.currentTimeMillis()),
        )
    }

    private fun restoreScheduling() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val triggerAtMillis = prefs.getLong(PREF_TRIGGER_AT_MILLIS, 0L)

        if (triggerAtMillis <= System.currentTimeMillis()) {
            cancelScheduling()
            return
        }

        startScheduling(
            triggerAtMillis = triggerAtMillis,
            callerName = prefs.getString(PREF_CALLER_NAME, null),
        )
    }

    private fun cancelScheduling() {
        clearScheduledTrigger(this)
        stopScheduling()
    }

    private fun stopScheduling() {
        cancelScheduledCall()
        releaseWakeLock()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    private fun cancelScheduledCall() {
        scheduledCall?.let { handler.removeCallbacks(it) }
        scheduledCall = null
    }

    private fun openCallScreen() {
        val intent = callScreenIntent()
        try {
            startActivity(intent)
        } catch (_: Exception) {
            // Android may block direct background activity launches. The
            // call-style notification below gives the user a visible fallback.
        }

        notificationManager().notify(
            CALL_NOTIFICATION_ID,
            buildIncomingCallNotification(intent),
        )
    }

    private fun callScreenIntent(): Intent {
        return Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_OPEN_SCHEDULED_CALL, true)
        }
    }

    private fun acquireWakeLockUntil(triggerAtMillis: Long) {
        releaseWakeLock()
        val holdMillis = max(
            60_000L,
            triggerAtMillis - System.currentTimeMillis() + 30_000L,
        )
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "Amica::FakeCallScheduler",
        ).apply {
            setReferenceCounted(false)
            acquire(holdMillis)
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        wakeLock = null
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val schedulerChannel = NotificationChannel(
            SCHEDULER_CHANNEL_ID,
            "Amica scheduled calls",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Counts down to a scheduled call."
        }

        val callChannel = NotificationChannel(
            CALL_CHANNEL_ID,
            "Incoming calls",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Shows the call screen when a scheduled call is due."
            setSound(null, null)
        }

        notificationManager().apply {
            createNotificationChannel(schedulerChannel)
            createNotificationChannel(callChannel)
        }
    }

    private fun startForegroundCompat(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                SCHEDULER_NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(SCHEDULER_NOTIFICATION_ID, notification)
        }
    }

    private fun buildSchedulingNotification(triggerAtMillis: Long): Notification {
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPendingIntent = PendingIntent.getActivity(
            this,
            0,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentImmutableFlag(),
        )
        val cancelPendingIntent = PendingIntent.getService(
            this,
            1,
            stopIntent(this),
            PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentImmutableFlag(),
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, SCHEDULER_CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }

        builder
            .setSmallIcon(android.R.drawable.ic_menu_recent_history)
            .setContentTitle("Call scheduled")
            .setContentText("$callerName will call you shortly.")
            .setContentIntent(openPendingIntent)
            .setOngoing(true)
            .setPriority(Notification.PRIORITY_LOW)
            .addAction(
                Notification.Action.Builder(
                    null,
                    "Cancel",
                    cancelPendingIntent,
                ).build(),
            )

        // A live countdown in the shade, without waking the service every
        // second just to rewrite the notification text.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            builder
                .setUsesChronometer(true)
                .setChronometerCountDown(true)
                .setWhen(triggerAtMillis)
                .setShowWhen(true)
        }

        return builder.build()
    }

    private fun buildIncomingCallNotification(intent: Intent): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            2,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentImmutableFlag(),
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CALL_CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }

        return builder
            .setSmallIcon(android.R.drawable.sym_call_incoming)
            .setContentTitle("Incoming call")
            .setContentText(callerName)
            .setContentIntent(pendingIntent)
            .setFullScreenIntent(pendingIntent, true)
            .setCategory(Notification.CATEGORY_CALL)
            .setPriority(Notification.PRIORITY_MAX)
            .setAutoCancel(true)
            .build()
    }

    private fun notificationManager(): NotificationManager {
        return getSystemService(NOTIFICATION_SERVICE) as NotificationManager
    }

    private fun pendingIntentImmutableFlag(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }
    }

    companion object {
        const val EXTRA_OPEN_SCHEDULED_CALL = "openScheduledCall"

        private const val SCHEDULER_CHANNEL_ID = "amica_fake_call_scheduler"
        private const val CALL_CHANNEL_ID = "amica_incoming_call_scheduled"
        private const val SCHEDULER_NOTIFICATION_ID = 941
        private const val CALL_NOTIFICATION_ID = 942
        private const val ACTION_START = "com.kintsugi.amica.START_FAKE_CALL_SCHEDULE"
        private const val ACTION_STOP = "com.kintsugi.amica.STOP_FAKE_CALL_SCHEDULE"
        private const val EXTRA_TRIGGER_AT_MILLIS = "triggerAtMillis"
        private const val EXTRA_CALLER_NAME = "callerName"
        private const val DEFAULT_CALLER_NAME = "Amica Friend"
        private const val PREFS_NAME = "amica_fake_call_scheduler"
        private const val PREF_TRIGGER_AT_MILLIS = "triggerAtMillis"
        private const val PREF_CALLER_NAME = "callerName"

        fun startIntent(
            context: Context,
            triggerAtMillis: Long,
            callerName: String,
        ): Intent {
            return Intent(context, FakeCallSchedulerService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_TRIGGER_AT_MILLIS, triggerAtMillis)
                putExtra(EXTRA_CALLER_NAME, callerName)
            }
        }

        fun stopIntent(context: Context): Intent {
            return Intent(context, FakeCallSchedulerService::class.java).apply {
                action = ACTION_STOP
            }
        }

        /**
         * Milliseconds left on the current schedule, or 0 when nothing is
         * pending. Read from shared preferences rather than service state so
         * the app can restore its countdown after the UI was closed, and so a
         * schedule that outlived its service does not strand the UI.
         */
        fun remainingMillis(context: Context): Long {
            val triggerAtMillis = context
                .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .getLong(PREF_TRIGGER_AT_MILLIS, 0L)
            if (triggerAtMillis <= 0L) {
                return 0L
            }
            return max(0L, triggerAtMillis - System.currentTimeMillis())
        }

        private fun saveScheduledTrigger(
            context: Context,
            triggerAtMillis: Long,
            callerName: String,
        ) {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .putLong(PREF_TRIGGER_AT_MILLIS, triggerAtMillis)
                .putString(PREF_CALLER_NAME, callerName)
                .apply()
        }

        private fun clearScheduledTrigger(context: Context) {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .remove(PREF_TRIGGER_AT_MILLIS)
                .remove(PREF_CALLER_NAME)
                .apply()
        }
    }
}
