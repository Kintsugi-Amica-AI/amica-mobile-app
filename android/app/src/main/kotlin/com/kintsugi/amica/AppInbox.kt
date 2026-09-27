package com.kintsugi.amica

import android.content.Context
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Adds an entry to the in-app Notifications list from native code.
 *
 * The alerts the Android services draw themselves (the approaching-stop alarm,
 * the "Are you safe?" check) used to appear only in the phone's notification
 * bar. The Notifications screen reads its list from Flutter's
 * SharedPreferences, so this writes to the same key in the same format as
 * `NotificationInboxService` (see lib/features/notifications). The Flutter
 * side re-reads the stored list whenever the app is opened or resumed.
 *
 * Best effort: a failure here must never get in the way of the alarm itself.
 */
object AppInbox {
    private const val TAG = "AppInbox"

    // Flutter's shared_preferences plugin stores everything in this file and
    // prefixes every key with "flutter.".
    private const val PREFS_FILE = "FlutterSharedPreferences"
    private const val KEY = "flutter.amica_notification_inbox_v1"
    private const val MAX_ITEMS = 100

    private val lock = Any()

    fun add(context: Context, type: String, title: String, body: String) {
        try {
            synchronized(lock) {
                val prefs = context.applicationContext
                    .getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
                val existing = prefs.getString(KEY, null)
                val old = try {
                    if (existing.isNullOrEmpty()) JSONArray() else JSONArray(existing)
                } catch (_: Exception) {
                    JSONArray()
                }

                val now = Date()
                // Local time with no zone suffix: Dart reads that as local
                // time, the same as its own toIso8601String() does.
                val stamp = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US)
                    .format(now)
                val entry = JSONObject()
                    .put("id", "${now.time}000-$type")
                    .put("type", type)
                    .put("title", title)
                    .put("body", body)
                    .put("receivedAt", stamp)
                    .put("read", false)
                    .put("data", JSONObject())

                val merged = JSONArray().put(entry)
                var i = 0
                while (i < old.length() && merged.length() < MAX_ITEMS) {
                    merged.put(old.get(i))
                    i++
                }
                prefs.edit().putString(KEY, merged.toString()).apply()
            }
        } catch (error: Exception) {
            Log.w(TAG, "Could not add to the in-app notification list", error)
        }
    }
}
