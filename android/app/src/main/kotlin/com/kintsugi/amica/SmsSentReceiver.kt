package com.kintsugi.amica

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Gets the radio's result for each part of an emergency SMS and hands it to
 * [SmsSender]. Declared in the manifest (not exported) and addressed
 * explicitly, which is the delivery path Android guarantees for SMS
 * "sent" pending intents.
 */
class SmsSentReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getLongExtra(EXTRA_ID, -1L)
        if (id < 0) return
        SmsSender.onPartResult(id, resultCode)
    }

    companion object {
        const val EXTRA_ID = "com.kintsugi.amica.extra.SMS_ID"
        const val EXTRA_PART = "com.kintsugi.amica.extra.SMS_PART"
    }
}
