package com.kintsugi.amica

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import java.io.File

/**
 * Records a short audio clip the moment an SOS fires, as evidence.
 *
 * Runs as a microphone-typed foreground service so the clip keeps recording
 * when she locks the phone or it goes back in a bag: Android silences the
 * microphone for apps in the background unless a service like this holds it.
 * It must be started while Amica is on screen (Android 14 refuses to start a
 * microphone service from the background), which is always true for a manual
 * or voice SOS.
 *
 * The clip is AAC in an MP4 container (.m4a), mono, 64 kbps — about 240 KB for
 * 30 seconds, small enough to upload on a weak connection. The service only
 * records; the app uploads the finished file (see `SosAudioService` in Dart).
 *
 * State lives in shared preferences, not in this object, so the app can read
 * it after its UI was closed and reopened, and so a clip that finished while
 * the Flutter side was gone is still found and uploaded later.
 */
class SosAudioRecorderService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var recorder: MediaRecorder? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var outputPath: String? = null
    private var startedAtElapsed = 0L
    private var safetyStop: Runnable? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startRecording(
                path = intent.getStringExtra(EXTRA_OUTPUT_PATH).orEmpty(),
                maxDurationMillis = intent.getLongExtra(
                    EXTRA_MAX_DURATION_MILLIS,
                    DEFAULT_MAX_DURATION_MILLIS,
                ),
            )
            ACTION_STOP -> finishRecording(reason = "stopped")
            // Restarted by the system with no intent: the recorder is gone, so
            // close out whatever was on disk rather than leave "recording".
            else -> {
                markInterruptedIfRecording(this)
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        // Killed mid-clip: keep what was written so far.
        if (recorder != null) finishRecording(reason = "interrupted")
        releaseWakeLock()
        super.onDestroy()
    }

    private fun startRecording(path: String, maxDurationMillis: Long) {
        // startForegroundService() must always be followed by startForeground().
        createNotificationChannel()
        try {
            startForegroundCompat(buildNotification())
        } catch (error: Exception) {
            // Android 14 refuses a microphone service without the permission
            // or from the background.
            saveState(this, STATE_FAILED, path, 0L, error.localizedMessage ?: "foreground")
            stopSelf()
            return
        }

        if (recorder != null) return // Already recording this SOS.
        if (path.isEmpty()) {
            saveState(this, STATE_FAILED, path, 0L, "no output path")
            stopService()
            return
        }

        val file = File(path)
        file.parentFile?.mkdirs()
        outputPath = path

        val mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(this)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }

        try {
            mediaRecorder.apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setAudioChannels(1)
                setAudioSamplingRate(44_100)
                setAudioEncodingBitRate(64_000)
                setMaxDuration(maxDurationMillis.toInt())
                setOutputFile(path)
                setOnInfoListener { _, what, _ ->
                    if (what == MediaRecorder.MEDIA_RECORDER_INFO_MAX_DURATION_REACHED ||
                        what == MediaRecorder.MEDIA_RECORDER_INFO_MAX_FILESIZE_REACHED
                    ) {
                        finishRecording(reason = "complete")
                    }
                }
                setOnErrorListener { _, _, _ -> finishRecording(reason = "error") }
                prepare()
                start()
            }
        } catch (error: Exception) {
            // Most often: the microphone is still held by speech recognition.
            try {
                mediaRecorder.release()
            } catch (_: Exception) {
            }
            file.delete()
            saveState(this, STATE_FAILED, path, 0L, error.localizedMessage ?: "start failed")
            stopService()
            return
        }

        recorder = mediaRecorder
        startedAtElapsed = SystemClock.elapsedRealtime()
        saveState(this, STATE_RECORDING, path, 0L, null)
        acquireWakeLock(maxDurationMillis + 15_000L)

        // Belt and braces: some devices never deliver MAX_DURATION_REACHED.
        val stopper = Runnable { finishRecording(reason = "complete") }
        safetyStop = stopper
        handler.postDelayed(stopper, maxDurationMillis + 2_000L)
    }

    private fun finishRecording(reason: String) {
        safetyStop?.let { handler.removeCallbacks(it) }
        safetyStop = null

        val active = recorder
        recorder = null
        val path = outputPath

        if (active != null && path != null) {
            val durationMillis = SystemClock.elapsedRealtime() - startedAtElapsed
            var stoppedCleanly = true
            try {
                active.stop()
            } catch (_: Exception) {
                // stop() throws when almost nothing was captured; the file is
                // unusable then.
                stoppedCleanly = false
            }
            try {
                active.release()
            } catch (_: Exception) {
            }

            val file = File(path)
            if (stoppedCleanly && file.exists() && file.length() > 0L) {
                saveState(this, STATE_FINISHED, path, durationMillis, reason)
            } else {
                file.delete()
                saveState(this, STATE_FAILED, path, 0L, "clip too short ($reason)")
            }
        }

        stopService()
    }

    private fun stopService() {
        releaseWakeLock()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    private fun acquireWakeLock(holdMillis: Long) {
        releaseWakeLock()
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "Amica::SosAudio",
        ).apply {
            setReferenceCounted(false)
            acquire(holdMillis)
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "SOS audio",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Shown while Amica saves a short audio clip during an SOS."
            setSound(null, null)
            enableVibration(false)
        }
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager)
            .createNotificationChannel(channel)
    }

    private fun startForegroundCompat(notification: Notification) {
        // The "microphone" service type exists from Android 11 (R); on older
        // versions a plain foreground service may use the microphone.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun buildNotification(): Notification {
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPendingIntent = PendingIntent.getActivity(
            this,
            0,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_IMMUTABLE
                } else {
                    0
                },
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }
        // Deliberately plain wording: someone glancing at her screen should
        // not learn more than they need to.
        return builder
            .setSmallIcon(R.drawable.ic_stat_amica)
            .setContentTitle("Amica SOS is active")
            .setContentText("Saving a short audio clip for your safety record.")
            .setContentIntent(openPendingIntent)
            .setOngoing(true)
            .setPriority(Notification.PRIORITY_LOW)
            .build()
    }

    companion object {
        const val STATE_IDLE = "idle"
        const val STATE_RECORDING = "recording"
        const val STATE_FINISHED = "finished"
        const val STATE_FAILED = "failed"

        private const val CHANNEL_ID = "amica_sos_audio"
        private const val NOTIFICATION_ID = 951
        private const val ACTION_START = "com.kintsugi.amica.START_SOS_AUDIO"
        private const val ACTION_STOP = "com.kintsugi.amica.STOP_SOS_AUDIO"
        private const val EXTRA_OUTPUT_PATH = "outputPath"
        private const val EXTRA_MAX_DURATION_MILLIS = "maxDurationMillis"
        private const val DEFAULT_MAX_DURATION_MILLIS = 30_000L

        private const val PREFS_NAME = "amica_sos_audio"
        private const val PREF_STATE = "state"
        private const val PREF_PATH = "path"
        private const val PREF_DURATION_MILLIS = "durationMillis"
        private const val PREF_DETAIL = "detail"
        private const val PREF_UPDATED_AT = "updatedAtMillis"

        fun startIntent(context: Context, outputPath: String, maxDurationMillis: Long): Intent {
            return Intent(context, SosAudioRecorderService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_OUTPUT_PATH, outputPath)
                putExtra(EXTRA_MAX_DURATION_MILLIS, maxDurationMillis)
            }
        }

        fun stopIntent(context: Context): Intent {
            return Intent(context, SosAudioRecorderService::class.java).apply {
                action = ACTION_STOP
            }
        }

        /** Where a new clip is written. App-private: no other app can read it. */
        fun newOutputPath(context: Context): String {
            val dir = File(context.filesDir, "sos_audio").apply { mkdirs() }
            return File(dir, "sos_${System.currentTimeMillis()}.m4a").absolutePath
        }

        /** Marks the clip as "recording" before the service has even started,
         * so the app never reads a stale result from a previous SOS. */
        fun markStarting(context: Context, path: String) {
            saveState(context, STATE_RECORDING, path, 0L, "starting")
        }

        fun status(context: Context): Map<String, Any?> {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            return mapOf(
                "state" to prefs.getString(PREF_STATE, STATE_IDLE),
                "path" to prefs.getString(PREF_PATH, null),
                "durationMillis" to prefs.getLong(PREF_DURATION_MILLIS, 0L),
                "detail" to prefs.getString(PREF_DETAIL, null),
                "updatedAtMillis" to prefs.getLong(PREF_UPDATED_AT, 0L),
            )
        }

        private fun markInterruptedIfRecording(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            if (prefs.getString(PREF_STATE, STATE_IDLE) != STATE_RECORDING) return
            val path = prefs.getString(PREF_PATH, null)
            val file = path?.let { File(it) }
            // MediaRecorder never finalised this file, so it cannot be played.
            file?.delete()
            saveState(context, STATE_FAILED, path.orEmpty(), 0L, "interrupted")
        }

        private fun saveState(
            context: Context,
            state: String,
            path: String,
            durationMillis: Long,
            detail: String?,
        ) {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .putString(PREF_STATE, state)
                .putString(PREF_PATH, path)
                .putLong(PREF_DURATION_MILLIS, durationMillis)
                .putString(PREF_DETAIL, detail)
                .putLong(PREF_UPDATED_AT, System.currentTimeMillis())
                // commit, not apply: the process may die right after.
                .commit()
        }
    }
}
