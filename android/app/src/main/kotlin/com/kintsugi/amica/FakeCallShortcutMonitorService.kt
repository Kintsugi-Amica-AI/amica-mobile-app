package com.kintsugi.amica

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.database.ContentObserver
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import kotlin.math.abs

class FakeCallShortcutMonitorService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var audioManager: AudioManager? = null
    private var volumeObserver: ContentObserver? = null
    private var previousVolumes = emptyMap<Int, Int>()
    private var firstVolumeUpAtMillis = 0L
    private var volumeUpPressCount = 0
    private var lastVolumeUpEventAtMillis = 0L

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return when (intent?.action) {
            ACTION_START -> {
                startMonitoring()
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
        unregisterVolumeObserver()
        super.onDestroy()
    }

    private fun startMonitoring() {
        createNotificationChannel()
        startForegroundCompat(buildServiceNotification())
        audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        primeVolumeStreamsForShortcut()
        previousVolumes = readCurrentVolumes()
        registerVolumeObserver()
    }

    private fun stopMonitoring() {
        unregisterVolumeObserver()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    private fun registerVolumeObserver() {
        unregisterVolumeObserver()
        volumeObserver = object : ContentObserver(handler) {
            override fun onChange(selfChange: Boolean) {
                handleVolumeSettingsChanged()
            }

            override fun onChange(selfChange: Boolean, uri: Uri?) {
                handleVolumeSettingsChanged()
            }
        }

        contentResolver.registerContentObserver(
            Settings.System.CONTENT_URI,
            true,
            volumeObserver as ContentObserver,
        )
    }

    private fun unregisterVolumeObserver() {
        volumeObserver?.let { contentResolver.unregisterContentObserver(it) }
        volumeObserver = null
    }

    private fun handleVolumeSettingsChanged() {
        val currentVolumes = readCurrentVolumes()
        val priorVolumes = previousVolumes
        val increasedStreams = monitoredStreams.filter { stream ->
            val previous = priorVolumes[stream] ?: return@filter false
            val current = currentVolumes[stream] ?: return@filter false
            current > previous
        }

        previousVolumes = currentVolumes

        if (increasedStreams.isEmpty()) {
            return
        }
        restorePriorVolumes(increasedStreams, priorVolumes)

        val now = System.currentTimeMillis()
        if (abs(now - lastVolumeUpEventAtMillis) < duplicateEventWindowMillis) {
            return
        }

        lastVolumeUpEventAtMillis = now
        if (recordVolumeUpPress(now)) {
            openCallScreen()
        }
    }

    private fun restorePriorVolumes(
        streams: List<Int>,
        priorVolumes: Map<Int, Int>,
    ) {
        val manager = audioManager ?: return
        streams.forEach { stream ->
            val priorVolume = priorVolumes[stream] ?: return@forEach
            try {
                manager.setStreamVolume(stream, priorVolume, 0)
            } catch (_: Exception) {
                // Some device modes restrict changing ringer/system streams.
            }
        }
        previousVolumes = readCurrentVolumes()
    }

    private fun readCurrentVolumes(): Map<Int, Int> {
        val manager = audioManager ?: return emptyMap()
        return monitoredStreams.associateWith { stream ->
            try {
                manager.getStreamVolume(stream)
            } catch (_: Exception) {
                0
            }
        }
    }

    private fun primeVolumeStreamsForShortcut() {
        val manager = audioManager ?: return
        monitoredStreams.forEach { stream ->
            try {
                val current = manager.getStreamVolume(stream)
                val max = manager.getStreamMaxVolume(stream)
                if (current >= max && current > 0) {
                    manager.setStreamVolume(stream, current - 1, 0)
                }
            } catch (_: Exception) {
                // Some device modes restrict changing ringer/system streams.
            }
        }
    }

    private fun recordVolumeUpPress(now: Long): Boolean {
        if (
            firstVolumeUpAtMillis == 0L ||
            now - firstVolumeUpAtMillis > volumeShortcutWindowMillis
        ) {
            firstVolumeUpAtMillis = now
            volumeUpPressCount = 1
            return false
        }

        volumeUpPressCount += 1
        if (volumeUpPressCount < 3) {
            return false
        }

        volumeUpPressCount = 0
        firstVolumeUpAtMillis = 0L
        return true
    }

    private fun openCallScreen() {
        val intent = callScreenIntent()
        try {
            startActivity(intent)
        } catch (_: Exception) {
            // Android may block direct background activity launches. The call-style
            // notification below gives the user a visible fallback.
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
            putExtra(EXTRA_OPEN_CALL_SHORTCUT, true)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val serviceChannel = NotificationChannel(
            SERVICE_CHANNEL_ID,
            "Amica safety shortcut",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Keeps the volume-button safety shortcut active."
        }

        val callChannel = NotificationChannel(
            CALL_CHANNEL_ID,
            "Incoming calls",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Shows the call screen when the shortcut is triggered."
            setSound(null, null)
        }

        notificationManager().apply {
            createNotificationChannel(serviceChannel)
            createNotificationChannel(callChannel)
        }
    }

    private fun startForegroundCompat(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                SERVICE_NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(SERVICE_NOTIFICATION_ID, notification)
        }
    }

    private fun buildServiceNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentImmutableFlag(),
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, SERVICE_CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }

        return builder
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Safety shortcut armed")
            .setContentText("Press volume up three times to open the call screen.")
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(Notification.PRIORITY_LOW)
            .build()
    }

    private fun buildIncomingCallNotification(intent: Intent): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            1,
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
            .setContentText("Tap to answer.")
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
        private const val SERVICE_CHANNEL_ID = "amica_fake_call_shortcut"
        private const val CALL_CHANNEL_ID = "amica_incoming_call_shortcut"
        private const val SERVICE_NOTIFICATION_ID = 931
        private const val CALL_NOTIFICATION_ID = 932
        private const val ACTION_START = "com.kintsugi.amica.START_FAKE_CALL_SHORTCUT"
        private const val ACTION_STOP = "com.kintsugi.amica.STOP_FAKE_CALL_SHORTCUT"
        private const val EXTRA_OPEN_CALL_SHORTCUT = "openCallShortcut"
        private const val volumeShortcutWindowMillis = 1500L
        private const val duplicateEventWindowMillis = 250L

        private val monitoredStreams = listOf(
            AudioManager.STREAM_MUSIC,
            AudioManager.STREAM_RING,
            AudioManager.STREAM_NOTIFICATION,
            AudioManager.STREAM_SYSTEM,
            AudioManager.STREAM_ALARM,
        )

        fun startIntent(context: Context): Intent {
            return Intent(context, FakeCallShortcutMonitorService::class.java).apply {
                action = ACTION_START
            }
        }

        fun stopIntent(context: Context): Intent {
            return Intent(context, FakeCallShortcutMonitorService::class.java).apply {
                action = ACTION_STOP
            }
        }
    }
}
