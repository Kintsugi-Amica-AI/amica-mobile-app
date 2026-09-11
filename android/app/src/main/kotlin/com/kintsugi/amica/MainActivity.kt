package com.kintsugi.amica

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.telephony.SmsManager
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val emergencyChannelName = "com.kintsugi.amica/emergency_actions"
    private val sendSmsRequestCode = 4101
    private val startCallRequestCode = 4102
    private val preparePermissionsRequestCode = 4103
    private val volumeShortcutWindowMillis = 1500L
    private val openCallShortcutExtra = "openCallShortcut"

    private var emergencyChannel: MethodChannel? = null
    private var pendingResult: MethodChannel.Result? = null
    private var pendingAction: PendingAction? = null
    private var volumeShortcutPressCount = 0
    private var firstVolumeShortcutAtMillis = 0L
    private var pendingCallShortcut = false
    private var pendingScheduledCall = false
    private var proximityWakeLock: PowerManager.WakeLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        emergencyChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            emergencyChannelName,
        )
        emergencyChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "prepareEmergencyPermissions" -> prepareEmergencyPermissions(result)
                "prepareNotificationPermission" -> prepareNotificationPermission(result)
                "sendSms" -> handleSendSms(call, result)
                "startCall" -> handleStartCall(call, result)
                "vibrateTwice" -> handleVibrateTwice(result)
                "startJourneySafetyMonitor" -> handleStartJourneySafetyMonitor(call, result)
                "stopJourneySafetyMonitor" -> handleStopJourneySafetyMonitor(result)
                "startFakeCallShortcutMonitor" -> handleStartFakeCallShortcutMonitor(result)
                "stopFakeCallShortcutMonitor" -> handleStopFakeCallShortcutMonitor(result)
                "consumePendingFakeCallShortcut" -> consumePendingCallShortcut(result)
                "setCallProximityEnabled" -> handleSetCallProximityEnabled(call, result)
                "scheduleFakeCall" -> handleScheduleFakeCall(call, result)
                "cancelScheduledFakeCall" -> handleCancelScheduledFakeCall(result)
                "scheduledFakeCallRemainingSeconds" ->
                    handleScheduledFakeCallRemainingSeconds(result)
                "consumePendingScheduledFakeCall" ->
                    consumePendingScheduledCall(result)
                "startStopAlertMonitor" -> handleStartStopAlertMonitor(call, result)
                "stopStopAlertMonitor" -> handleStopStopAlertMonitor(result)
                else -> result.notImplemented()
            }
        }
        handleCallShortcutIntent(intent)
        handleScheduledCallIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleCallShortcutIntent(intent)
        handleScheduledCallIntent(intent)
    }

    override fun onDestroy() {
        releaseCallProximityWakeLock()
        super.onDestroy()
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (
            (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP ||
                event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) &&
            event.action == KeyEvent.ACTION_DOWN &&
            event.repeatCount == 0
        ) {
            if (recordVolumeShortcutPress()) {
                emergencyChannel?.invokeMethod("onVolumeDownTriplePress", null)
                return true
            }
        }
        return super.dispatchKeyEvent(event)
    }

    private fun recordVolumeShortcutPress(): Boolean {
        val now = System.currentTimeMillis()
        if (firstVolumeShortcutAtMillis == 0L ||
            now - firstVolumeShortcutAtMillis > volumeShortcutWindowMillis
        ) {
            firstVolumeShortcutAtMillis = now
            volumeShortcutPressCount = 1
            return false
        }

        volumeShortcutPressCount += 1
        if (volumeShortcutPressCount >= 3) {
            volumeShortcutPressCount = 0
            firstVolumeShortcutAtMillis = 0L
            return true
        }
        return false
    }

    private fun prepareEmergencyPermissions(result: MethodChannel.Result) {
        val requiredPermissions = mutableListOf(
            Manifest.permission.SEND_SMS,
            Manifest.permission.CALL_PHONE,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            requiredPermissions.add(Manifest.permission.POST_NOTIFICATIONS)
        }

        val missingPermissions = requiredPermissions.filter { !hasPermission(it) }

        if (missingPermissions.isEmpty()) {
            result.success(true)
            return
        }

        startPendingPermissionRequest(
            PendingAction(PendingActionType.PREPARE_PERMISSIONS),
            result,
            missingPermissions.toTypedArray(),
            preparePermissionsRequestCode,
        )
    }

    /// Asks only for notifications, for features such as the Smart Stop Alert
    /// that need to show an alarm but have no business requesting SMS or phone
    /// permissions.
    private fun prepareNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(true)
            return
        }

        if (hasPermission(Manifest.permission.POST_NOTIFICATIONS)) {
            result.success(true)
            return
        }

        startPendingPermissionRequest(
            PendingAction(PendingActionType.PREPARE_PERMISSIONS),
            result,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            preparePermissionsRequestCode,
        )
    }

    private fun handleStartJourneySafetyMonitor(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val journeyId = call.argument<String>("journeyId")?.trim().orEmpty()
        val destinationName = call.argument<String>("destinationName")
            ?.trim()
            .orEmpty()
        val safetyCheckAtMillis = call.argument<Number>("safetyCheckAtMillis")
            ?.toLong()
            ?: 0L
        val emergencyPhone = call.argument<String>("emergencyPhone")
            ?.trim()
            .orEmpty()
        val emergencyMessage = call.argument<String>("emergencyMessage")
            ?.trim()
            .orEmpty()

        if (journeyId.isEmpty() || safetyCheckAtMillis <= 0L) {
            result.error(
                "INVALID_MONITOR_ARGUMENTS",
                "Journey ID and safety check time are required.",
                null,
            )
            return
        }

        val intent = EmergencySafetyMonitorService.startIntent(
            context = this,
            journeyId = journeyId,
            destinationName = destinationName,
            safetyCheckAtMillis = safetyCheckAtMillis,
            emergencyPhone = emergencyPhone,
            emergencyMessage = emergencyMessage,
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        result.success(true)
    }

    private fun handleStopJourneySafetyMonitor(result: MethodChannel.Result) {
        startService(EmergencySafetyMonitorService.stopIntent(this))
        result.success(true)
    }

    private fun handleStartFakeCallShortcutMonitor(result: MethodChannel.Result) {
        val intent = FakeCallShortcutMonitorService.startIntent(this)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        result.success(true)
    }

    private fun handleStopFakeCallShortcutMonitor(result: MethodChannel.Result) {
        startService(FakeCallShortcutMonitorService.stopIntent(this))
        result.success(true)
    }

    private fun consumePendingCallShortcut(result: MethodChannel.Result) {
        val wasPending = pendingCallShortcut
        pendingCallShortcut = false
        result.success(wasPending)
    }

    private fun handleCallShortcutIntent(intent: Intent?) {
        if (intent?.getBooleanExtra(openCallShortcutExtra, false) != true) {
            return
        }

        pendingCallShortcut = true
        intent.removeExtra(openCallShortcutExtra)
        emergencyChannel?.invokeMethod("onVolumeDownTriplePress", null)
    }

    private fun handleStartStopAlertMonitor(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val dropOffLatitude = call.argument<Number>("dropOffLatitude")?.toDouble()
        val dropOffLongitude = call.argument<Number>("dropOffLongitude")?.toDouble()

        if (dropOffLatitude == null || dropOffLongitude == null) {
            result.error(
                "INVALID_STOP_ALERT_ARGUMENTS",
                "Drop-off coordinates are required.",
                null,
            )
            return
        }

        val intent = StopAlertMonitorService.startIntent(
            context = this,
            dropOffLatitude = dropOffLatitude,
            dropOffLongitude = dropOffLongitude,
            dropOffName = call.argument<String>("dropOffName")?.trim().orEmpty(),
            alertDistanceMeters = call.argument<Number>("alertDistanceMeters")
                ?.toInt()
                ?: 2000,
            alreadyAlerted = call.argument<Boolean>("alreadyAlerted") == true,
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        result.success(true)
    }

    private fun handleStopStopAlertMonitor(result: MethodChannel.Result) {
        startService(StopAlertMonitorService.stopIntent(this))
        result.success(true)
    }

    private fun handleScheduleFakeCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val delaySeconds = call.argument<Number>("delaySeconds")?.toLong() ?: 0L
        val callerName = call.argument<String>("callerName")?.trim().orEmpty()

        if (delaySeconds <= 0L) {
            result.error(
                "INVALID_SCHEDULE_ARGUMENTS",
                "Schedule delay must be greater than zero.",
                null,
            )
            return
        }

        val intent = FakeCallSchedulerService.startIntent(
            context = this,
            triggerAtMillis = System.currentTimeMillis() + delaySeconds * 1000L,
            callerName = callerName,
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        result.success(true)
    }

    private fun handleCancelScheduledFakeCall(result: MethodChannel.Result) {
        startService(FakeCallSchedulerService.stopIntent(this))
        result.success(true)
    }

    private fun handleScheduledFakeCallRemainingSeconds(
        result: MethodChannel.Result,
    ) {
        val remainingMillis = FakeCallSchedulerService.remainingMillis(this)
        result.success(((remainingMillis + 999L) / 1000L).toInt())
    }

    private fun consumePendingScheduledCall(result: MethodChannel.Result) {
        val wasPending = pendingScheduledCall
        pendingScheduledCall = false
        result.success(wasPending)
    }

    private fun handleScheduledCallIntent(intent: Intent?) {
        if (
            intent?.getBooleanExtra(
                FakeCallSchedulerService.EXTRA_OPEN_SCHEDULED_CALL,
                false,
            ) != true
        ) {
            return
        }

        pendingScheduledCall = true
        intent.removeExtra(FakeCallSchedulerService.EXTRA_OPEN_SCHEDULED_CALL)
        emergencyChannel?.invokeMethod("onScheduledFakeCallDue", null)
    }

    private fun handleSendSms(call: MethodCall, result: MethodChannel.Result) {
        val phone = call.argument<String>("phone")?.trim().orEmpty()
        val message = call.argument<String>("message")?.trim().orEmpty()

        if (phone.isEmpty() || message.isEmpty()) {
            result.error(
                "INVALID_SMS_ARGUMENTS",
                "Phone number and message are required.",
                null,
            )
            return
        }

        val action = PendingAction(
            type = PendingActionType.SEND_SMS,
            phone = phone,
            message = message,
        )

        if (hasPermission(Manifest.permission.SEND_SMS)) {
            runPendingAction(action, result)
            return
        }

        startPendingPermissionRequest(
            action,
            result,
            arrayOf(Manifest.permission.SEND_SMS),
            sendSmsRequestCode,
        )
    }

    private fun handleStartCall(call: MethodCall, result: MethodChannel.Result) {
        val phone = call.argument<String>("phone")?.trim().orEmpty()

        if (phone.isEmpty()) {
            result.error(
                "INVALID_CALL_ARGUMENTS",
                "Phone number is required.",
                null,
            )
            return
        }

        val action = PendingAction(
            type = PendingActionType.START_CALL,
            phone = phone,
        )

        if (hasPermission(Manifest.permission.CALL_PHONE)) {
            runPendingAction(action, result)
            return
        }

        startPendingPermissionRequest(
            action,
            result,
            arrayOf(Manifest.permission.CALL_PHONE),
            startCallRequestCode,
        )
    }

    private fun handleVibrateTwice(result: MethodChannel.Result) {
        try {
            val vibrator = currentVibrator()
            if (vibrator == null || !vibrator.hasVibrator()) {
                result.success(false)
                return
            }

            val pattern = longArrayOf(0, 450, 250, 450)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(
                    VibrationEffect.createWaveform(pattern, -1),
                )
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(pattern, -1)
            }
            result.success(true)
        } catch (error: Exception) {
            result.error(
                "VIBRATION_FAILED",
                error.localizedMessage ?: "Could not vibrate device.",
                null,
            )
        }
    }

    private fun handleSetCallProximityEnabled(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val enabled = call.argument<Boolean>("enabled") == true
        try {
            if (enabled) {
                acquireCallProximityWakeLock()
            } else {
                releaseCallProximityWakeLock()
            }
            result.success(true)
        } catch (error: Exception) {
            result.error(
                "PROXIMITY_WAKE_LOCK_FAILED",
                error.localizedMessage ?: "Could not update call proximity mode.",
                null,
            )
        }
    }

    private fun startPendingPermissionRequest(
        action: PendingAction,
        result: MethodChannel.Result,
        permissions: Array<String>,
        requestCode: Int,
    ) {
        if (pendingResult != null) {
            result.error(
                "PERMISSION_REQUEST_IN_PROGRESS",
                "Another emergency permission request is already active.",
                null,
            )
            return
        }

        pendingAction = action
        pendingResult = result

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            requestPermissions(permissions, requestCode)
        } else {
            runPendingActionAndClear()
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (
            requestCode != sendSmsRequestCode &&
            requestCode != startCallRequestCode &&
            requestCode != preparePermissionsRequestCode
        ) {
            return
        }

        val allGranted = grantResults.isNotEmpty() &&
            grantResults.all { it == PackageManager.PERMISSION_GRANTED }

        if (!allGranted) {
            pendingResult?.error(
                "PERMISSION_DENIED",
                "Emergency SMS/phone permission was denied.",
                null,
            )
            clearPendingAction()
            return
        }

        runPendingActionAndClear()
    }

    private fun runPendingActionAndClear() {
        val result = pendingResult
        val action = pendingAction
        clearPendingAction()

        if (result == null || action == null) {
            return
        }

        runPendingAction(action, result)
    }

    private fun runPendingAction(
        action: PendingAction,
        result: MethodChannel.Result,
    ) {
        try {
            when (action.type) {
                PendingActionType.PREPARE_PERMISSIONS -> result.success(true)
                PendingActionType.SEND_SMS -> {
                    sendSmsDirectly(
                        phone = action.phone.orEmpty(),
                        message = action.message.orEmpty(),
                    )
                    result.success(true)
                }
                PendingActionType.START_CALL -> {
                    startPhoneCall(action.phone.orEmpty())
                    result.success(true)
                }
            }
        } catch (error: Exception) {
            result.error(
                "EMERGENCY_ACTION_FAILED",
                error.localizedMessage ?: "Emergency action failed.",
                null,
            )
        }
    }

    private fun sendSmsDirectly(phone: String, message: String) {
        @Suppress("DEPRECATION")
        val smsManager = SmsManager.getDefault()
        val messageParts = smsManager.divideMessage(message)

        if (messageParts.size > 1) {
            smsManager.sendMultipartTextMessage(
                phone,
                null,
                messageParts,
                null,
                null,
            )
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

    private fun hasPermission(permission: String): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun currentVibrator(): Vibrator? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(VIBRATOR_SERVICE) as? Vibrator
        }
    }

    private fun acquireCallProximityWakeLock() {
        if (proximityWakeLock?.isHeld == true) {
            return
        }

        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP &&
            !powerManager.isWakeLockLevelSupported(
                PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK,
            )
        ) {
            return
        }

        proximityWakeLock = powerManager.newWakeLock(
            PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK,
            "Amica::CallProximity",
        ).apply {
            setReferenceCounted(false)
            acquire()
        }
    }

    private fun releaseCallProximityWakeLock() {
        proximityWakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        proximityWakeLock = null
    }

    private fun clearPendingAction() {
        pendingResult = null
        pendingAction = null
    }
}

private data class PendingAction(
    val type: PendingActionType,
    val phone: String? = null,
    val message: String? = null,
)

private enum class PendingActionType {
    PREPARE_PERMISSIONS,
    SEND_SMS,
    START_CALL,
}
