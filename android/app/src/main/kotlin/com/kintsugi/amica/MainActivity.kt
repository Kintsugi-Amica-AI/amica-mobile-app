package com.kintsugi.amica

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val emergencyChannelName = "com.kintsugi.amica/emergency_actions"
    private val sendSmsRequestCode = 4101
    private val startCallRequestCode = 4102
    private val preparePermissionsRequestCode = 4103

    private var pendingResult: MethodChannel.Result? = null
    private var pendingAction: PendingAction? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            emergencyChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "prepareEmergencyPermissions" -> prepareEmergencyPermissions(result)
                "sendSms" -> handleSendSms(call, result)
                "startCall" -> handleStartCall(call, result)
                "vibrateTwice" -> handleVibrateTwice(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun prepareEmergencyPermissions(result: MethodChannel.Result) {
        val missingPermissions = listOf(
            Manifest.permission.SEND_SMS,
            Manifest.permission.CALL_PHONE,
        ).filter { !hasPermission(it) }

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
