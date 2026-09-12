package com.kintsugi.amica

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.telephony.SmsManager
import kotlin.math.max

class EmergencySafetyMonitorService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private val scheduledActions = mutableListOf<Runnable>()
    private var wakeLock: PowerManager.WakeLock? = null
    private var emergencyPhone = ""
    private var emergencyMessage = ""
    private var emergencyPhones: List<String> = emptyList()

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return when (intent?.action) {
            ACTION_START -> {
                startMonitoring(intent)
                START_STICKY
            }
            ACTION_STOP -> {
                stopMonitoring()
                START_NOT_STICKY
            }
            else -> START_NOT_STICKY
        }
    }

    override fun onDestroy() {
        cancelScheduledActions()
        releaseWakeLock()
        super.onDestroy()
    }

    private fun startMonitoring(intent: Intent) {
        cancelScheduledActions()

        val destinationName = intent.getStringExtra(EXTRA_DESTINATION_NAME)
            ?.takeIf { it.isNotBlank() }
            ?: "your destination"
        val safetyCheckAtMillis = intent.getLongExtra(
            EXTRA_SAFETY_CHECK_AT_MILLIS,
            0L,
        )
        emergencyPhone = intent.getStringExtra(EXTRA_EMERGENCY_PHONE).orEmpty()
        emergencyPhones = intent.getStringArrayListExtra("emergencyPhones")
            ?.filter { it.isNotBlank() }?.distinct().orEmpty()
        if (emergencyPhones.isEmpty() && emergencyPhone.isNotBlank()) {
            emergencyPhones = listOf(emergencyPhone)
        }
        emergencyMessage = intent.getStringExtra(EXTRA_EMERGENCY_MESSAGE)
            .orEmpty()

        if (safetyCheckAtMillis <= 0L) {
            stopMonitoring()
            return
        }

        createNotificationChannel()
        startForegroundCompat(
            buildNotification(
                title = "Journey safety timer running",
                text = "Amica is monitoring your trip to $destinationName.",
            ),
        )
        acquireWakeLockUntil(safetyCheckAtMillis + CALL_DELAY_MILLIS + 60_000L)

        scheduleAt(safetyCheckAtMillis) {
            vibrateTwice()
            showSafetyCheckAlertNotification()
            updateNotification(
                title = "Safety check due",
                text = "Amica is waiting for your safety response.",
            )
        }

        scheduleAt(safetyCheckAtMillis + SMS_DELAY_MILLIS) {
            if (emergencyPhone.isNotBlank() && emergencyMessage.isNotBlank()) {
                var submitted = 0
                for (phone in emergencyPhones) {
                    try {
                        sendSmsDirectly(phone, emergencyMessage)
                        submitted++
                    } catch (_: Exception) {
                        // One failed recipient must not block the others.
                    }
                }
                updateNotification(
                    title = "Emergency SMS submission",
                    text = "$submitted of ${emergencyPhones.size} submitted. Delivery depends on your network.",
                )
            }
        }

        scheduleAt(safetyCheckAtMillis + CALL_DELAY_MILLIS) {
            // Persist the unanswered check so Flutter can sync it after unlocking.
            getSharedPreferences("amica_vehicle_escalations", MODE_PRIVATE).edit()
                .putBoolean(intent.getStringExtra(EXTRA_JOURNEY_ID).orEmpty(), true).apply()
            if (emergencyPhone.isNotBlank()) {
                startPhoneCall(emergencyPhone)
            }
            stopMonitoring()
        }
    }

    private fun scheduleAt(triggerAtMillis: Long, action: () -> Unit) {
        val delayMillis = max(0L, triggerAtMillis - System.currentTimeMillis())
        val runnable = Runnable {
            try {
                action()
            } catch (_: Exception) {
                updateNotification(
                    title = "Emergency action failed",
                    text = "Open Amica and check emergency permissions.",
                )
            }
        }
        scheduledActions.add(runnable)
        handler.postDelayed(runnable, delayMillis)
    }

    private fun cancelScheduledActions() {
        scheduledActions.forEach { handler.removeCallbacks(it) }
        scheduledActions.clear()
    }

    private fun stopMonitoring() {
        cancelScheduledActions()
        releaseWakeLock()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    private fun acquireWakeLockUntil(endAtMillis: Long) {
        releaseWakeLock()
        val holdMillis = max(60_000L, endAtMillis - System.currentTimeMillis())
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "Amica::JourneySafetyMonitor",
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

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Amica journey safety",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Keeps the journey safety timer active."
        }

        val alertChannel = NotificationChannel(
            ALERT_CHANNEL_ID,
            "Amica safety alerts",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Alerts when a journey safety check needs attention."
            enableVibration(true)
            vibrationPattern = TWO_PULSE_VIBRATION_PATTERN
        }

        notificationManager().apply {
            createNotificationChannel(channel)
            createNotificationChannel(alertChannel)
        }
    }

    private fun startForegroundCompat(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun updateNotification(title: String, text: String) {
        notificationManager().notify(
            NOTIFICATION_ID,
            buildNotification(title = title, text = text),
        )
    }

    private fun buildNotification(title: String, text: String): Notification {
        return buildNotification(
            channelId = CHANNEL_ID,
            title = title,
            text = text,
            ongoing = true,
            vibrate = false,
        )
    }

    private fun showSafetyCheckAlertNotification() {
        notificationManager().notify(
            ALERT_NOTIFICATION_ID,
            buildNotification(
                channelId = ALERT_CHANNEL_ID,
                title = "Are you safe?",
                text = "Your journey timer ended. Open Amica to respond.",
                ongoing = false,
                vibrate = true,
            ),
        )
    }

    private fun buildNotification(
        channelId: String,
        title: String,
        text: String,
        ongoing: Boolean,
        vibrate: Boolean,
    ): Notification {
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentImmutableFlag(),
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, channelId)
        } else {
            Notification.Builder(this)
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O && vibrate) {
            builder.setVibrate(TWO_PULSE_VIBRATION_PATTERN)
        }

        return builder
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(pendingIntent)
            .setCategory(Notification.CATEGORY_ALARM)
            .setPriority(Notification.PRIORITY_HIGH)
            .setOngoing(ongoing)
            .build()
    }

    private fun pendingIntentImmutableFlag(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }
    }

    private fun notificationManager(): NotificationManager {
        return getSystemService(NOTIFICATION_SERVICE) as NotificationManager
    }

    private fun vibrateTwice() {
        val vibrator = currentVibrator()
        if (vibrator == null || !vibrator.hasVibrator()) {
            return
        }

        val pattern = TWO_PULSE_VIBRATION_PATTERN
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(
                VibrationEffect.createWaveform(pattern, -1),
                alarmVibrationAttributes(),
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(pattern, -1)
        }
    }

    private fun currentVibrator(): Vibrator? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(VIBRATOR_SERVICE) as? Vibrator
        }
    }

    private fun sendSmsDirectly(phone: String, message: String) {
        @Suppress("DEPRECATION")
        val smsManager = SmsManager.getDefault()
        val messageParts = smsManager.divideMessage(message)

        if (messageParts.size > 1) {
            smsManager.sendMultipartTextMessage(phone, null, messageParts, null, null)
            return
        }

        smsManager.sendTextMessage(phone, null, message, null, null)
    }

    private fun startPhoneCall(phone: String) {
        val intent = Intent(Intent.ACTION_CALL).apply {
            data = Uri.fromParts("tel", phone, null)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun alarmVibrationAttributes(): AudioAttributes {
        return AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
    }

    companion object {
        private const val CHANNEL_ID = "amica_journey_safety"
        private const val ALERT_CHANNEL_ID = "amica_safety_alerts"
        private const val NOTIFICATION_ID = 901
        private const val ALERT_NOTIFICATION_ID = 902
        private const val SMS_DELAY_MILLIS = 60_000L
        private const val CALL_DELAY_MILLIS = 180_000L
        private val TWO_PULSE_VIBRATION_PATTERN = longArrayOf(0, 450, 250, 450)
        private const val ACTION_START = "com.kintsugi.amica.START_SAFETY_MONITOR"
        private const val ACTION_STOP = "com.kintsugi.amica.STOP_SAFETY_MONITOR"
        private const val EXTRA_JOURNEY_ID = "journeyId"
        private const val EXTRA_DESTINATION_NAME = "destinationName"
        private const val EXTRA_SAFETY_CHECK_AT_MILLIS = "safetyCheckAtMillis"
        private const val EXTRA_EMERGENCY_PHONE = "emergencyPhone"
        private const val EXTRA_EMERGENCY_MESSAGE = "emergencyMessage"

        fun startIntent(
            context: Context,
            journeyId: String,
            destinationName: String,
            safetyCheckAtMillis: Long,
            emergencyPhone: String,
            emergencyMessage: String,
            emergencyPhones: List<String> = emptyList(),
        ): Intent {
            return Intent(context, EmergencySafetyMonitorService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_JOURNEY_ID, journeyId)
                putExtra(EXTRA_DESTINATION_NAME, destinationName)
                putExtra(EXTRA_SAFETY_CHECK_AT_MILLIS, safetyCheckAtMillis)
                putExtra(EXTRA_EMERGENCY_PHONE, emergencyPhone)
                putExtra(EXTRA_EMERGENCY_MESSAGE, emergencyMessage)
                putStringArrayListExtra("emergencyPhones", ArrayList(emergencyPhones))
            }
        }

        fun stopIntent(context: Context): Intent {
            return Intent(context, EmergencySafetyMonitorService::class.java).apply {
                action = ACTION_STOP
            }
        }
    }
}
