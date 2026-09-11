package com.kintsugi.amica

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import kotlin.math.roundToInt

/**
 * Watches how far the rider still is from their chosen drop-off and sounds an
 * alarm once they come within the configured distance of it.
 *
 * The whole point of the feature is to help someone who has dozed off or lost
 * track of an unfamiliar route, so the phone will be in a pocket with the
 * screen off. That rules out a Dart timer or an in-app location stream: the
 * tracking runs here, in a foreground service with a partial wake lock, and
 * the alarm is an alarm-channel notification plus a long vibration pattern so
 * it lands even when Amica is not on screen.
 *
 * A foreground service typed `location` may keep receiving location while the
 * app is in the background without the separate background-location
 * permission, as long as it is started while the app is in the foreground —
 * which it always is here, since the rider starts the ride from the app.
 */
class StopAlertMonitorService : Service(), LocationListener {
    private var locationManager: LocationManager? = null
    private var wakeLock: PowerManager.WakeLock? = null

    private var dropOffLatitude = 0.0
    private var dropOffLongitude = 0.0
    private var dropOffName = DEFAULT_DROP_OFF_NAME
    private var alertDistanceMeters = DEFAULT_ALERT_DISTANCE_METERS
    private var hasAlerted = false
    private var lastDistanceMeters: Float? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return when (intent?.action) {
            ACTION_START -> {
                startMonitoring(intent)
                START_STICKY
            }
            ACTION_STOP -> {
                clearSavedRide(this)
                stopMonitoring()
                START_NOT_STICKY
            }
            // Android restarted the sticky service with no intent, which on a
            // long ride is exactly when the rider still needs the alarm.
            // Resume from the saved ride rather than going quiet.
            else -> {
                restoreMonitoring()
                START_STICKY
            }
        }
    }

    override fun onDestroy() {
        stopLocationUpdates()
        releaseWakeLock()
        super.onDestroy()
    }

    private fun startMonitoring(intent: Intent) {
        startMonitoring(
            latitude = intent.getDoubleExtra(EXTRA_DROP_OFF_LATITUDE, 0.0),
            longitude = intent.getDoubleExtra(EXTRA_DROP_OFF_LONGITUDE, 0.0),
            name = intent.getStringExtra(EXTRA_DROP_OFF_NAME),
            alertDistance = intent.getIntExtra(
                EXTRA_ALERT_DISTANCE_METERS,
                DEFAULT_ALERT_DISTANCE_METERS,
            ),
            alreadyAlerted = intent.getBooleanExtra(EXTRA_ALREADY_ALERTED, false),
        )
    }

    private fun restoreMonitoring() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        if (!prefs.contains(PREF_DROP_OFF_LATITUDE)) {
            stopMonitoring()
            return
        }

        startMonitoring(
            latitude = java.lang.Double.longBitsToDouble(
                prefs.getLong(PREF_DROP_OFF_LATITUDE, 0L),
            ),
            longitude = java.lang.Double.longBitsToDouble(
                prefs.getLong(PREF_DROP_OFF_LONGITUDE, 0L),
            ),
            name = prefs.getString(PREF_DROP_OFF_NAME, null),
            alertDistance = prefs.getInt(
                PREF_ALERT_DISTANCE_METERS,
                DEFAULT_ALERT_DISTANCE_METERS,
            ),
            alreadyAlerted = prefs.getBoolean(PREF_ALREADY_ALERTED, false),
        )
    }

    private fun startMonitoring(
        latitude: Double,
        longitude: Double,
        name: String?,
        alertDistance: Int,
        alreadyAlerted: Boolean,
    ) {
        dropOffLatitude = latitude
        dropOffLongitude = longitude
        dropOffName = name?.takeIf { it.isNotBlank() } ?: DEFAULT_DROP_OFF_NAME
        alertDistanceMeters = alertDistance
        hasAlerted = alreadyAlerted
        lastDistanceMeters = null

        // Go foreground before any early return: Android kills the process if
        // startForegroundService() is not followed by startForeground().
        createNotificationChannels()
        startForegroundCompat(
            buildTrackingNotification(
                title = "Watching your stop",
                text = "Amica will alert you near $dropOffName.",
            ),
        )

        if (dropOffLatitude == 0.0 && dropOffLongitude == 0.0) {
            clearSavedRide(this)
            stopMonitoring()
            return
        }

        saveRide(this)
        acquireWakeLock()
        startLocationUpdates()
    }

    private fun stopMonitoring() {
        stopLocationUpdates()
        releaseWakeLock()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    private fun startLocationUpdates() {
        if (!hasLocationPermission()) {
            updateTrackingNotification(
                title = "Location permission needed",
                text = "Open Amica and allow location to watch your stop.",
            )
            return
        }

        val manager = getSystemService(LOCATION_SERVICE) as LocationManager
        locationManager = manager

        // GPS is the accurate source; network fixes keep the distance roughly
        // current inside buildings and tunnels where GPS drops out.
        val providers = listOf(
            LocationManager.GPS_PROVIDER,
            LocationManager.NETWORK_PROVIDER,
        )

        var requested = false
        providers.forEach { provider ->
            try {
                if (!manager.isProviderEnabled(provider)) {
                    return@forEach
                }
                manager.requestLocationUpdates(
                    provider,
                    MIN_UPDATE_INTERVAL_MILLIS,
                    MIN_UPDATE_DISTANCE_METERS,
                    this,
                )
                requested = true
            } catch (_: SecurityException) {
                // Permission was revoked between the check and the request.
            } catch (_: IllegalArgumentException) {
                // Provider is not present on this device.
            }
        }

        if (!requested) {
            updateTrackingNotification(
                title = "Location is off",
                text = "Turn on location so Amica can watch your stop.",
            )
            return
        }

        // Seed the distance from the last known fix so the notification shows
        // something useful before the first fresh fix arrives.
        providers.forEach { provider ->
            try {
                manager.getLastKnownLocation(provider)?.let(::handleLocation)
            } catch (_: SecurityException) {
                // Ignored; fresh updates will still arrive.
            }
        }
    }

    private fun stopLocationUpdates() {
        try {
            locationManager?.removeUpdates(this)
        } catch (_: SecurityException) {
            // Nothing to clean up if the permission is already gone.
        }
        locationManager = null
    }

    override fun onLocationChanged(location: Location) {
        handleLocation(location)
    }

    // Required by LocationListener on older API levels.
    @Deprecated("Deprecated in Java")
    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) = Unit

    override fun onProviderEnabled(provider: String) = Unit

    override fun onProviderDisabled(provider: String) = Unit

    private fun handleLocation(location: Location) {
        val dropOff = Location("amica-drop-off").apply {
            latitude = dropOffLatitude
            longitude = dropOffLongitude
        }
        val distanceMeters = location.distanceTo(dropOff)

        // Ignore a fix that moves the rider further from the stop than the
        // previous one by an implausible jump, which usually means a bad fix.
        val previous = lastDistanceMeters
        if (previous != null && distanceMeters - previous > MAX_PLAUSIBLE_JUMP_METERS) {
            return
        }
        lastDistanceMeters = distanceMeters

        if (!hasAlerted && distanceMeters <= alertDistanceMeters) {
            hasAlerted = true
            // Persist before alarming so a restart mid-ride cannot sound it
            // a second time.
            saveRide(this)
            soundApproachingStopAlarm(distanceMeters)
        }

        updateTrackingNotification(
            title = if (hasAlerted) {
                "Approaching $dropOffName"
            } else {
                "Watching your stop"
            },
            text = "${formatDistance(distanceMeters)} to $dropOffName.",
        )
    }

    private fun soundApproachingStopAlarm(distanceMeters: Float) {
        vibrateAlarmPattern()
        notificationManager().notify(
            ALARM_NOTIFICATION_ID,
            buildAlarmNotification(distanceMeters),
        )
    }

    private fun vibrateAlarmPattern() {
        try {
            val vibrator = currentVibrator()
            if (vibrator == null || !vibrator.hasVibrator()) {
                return
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(
                    VibrationEffect.createWaveform(ALARM_VIBRATION_PATTERN, -1),
                )
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(ALARM_VIBRATION_PATTERN, -1)
            }
        } catch (_: Exception) {
            // The notification alarm still sounds if vibration is unavailable.
        }
    }

    private fun acquireWakeLock() {
        releaseWakeLock()
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "Amica::StopAlertMonitor",
        ).apply {
            setReferenceCounted(false)
            acquire(MAX_RIDE_DURATION_MILLIS)
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

    private fun hasLocationPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true
        }
        return checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED ||
            checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val trackingChannel = NotificationChannel(
            TRACKING_CHANNEL_ID,
            "Amica stop tracking",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Shows how far you are from your drop-off."
        }

        // An alarm-usage channel so the alert is loud enough to wake someone
        // who dozed off, rather than a notification chime they sleep through.
        val alarmChannel = NotificationChannel(
            ALARM_CHANNEL_ID,
            "Amica stop alarm",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Alarm when you are close to your drop-off."
            enableVibration(true)
            vibrationPattern = ALARM_VIBRATION_PATTERN
            setSound(
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM),
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
        }

        notificationManager().apply {
            createNotificationChannel(trackingChannel)
            createNotificationChannel(alarmChannel)
        }
    }

    private fun startForegroundCompat(notification: Notification) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(
                    TRACKING_NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION,
                )
            } else {
                startForeground(TRACKING_NOTIFICATION_ID, notification)
            }
        } catch (_: Exception) {
            // Android 14+ refuses a location-typed foreground service when the
            // permission is missing. Stop cleanly instead of crashing the app.
            stopSelf()
        }
    }

    private fun updateTrackingNotification(title: String, text: String) {
        notificationManager().notify(
            TRACKING_NOTIFICATION_ID,
            buildTrackingNotification(title = title, text = text),
        )
    }

    private fun buildTrackingNotification(
        title: String,
        text: String,
    ): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, TRACKING_CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }

        return builder
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(openAppPendingIntent())
            .setOngoing(true)
            .setPriority(Notification.PRIORITY_LOW)
            .addAction(
                Notification.Action.Builder(
                    null,
                    "Stop",
                    PendingIntent.getService(
                        this,
                        1,
                        stopIntent(this),
                        PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentImmutableFlag(),
                    ),
                ).build(),
            )
            .build()
    }

    private fun buildAlarmNotification(distanceMeters: Float): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, ALARM_CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            builder
                .setVibrate(ALARM_VIBRATION_PATTERN)
                .setSound(
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM),
                )
        }

        return builder
            .setSmallIcon(android.R.drawable.ic_popup_reminder)
            .setContentTitle("Your stop is coming up")
            .setContentText(
                "${formatDistance(distanceMeters)} to $dropOffName. " +
                    "Get ready to get off.",
            )
            .setContentIntent(openAppPendingIntent())
            .setCategory(Notification.CATEGORY_ALARM)
            .setPriority(Notification.PRIORITY_MAX)
            .setAutoCancel(true)
            .build()
    }

    private fun openAppPendingIntent(): PendingIntent {
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            this,
            0,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentImmutableFlag(),
        )
    }

    private fun formatDistance(meters: Float): String {
        if (meters < 1000f) {
            return "${meters.roundToInt()} m"
        }
        return String.format("%.1f km", meters / 1000f)
    }

    private fun notificationManager(): NotificationManager {
        return getSystemService(NOTIFICATION_SERVICE) as NotificationManager
    }

    private fun currentVibrator(): Vibrator? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(VIBRATOR_SERVICE) as? Vibrator
        }
    }

    private fun pendingIntentImmutableFlag(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }
    }

    companion object {
        private const val TRACKING_CHANNEL_ID = "amica_stop_tracking"
        private const val ALARM_CHANNEL_ID = "amica_stop_alarm"
        private const val TRACKING_NOTIFICATION_ID = 951
        private const val ALARM_NOTIFICATION_ID = 952
        private const val ACTION_START = "com.kintsugi.amica.START_STOP_ALERT"
        private const val ACTION_STOP = "com.kintsugi.amica.STOP_STOP_ALERT"
        private const val EXTRA_DROP_OFF_LATITUDE = "dropOffLatitude"
        private const val EXTRA_DROP_OFF_LONGITUDE = "dropOffLongitude"
        private const val EXTRA_DROP_OFF_NAME = "dropOffName"
        private const val EXTRA_ALERT_DISTANCE_METERS = "alertDistanceMeters"
        private const val EXTRA_ALREADY_ALERTED = "alreadyAlerted"
        private const val DEFAULT_DROP_OFF_NAME = "your stop"
        private const val DEFAULT_ALERT_DISTANCE_METERS = 2000
        private const val MIN_UPDATE_INTERVAL_MILLIS = 10_000L
        private const val MIN_UPDATE_DISTANCE_METERS = 25f

        /// A single fix that puts the rider this much further from the stop
        /// than the previous one is treated as GPS noise, not travel.
        private const val MAX_PLAUSIBLE_JUMP_METERS = 3000f
        private const val MAX_RIDE_DURATION_MILLIS = 4 * 60 * 60 * 1000L
        private val ALARM_VIBRATION_PATTERN =
            longArrayOf(0, 700, 300, 700, 300, 700)

        private const val PREFS_NAME = "amica_stop_alert"
        private const val PREF_DROP_OFF_LATITUDE = "dropOffLatitude"
        private const val PREF_DROP_OFF_LONGITUDE = "dropOffLongitude"
        private const val PREF_DROP_OFF_NAME = "dropOffName"
        private const val PREF_ALERT_DISTANCE_METERS = "alertDistanceMeters"
        private const val PREF_ALREADY_ALERTED = "alreadyAlerted"

        fun startIntent(
            context: Context,
            dropOffLatitude: Double,
            dropOffLongitude: Double,
            dropOffName: String,
            alertDistanceMeters: Int,
            alreadyAlerted: Boolean,
        ): Intent {
            return Intent(context, StopAlertMonitorService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_DROP_OFF_LATITUDE, dropOffLatitude)
                putExtra(EXTRA_DROP_OFF_LONGITUDE, dropOffLongitude)
                putExtra(EXTRA_DROP_OFF_NAME, dropOffName)
                putExtra(EXTRA_ALERT_DISTANCE_METERS, alertDistanceMeters)
                putExtra(EXTRA_ALREADY_ALERTED, alreadyAlerted)
            }
        }

        fun stopIntent(context: Context): Intent {
            return Intent(context, StopAlertMonitorService::class.java).apply {
                action = ACTION_STOP
            }
        }

        private fun clearSavedRide(context: Context) {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .clear()
                .apply()
        }
    }

    /// Shared preferences has no double, so coordinates are stored as raw bits
    /// rather than narrowed to a float and losing precision.
    private fun saveRide(context: Context) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putLong(
                PREF_DROP_OFF_LATITUDE,
                java.lang.Double.doubleToRawLongBits(dropOffLatitude),
            )
            .putLong(
                PREF_DROP_OFF_LONGITUDE,
                java.lang.Double.doubleToRawLongBits(dropOffLongitude),
            )
            .putString(PREF_DROP_OFF_NAME, dropOffName)
            .putInt(PREF_ALERT_DISTANCE_METERS, alertDistanceMeters)
            .putBoolean(PREF_ALREADY_ALERTED, hasAlerted)
            .apply()
    }
}
