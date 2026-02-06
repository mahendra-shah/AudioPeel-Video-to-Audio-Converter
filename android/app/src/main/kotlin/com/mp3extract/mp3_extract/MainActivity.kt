package com.mp3extract.mp3_extract

import android.content.ContentValues
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.mp3extract.app/ringtone"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setRingtone" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath == null) {
                        result.error("INVALID_ARGUMENT", "filePath is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        if (!Settings.System.canWrite(this)) {
                            result.error("PERMISSION_DENIED", "WRITE_SETTINGS permission not granted", null)
                            return@setMethodCallHandler
                        }
                        val success = setRingtone(filePath)
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("SET_RINGTONE_FAILED", e.message, null)
                    }
                }
                "canWriteSettings" -> {
                    result.success(Settings.System.canWrite(this))
                }
                "requestWriteSettings" -> {
                    val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).apply {
                        data = Uri.parse("package:$packageName")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setRingtone(filePath: String): Boolean {
        val file = File(filePath)
        if (!file.exists()) return false

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.TITLE, file.nameWithoutExtension)
            put(MediaStore.MediaColumns.MIME_TYPE, "audio/mpeg")
            put(MediaStore.Audio.Media.IS_RINGTONE, true)
            put(MediaStore.Audio.Media.IS_NOTIFICATION, false)
            put(MediaStore.Audio.Media.IS_ALARM, false)
            put(MediaStore.Audio.Media.IS_MUSIC, false)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.MediaColumns.RELATIVE_PATH, "Ringtones")
            } else {
                @Suppress("DEPRECATION")
                put(MediaStore.MediaColumns.DATA, filePath)
            }
        }

        val uri: Uri?
        val resolver = contentResolver

        // Check if already exists and delete first
        val existingUri = MediaStore.Audio.Media.getContentUriForPath(filePath)
        if (existingUri != null) {
            resolver.delete(
                existingUri,
                "${MediaStore.MediaColumns.TITLE} = ?",
                arrayOf(file.nameWithoutExtension)
            )
        }

        uri = resolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values)
        if (uri == null) return false

        // Copy file content for Android Q+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            resolver.openOutputStream(uri)?.use { outputStream ->
                file.inputStream().use { inputStream ->
                    inputStream.copyTo(outputStream)
                }
            }
        }

        RingtoneManager.setActualDefaultRingtoneUri(
            this,
            RingtoneManager.TYPE_RINGTONE,
            uri
        )
        return true
    }
}
