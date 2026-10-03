package com.mcore.audiopeel

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ContentValues
import android.content.Intent
import android.graphics.Bitmap
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.media.MediaScannerConnection
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Hosts the Flutter UI and exposes the "media bridge" used by the Dart layer:
 * zero-copy video picking, probing, thumbnails, saving to Music/AudioPeel via
 * MediaStore, sharing, ringtones and share-to-app intents.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.mcore.audiopeel/media"
    private val requestPick = 4201
    private val outputFolder = "AudioPeel"

    private var channel: MethodChannel? = null
    private val io = Executors.newFixedThreadPool(2)
    private val mainHandler = Handler(Looper.getMainLooper())

    private var pendingPick: MethodChannel.Result? = null
    private var pendingShared: List<String> = emptyList()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).also {
            it.setMethodCallHandler(::onMethodCall)
        }
        pendingShared = extractSharedUris(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val uris = extractSharedUris(intent)
        if (uris.isNotEmpty()) channel?.invokeMethod("onShared", uris)
    }

    override fun onDestroy() {
        io.shutdown()
        super.onDestroy()
    }

    // ─── Dispatcher ──────────────────────────────────────────────────────

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "sdkInt" -> result.success(Build.VERSION.SDK_INT)
            "initialShared" -> {
                result.success(pendingShared)
                pendingShared = emptyList()
            }
            "pickVideos" -> pickVideos(call.argument<Boolean>("multiple") ?: false, result)
            "probe" -> background(result) { probe(Uri.parse(call.argument<String>("uri")!!)) }
            "thumbnail" -> background(result) {
                thumbnail(
                    Uri.parse(call.argument<String>("uri")!!),
                    (call.argument<Number>("ms") ?: 0).toLong(),
                    call.argument<Int>("width") ?: 480,
                )
            }
            "filmstrip" -> background(result) {
                filmstrip(
                    Uri.parse(call.argument<String>("uri")!!),
                    call.argument<Int>("count") ?: 8,
                    call.argument<Int>("width") ?: 160,
                )
            }
            "saveToLibrary" -> background(result) {
                saveToLibrary(
                    call.argument<String>("path")!!,
                    call.argument<String>("name")!!,
                    call.argument<String>("mime")!!,
                )
            }
            "delete" -> background(result) { delete(call.argument<String>("uri")!!) }
            "exists" -> background(result) { exists(call.argument<String>("uri")!!) }
            "share" -> {
                share(call.argument<List<String>>("uris") ?: emptyList(), call.argument<String>("mime") ?: "audio/*")
                result.success(true)
            }
            "openWith" -> result.success(openWith(call.argument<String>("uri")!!, call.argument<String>("mime") ?: "audio/*"))
            "openFolder" -> result.success(openFolder())
            "canWriteSettings" -> result.success(Settings.System.canWrite(this))
            "requestWriteSettings" -> {
                startActivity(
                    Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).apply {
                        data = Uri.parse("package:$packageName")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    },
                )
                result.success(null)
            }
            "setRingtone" -> background(result) {
                setRingtone(call.argument<String>("uri")!!, call.argument<Int>("type") ?: RingtoneManager.TYPE_RINGTONE)
            }
            else -> result.notImplemented()
        }
    }

    /** Runs [block] on the IO pool and posts its value (or error) back on the main thread. */
    private fun background(result: MethodChannel.Result, block: () -> Any?) {
        io.execute {
            try {
                val value = block()
                mainHandler.post { result.success(value) }
            } catch (e: Exception) {
                mainHandler.post { result.error("MEDIA_ERROR", e.message, null) }
            }
        }
    }

    // ─── Picking ─────────────────────────────────────────────────────────

    private fun pickVideos(multiple: Boolean, result: MethodChannel.Result) {
        pendingPick?.success(emptyList<String>())
        pendingPick = result
        val photoPicker = if (Build.VERSION.SDK_INT >= 33) {
            Intent(MediaStore.ACTION_PICK_IMAGES).apply {
                type = "video/*"
                if (multiple) putExtra(MediaStore.EXTRA_PICK_IMAGES_MAX, minOf(20, MediaStore.getPickImagesMaxLimit()))
            }
        } else {
            null
        }
        val documents = Intent(Intent.ACTION_GET_CONTENT).apply {
            type = "video/*"
            addCategory(Intent.CATEGORY_OPENABLE)
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, multiple)
        }
        try {
            startActivityForResult(photoPicker ?: documents, requestPick)
        } catch (e: ActivityNotFoundException) {
            try {
                startActivityForResult(documents, requestPick)
            } catch (e2: ActivityNotFoundException) {
                pendingPick = null
                result.error("NO_PICKER", "No app can pick videos", null)
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != requestPick) return
        val result = pendingPick ?: return
        pendingPick = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(emptyList<String>())
            return
        }
        val uris = mutableListOf<String>()
        val clip = data.clipData
        if (clip != null) {
            for (i in 0 until clip.itemCount) {
                clip.getItemAt(i).uri?.let { uri ->
                    try {
                        contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    } catch (_: Exception) {}
                    uris.add(uri.toString())
                }
            }
        } else {
            data.data?.let { uri ->
                try {
                    contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                } catch (_: Exception) {}
                uris.add(uri.toString())
            }
        }
        result.success(uris)
    }

    @Suppress("DEPRECATION")
    private fun extractSharedUris(intent: Intent?): List<String> {
        if (intent == null) return emptyList()
        val uris = mutableListOf<Uri>()
        when (intent.action) {
            Intent.ACTION_SEND -> {
                val uri = if (Build.VERSION.SDK_INT >= 33) {
                    intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    intent.getParcelableExtra(Intent.EXTRA_STREAM)
                }
                uri?.let { uris.add(it) }
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                val list = if (Build.VERSION.SDK_INT >= 33) {
                    intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)
                }
                list?.let { uris.addAll(it) }
            }
            Intent.ACTION_VIEW -> intent.data?.let { uris.add(it) }
        }
        // Consume the intent so a config change does not re-deliver it.
        if (uris.isNotEmpty()) intent.action = Intent.ACTION_MAIN
        return uris.map { it.toString() }
    }

    // ─── Probing ─────────────────────────────────────────────────────────

    private fun probe(uri: Uri): Map<String, Any?> {
        var name: String? = null
        var size: Long = 0
        if (uri.scheme == "file") {
            val f = File(uri.path!!)
            name = f.name
            size = f.length()
        } else {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)?.use { c ->
                if (c.moveToFirst()) {
                    val ni = c.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    val si = c.getColumnIndex(OpenableColumns.SIZE)
                    if (ni >= 0) name = c.getString(ni)
                    if (si >= 0 && !c.isNull(si)) size = c.getLong(si)
                }
            }
        }

        var durationMs = 0L
        var width = 0
        var height = 0
        var rotation = 0
        var hasAudio = false
        var hasVideo = false
        val retriever = MediaMetadataRetriever()
        try {
            contentResolver.openFileDescriptor(uri, "r")?.use { pfd ->
                retriever.setDataSource(pfd.fileDescriptor)
            } ?: run {
                retriever.setDataSource(this, uri)
            }
            durationMs = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0
            width = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull() ?: 0
            height = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull() ?: 0
            rotation = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
            hasAudio = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_HAS_AUDIO) == "yes"
            hasVideo = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_HAS_VIDEO) == "yes"
        } catch (e: Exception) {
            android.util.Log.e("AudioPeel", "MediaMetadataRetriever probe failed for $uri", e)
        } finally {
            try { retriever.release() } catch (_: Exception) {}
        }

        var audioMime: String? = null
        var sampleRate = 0
        var channels = 0
        var bitrate = 0
        val extractor = MediaExtractor()
        try {
            contentResolver.openFileDescriptor(uri, "r")?.use { pfd ->
                extractor.setDataSource(pfd.fileDescriptor)
            } ?: run {
                extractor.setDataSource(this, uri, null)
            }
            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
                if (mime.startsWith("audio/")) {
                    audioMime = mime
                    hasAudio = true
                    if (format.containsKey(MediaFormat.KEY_SAMPLE_RATE)) sampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                    if (format.containsKey(MediaFormat.KEY_CHANNEL_COUNT)) channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                    if (format.containsKey(MediaFormat.KEY_BIT_RATE)) bitrate = format.getInteger(MediaFormat.KEY_BIT_RATE)
                    break
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("AudioPeel", "MediaExtractor probe failed for $uri", e)
        } finally {
            extractor.release()
        }

        return mapOf(
            "uri" to uri.toString(),
            "name" to (name ?: uri.lastPathSegment ?: "video"),
            "size" to size,
            "mime" to contentResolver.getType(uri),
            "durationMs" to durationMs,
            "width" to width,
            "height" to height,
            "rotation" to rotation,
            "hasAudio" to hasAudio,
            "hasVideo" to hasVideo,
            "audioMime" to audioMime,
            "sampleRate" to sampleRate,
            "channels" to channels,
            "bitrate" to bitrate,
        )
    }

    // ─── Frames ──────────────────────────────────────────────────────────

    private fun frameAt(retriever: MediaMetadataRetriever, timeUs: Long, width: Int): Bitmap? {
        val frame = if (Build.VERSION.SDK_INT >= 27) {
            val vw = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull() ?: width
            val vh = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull() ?: width
            val rot = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
            val (w, h) = if (rot == 90 || rot == 270) vh to vw else vw to vh
            val targetW = minOf(width, w.coerceAtLeast(1))
            val targetH = (targetW.toFloat() * h / w.coerceAtLeast(1)).toInt().coerceAtLeast(1)
            retriever.getScaledFrameAtTime(timeUs, MediaMetadataRetriever.OPTION_CLOSEST_SYNC, targetW, targetH)
        } else {
            retriever.getFrameAtTime(timeUs, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)?.let {
                val h = (width.toFloat() * it.height / it.width).toInt().coerceAtLeast(1)
                Bitmap.createScaledBitmap(it, width, h, true)
            }
        }
        return frame
    }

    private fun Bitmap.toJpeg(quality: Int = 82): ByteArray {
        val out = ByteArrayOutputStream()
        compress(Bitmap.CompressFormat.JPEG, quality, out)
        return out.toByteArray()
    }

    private fun thumbnail(uri: Uri, ms: Long, width: Int): ByteArray? {
        val retriever = MediaMetadataRetriever()
        return try {
            contentResolver.openFileDescriptor(uri, "r")?.use { pfd ->
                retriever.setDataSource(pfd.fileDescriptor)
            } ?: run {
                retriever.setDataSource(this, uri)
            }
            frameAt(retriever, ms * 1000, width)?.toJpeg()
        } catch (e: Exception) {
            android.util.Log.e("AudioPeel", "thumbnail extraction failed for $uri", e)
            null
        } finally {
            try { retriever.release() } catch (_: Exception) {}
        }
    }

    private fun filmstrip(uri: Uri, count: Int, width: Int): List<ByteArray> {
        val retriever = MediaMetadataRetriever()
        val frames = mutableListOf<ByteArray>()
        try {
            contentResolver.openFileDescriptor(uri, "r")?.use { pfd ->
                retriever.setDataSource(pfd.fileDescriptor)
            } ?: run {
                retriever.setDataSource(this, uri)
            }
            val duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0
            for (i in 0 until count) {
                val t = (duration * (i + 0.5) / count).toLong() * 1000
                frameAt(retriever, t, width)?.let { frames.add(it.toJpeg(70)) }
            }
        } catch (e: Exception) {
            android.util.Log.e("AudioPeel", "filmstrip extraction failed for $uri", e)
        } finally {
            try { retriever.release() } catch (_: Exception) {}
        }
        return frames
    }

    // ─── Saving ──────────────────────────────────────────────────────────

    private fun saveToLibrary(path: String, name: String, mime: String): Map<String, Any?> {
        val source = File(path)
        require(source.exists()) { "Converted file is missing" }

        if (Build.VERSION.SDK_INT >= 29) {
            val collection = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, name)
                put(MediaStore.MediaColumns.MIME_TYPE, mime)
                put(MediaStore.MediaColumns.RELATIVE_PATH, "${Environment.DIRECTORY_MUSIC}/$outputFolder")
                put(MediaStore.MediaColumns.IS_PENDING, 1)
                put(MediaStore.Audio.Media.IS_MUSIC, 1)
            }
            val uri = contentResolver.insert(collection, values) ?: error("Could not create the audio file")
            try {
                contentResolver.openOutputStream(uri)?.use { out -> source.inputStream().use { it.copyTo(out) } }
                    ?: error("Could not write the audio file")
                contentResolver.update(uri, ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }, null, null)
            } catch (e: Exception) {
                contentResolver.delete(uri, null, null)
                throw e
            }
            var finalName = name
            contentResolver.query(uri, arrayOf(MediaStore.MediaColumns.DISPLAY_NAME), null, null, null)?.use { c ->
                if (c.moveToFirst()) finalName = c.getString(0) ?: name
            }
            return mapOf(
                "uri" to uri.toString(),
                "name" to finalName,
                "displayPath" to "Music/$outputFolder/$finalName",
                "size" to source.length(),
            )
        }

        @Suppress("DEPRECATION")
        val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC), outputFolder)
        if (!dir.exists()) dir.mkdirs()
        val base = name.substringBeforeLast('.')
        val ext = name.substringAfterLast('.', "")
        var target = File(dir, name)
        var n = 1
        while (target.exists()) {
            target = File(dir, "$base ($n).$ext")
            n++
        }
        source.copyTo(target)
        val latch = CountDownLatch(1)
        var scanned: Uri? = null
        MediaScannerConnection.scanFile(this, arrayOf(target.absolutePath), arrayOf(mime)) { _, uri ->
            scanned = uri
            latch.countDown()
        }
        latch.await(4, TimeUnit.SECONDS)
        return mapOf(
            "uri" to (scanned?.toString() ?: target.absolutePath),
            "name" to target.name,
            "displayPath" to "Music/$outputFolder/${target.name}",
            "size" to target.length(),
        )
    }

    private fun delete(uri: String): Boolean {
        return try {
            if (uri.startsWith("content://")) {
                contentResolver.delete(Uri.parse(uri), null, null) > 0
            } else {
                File(uri).delete()
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun exists(uri: String): Boolean {
        return try {
            if (uri.startsWith("content://")) {
                contentResolver.query(Uri.parse(uri), arrayOf(MediaStore.MediaColumns._ID), null, null, null)?.use { it.count > 0 } ?: false
            } else {
                File(uri).exists()
            }
        } catch (_: Exception) {
            false
        }
    }

    // ─── Output actions ──────────────────────────────────────────────────

    private fun share(uris: List<String>, mime: String) {
        val parsed = uris.map { Uri.parse(it) }
        if (parsed.isEmpty()) return
        val intent = if (parsed.size == 1) {
            Intent(Intent.ACTION_SEND).apply { putExtra(Intent.EXTRA_STREAM, parsed.first()) }
        } else {
            Intent(Intent.ACTION_SEND_MULTIPLE).apply { putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(parsed)) }
        }
        intent.type = mime
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        val clip = ClipData.newRawUri("", parsed.first())
        parsed.drop(1).forEach { clip.addItem(ClipData.Item(it)) }
        intent.clipData = clip
        startActivity(Intent.createChooser(intent, null))
    }

    private fun openWith(uri: String, mime: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(Uri.parse(uri), mime)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(Intent.createChooser(intent, null))
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun openFolder(): Boolean {
        val docUri = DocumentsContract.buildDocumentUri(
            "com.android.externalstorage.documents",
            "primary:${Environment.DIRECTORY_MUSIC}/$outputFolder",
        )
        val attempts = mutableListOf(
            Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(docUri, DocumentsContract.Document.MIME_TYPE_DIR)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            },
            Intent("android.provider.action.BROWSE").apply { data = docUri },
        )
        if (Build.VERSION.SDK_INT >= 29) {
            attempts.add(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_APP_FILES))
        }
        for (intent in attempts) {
            try {
                startActivity(intent)
                return true
            } catch (_: Exception) {
            }
        }
        return false
    }

    private fun setRingtone(uriString: String, type: Int): Boolean {
        if (!Settings.System.canWrite(this)) throw SecurityException("WRITE_SETTINGS not granted")
        val flag = when (type) {
            RingtoneManager.TYPE_NOTIFICATION -> MediaStore.Audio.Media.IS_NOTIFICATION
            RingtoneManager.TYPE_ALARM -> MediaStore.Audio.Media.IS_ALARM
            else -> MediaStore.Audio.Media.IS_RINGTONE
        }
        val uri: Uri = if (uriString.startsWith("content://")) {
            val u = Uri.parse(uriString)
            try {
                contentResolver.update(u, ContentValues().apply { put(flag, 1) }, null, null)
            } catch (_: Exception) {
                // Not owned by us (e.g. after reinstall) — the URI still works as a ringtone.
            }
            u
        } else {
            insertLegacyRingtone(File(uriString), flag) ?: return false
        }
        RingtoneManager.setActualDefaultRingtoneUri(this, type, uri)
        return true
    }

    /** Copies a file-path audio (v1 app-private output) into MediaStore so it can be a ringtone. */
    private fun insertLegacyRingtone(file: File, flag: String): Uri? {
        if (!file.exists()) return null
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, file.name)
            put(MediaStore.MediaColumns.MIME_TYPE, "audio/mpeg")
            put(flag, 1)
            if (Build.VERSION.SDK_INT >= 29) {
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_RINGTONES)
            } else {
                @Suppress("DEPRECATION")
                put(MediaStore.MediaColumns.DATA, file.absolutePath)
            }
        }
        val uri = contentResolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values) ?: return null
        if (Build.VERSION.SDK_INT >= 29) {
            contentResolver.openOutputStream(uri)?.use { out -> file.inputStream().use { it.copyTo(out) } }
        }
        return uri
    }
}
