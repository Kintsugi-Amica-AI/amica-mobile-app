package com.kintsugi.amica

import android.app.Activity
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import android.util.Log
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong

/**
 * Sends emergency SMS and reports what really happened.
 *
 * Two things made alerts silently disappear before:
 * 1. `SmsManager.getDefault()` on a dual-SIM phone with no default SMS SIM
 *    (or on Android 12+) can accept a message and never send it. This picks
 *    the manager for the phone's default SMS subscription instead.
 * 2. Sending was fire-and-forget: the app said "sent" as soon as the call
 *    returned. This waits for the radio's "sent" result for every part (via
 *    [SmsSentReceiver]), so the SOS screen can show who was actually reached.
 */
object SmsSender {
    const val STATUS_SENT = "sent"
    const val STATUS_FAILED = "failed"
    const val STATUS_UNCONFIRMED = "unconfirmed"

    private const val TAG = "AmicaSms"
    private const val CONFIRM_TIMEOUT_MS = 45_000L
    private val requestCodes = AtomicInteger(7000)

    fun managerFor(context: Context): SmsManager {
        val subId = SubscriptionManager.getDefaultSmsSubscriptionId()
        val valid = subId != SubscriptionManager.INVALID_SUBSCRIPTION_ID
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val base = context.getSystemService(SmsManager::class.java)
            if (valid) base.createForSubscriptionId(subId) else base
        } else {
            @Suppress("DEPRECATION")
            if (valid) SmsManager.getSmsManagerForSubscriptionId(subId) else SmsManager.getDefault()
        }
    }

    /** Fire-and-forget send, for background services with no one to report to. */
    fun sendQuietly(context: Context, phone: String, message: String) {
        val manager = managerFor(context)
        val parts = manager.divideMessage(message)
        if (parts.size > 1) {
            manager.sendMultipartTextMessage(phone, null, parts, null, null)
        } else {
            manager.sendTextMessage(phone, null, message, null, null)
        }
    }

    /** One text on its way: how many parts are still unconfirmed. */
    private class Pending(
        var remaining: Int,
        val onDone: (String, String?) -> Unit,
    ) {
        var failure: String? = null
        var finished = false
    }

    private val pending = ConcurrentHashMap<Long, Pending>()
    private val nextId = AtomicLong(System.currentTimeMillis())

    private fun finish(id: Long, status: String, error: String?) {
        val entry = pending.remove(id) ?: return
        if (entry.finished) return
        entry.finished = true
        Log.i(TAG, "SMS $id finished: $status ${error ?: ""}")
        entry.onDone(status, error)
    }

    /**
     * Called by [SmsSentReceiver] for every part the radio has handled.
     */
    internal fun onPartResult(id: Long, resultCode: Int) {
        val entry = pending[id] ?: return
        if (resultCode != Activity.RESULT_OK) {
            entry.failure = describe(resultCode)
        }
        entry.remaining -= 1
        Log.i(TAG, "SMS $id part result=$resultCode remaining=${entry.remaining}")
        if (entry.remaining <= 0) {
            finish(id, if (entry.failure == null) STATUS_SENT else STATUS_FAILED, entry.failure)
        }
    }

    /**
     * Sends [message] to [phone] and calls [onDone] once with
     * ([STATUS_SENT] | [STATUS_FAILED] | [STATUS_UNCONFIRMED], error text).
     * Always called on the main thread.
     *
     * The "sent" results come back through [SmsSentReceiver], a receiver
     * declared in the manifest and targeted *explicitly* by the pending
     * intents. (An earlier version registered a receiver at runtime for an
     * implicit action; on several phones the telephony stack's result never
     * reached it, so every text showed "Not confirmed" even though it went.)
     */
    fun sendWithReport(
        context: Context,
        phone: String,
        message: String,
        onDone: (status: String, error: String?) -> Unit,
    ) {
        val appContext = context.applicationContext
        val main = Handler(Looper.getMainLooper())
        val manager = try {
            managerFor(appContext)
        } catch (error: Exception) {
            onDone(STATUS_FAILED, error.localizedMessage ?: "No SMS service on this phone")
            return
        }
        val parts = manager.divideMessage(message)
        val id = nextId.incrementAndGet()
        pending[id] = Pending(parts.size) { status, error ->
            main.post { onDone(status, error) }
        }

        val sentIntents = ArrayList<PendingIntent>()
        for (i in parts.indices) {
            val intent = Intent(appContext, SmsSentReceiver::class.java)
                .setAction("${appContext.packageName}.SMS_SENT")
                .putExtra(SmsSentReceiver.EXTRA_ID, id)
                .putExtra(SmsSentReceiver.EXTRA_PART, i)
            sentIntents.add(
                PendingIntent.getBroadcast(
                    appContext,
                    requestCodes.incrementAndGet(),
                    intent,
                    // Mutable so the radio can attach its error details;
                    // safe because the intent is explicit to our receiver.
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_ONE_SHOT
                    } else {
                        PendingIntent.FLAG_ONE_SHOT
                    },
                ),
            )
        }

        try {
            Log.i(TAG, "SMS $id sending ${parts.size} part(s)")
            if (parts.size > 1) {
                manager.sendMultipartTextMessage(phone, null, parts, sentIntents, null)
            } else {
                manager.sendTextMessage(phone, null, message, sentIntents[0], null)
            }
        } catch (error: Exception) {
            finish(id, STATUS_FAILED, error.localizedMessage ?: "SMS could not be sent")
            return
        }

        // Some phones never report back. Don't hang the SOS flow: after a
        // generous wait, say "not confirmed" rather than guessing.
        main.postDelayed({
            val entry = pending[id] ?: return@postDelayed
            finish(id, STATUS_UNCONFIRMED, entry.failure)
        }, CONFIRM_TIMEOUT_MS)
    }

    private fun describe(resultCode: Int): String = when (resultCode) {
        SmsManager.RESULT_ERROR_NO_SERVICE -> "No mobile service"
        SmsManager.RESULT_ERROR_RADIO_OFF -> "Airplane mode or radio off"
        SmsManager.RESULT_ERROR_NULL_PDU -> "Message could not be encoded"
        SmsManager.RESULT_ERROR_GENERIC_FAILURE -> "SIM refused the message (check SMS balance)"
        else -> "SMS error $resultCode"
    }
}
