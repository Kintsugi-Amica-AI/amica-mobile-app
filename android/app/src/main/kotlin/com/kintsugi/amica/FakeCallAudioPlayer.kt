package com.kintsugi.amica

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioDeviceInfo
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import io.flutter.FlutterInjector

/**
 * Plays the Fake Call caller voice the way a real call sounds.
 *
 * Audio goes out on the voice-call path, so it comes from the earpiece (or a
 * connected headset) unless the user taps Speaker, and the volume keys adjust
 * call volume. The main clip plays once. The optional filler clip, which is
 * short "mm-hm"s with long gaps, then loops so a long call never goes fully
 * quiet.
 *
 * Audio focus changes are ignored on purpose: Voice SOS starts the speech
 * recognizer during the call, and a real call would not pause for that.
 */
class FakeCallAudioPlayer(private val context: Context) {
    private val audioManager =
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val attributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
        .build()

    private var player: MediaPlayer? = null
    private var focusRequest: AudioFocusRequest? = null
    private var previousMode: Int? = null
    private var active = false

    val isActive: Boolean
        get() = active

    fun start(clipAsset: String, fillerAsset: String?, speakerOn: Boolean) {
        stop()
        active = true
        requestFocus()
        previousMode = audioManager.mode
        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
        setSpeaker(speakerOn)
        play(clipAsset, loop = false) {
            if (fillerAsset != null && active) {
                try {
                    play(fillerAsset, loop = true, onDone = null)
                } catch (_: Exception) {
                    // Filler is optional; the call just goes quiet.
                    releasePlayer()
                }
            } else {
                releasePlayer()
            }
        }
    }

    fun setSpeaker(on: Boolean) {
        if (!active) {
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val devices = audioManager.availableCommunicationDevices
            val preferred = if (on) {
                listOf(AudioDeviceInfo.TYPE_BUILTIN_SPEAKER)
            } else {
                // A headset wins over the earpiece, like a real call.
                listOf(
                    AudioDeviceInfo.TYPE_WIRED_HEADSET,
                    AudioDeviceInfo.TYPE_USB_HEADSET,
                    AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
                    AudioDeviceInfo.TYPE_BLE_HEADSET,
                    AudioDeviceInfo.TYPE_BUILTIN_EARPIECE,
                )
            }
            val device = preferred.firstNotNullOfOrNull { type ->
                devices.firstOrNull { it.type == type }
            }
            if (device != null) {
                audioManager.setCommunicationDevice(device)
            } else {
                audioManager.clearCommunicationDevice()
            }
        } else {
            @Suppress("DEPRECATION")
            audioManager.isSpeakerphoneOn = on
        }
    }

    fun stop() {
        if (!active) {
            return
        }
        active = false
        releasePlayer()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            audioManager.clearCommunicationDevice()
        } else {
            @Suppress("DEPRECATION")
            audioManager.isSpeakerphoneOn = false
        }
        previousMode?.let { audioManager.mode = it }
        previousMode = null
        abandonFocus()
    }

    private fun play(asset: String, loop: Boolean, onDone: (() -> Unit)?) {
        releasePlayer()
        val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(asset)
        val mediaPlayer = MediaPlayer()
        try {
            // .m4a is stored uncompressed in the APK, so openFd works.
            context.assets.openFd(key).use { fd ->
                mediaPlayer.setDataSource(fd.fileDescriptor, fd.startOffset, fd.length)
            }
            mediaPlayer.setAudioAttributes(attributes)
            mediaPlayer.isLooping = loop
            mediaPlayer.setOnCompletionListener {
                if (!loop) {
                    onDone?.invoke()
                }
            }
            mediaPlayer.setOnErrorListener { _, _, _ ->
                releasePlayer()
                true
            }
            mediaPlayer.prepare()
            mediaPlayer.start()
            player = mediaPlayer
        } catch (error: Exception) {
            mediaPlayer.release()
            throw error
        }
    }

    private fun releasePlayer() {
        player?.let {
            try {
                it.stop()
            } catch (_: IllegalStateException) {
                // Already stopped or never prepared.
            }
            it.release()
        }
        player = null
    }

    private fun requestFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(attributes)
                .setOnAudioFocusChangeListener { _ -> }
                .build()
            audioManager.requestAudioFocus(request)
            focusRequest = request
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                null,
                AudioManager.STREAM_VOICE_CALL,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT,
            )
        }
    }

    private fun abandonFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
            focusRequest = null
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(null)
        }
    }
}
