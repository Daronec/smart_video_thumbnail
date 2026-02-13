package ru.pathcreator.smart.video.thumbnails.smart_video_thumbnail

import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.smartmedia.ffmpeg.SmartFfmpegBridge
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

/// Flutter плагин для генерации обложек видео через Smart FFmpeg Android Library
///
/// Использует опубликованную библиотеку com.smartmedia:smart-ffmpeg-android:1.0.0
/// из GitHub Packages вместо локальной нативной сборки.
class SmartVideoThumbnailPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var progressChannel: EventChannel
    private var progressEventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        private const val TAG = "SmartVideoThumbnail"
        private const val CHANNEL_NAME = "smart_video_thumbnail"
        private const val PROGRESS_CHANNEL_NAME = "smart_video_thumbnail/progress"
        
        // Supported architectures
        private val SUPPORTED_ABIS = setOf("arm64-v8a", "armeabi-v7a")
    }
    
    /// Check if current architecture is supported
    private fun isArchitectureSupported(): Boolean {
        val currentAbi = Build.SUPPORTED_ABIS.firstOrNull() ?: return false
        return SUPPORTED_ABIS.contains(currentAbi)
    }
    
    /// Get architecture error message
    private fun getArchitectureErrorMessage(): String {
        val currentAbi = Build.SUPPORTED_ABIS.firstOrNull() ?: "unknown"
        return "smart_video_thumbnail only supports arm64-v8a and armeabi-v7a architectures. " +
               "Current architecture: $currentAbi. " +
               "This plugin is optimized for physical Android devices and does not support x86/x86_64 emulators."
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "✅ SmartVideoThumbnailPlugin: onAttachedToEngine вызван")
        
        // Check architecture support
        if (!isArchitectureSupported()) {
            Log.w(TAG, "⚠️ ${getArchitectureErrorMessage()}")
        }
        
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        
        // Setup progress event channel
        progressChannel = EventChannel(binding.binaryMessenger, PROGRESS_CHANNEL_NAME)
        progressChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                progressEventSink = events
                Log.d(TAG, "✅ Progress EventChannel: Listener attached")
            }

            override fun onCancel(arguments: Any?) {
                progressEventSink = null
                Log.d(TAG, "🔄 Progress EventChannel: Listener cancelled")
            }
        })
        
        // Проверяем версию FFmpeg
        try {
            val ffmpegVersion = SmartFfmpegBridge.getFFmpegVersion()
            Log.d(TAG, "✅ SmartVideoThumbnailPlugin: FFmpeg version: $ffmpegVersion")
        } catch (e: Exception) {
            Log.e(TAG, "❌ SmartVideoThumbnailPlugin: Failed to get FFmpeg version", e)
        }
        
        Log.d(TAG, "✅ SmartVideoThumbnailPlugin: Канал '$CHANNEL_NAME' настроен")
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "🎬 SmartVideoThumbnailPlugin: Метод вызван: ${call.method}")
        
        when (call.method) {
            "getThumbnail" -> {
                handleGetThumbnail(call, result)
            }
            "getVideoDuration" -> {
                handleGetVideoDuration(call, result)
            }
            "getVideoMetadata" -> {
                handleGetVideoMetadata(call, result)
            }
            else -> {
                Log.w(TAG, "⚠️ SmartVideoThumbnailPlugin: Неизвестный метод: ${call.method}")
                result.notImplemented()
            }
        }
    }

    /// Обработка метода getThumbnail
    ///
    /// Использует SmartFfmpegBridge.extractThumbnail() из библиотеки
    private fun handleGetThumbnail(call: MethodCall, result: MethodChannel.Result) {
        synchronized(this) {
            try {
                // Check architecture support first
                if (!isArchitectureSupported()) {
                    Log.e(TAG, "❌ Unsupported architecture")
                    result.error("UNSUPPORTED_ARCHITECTURE", getArchitectureErrorMessage(), null)
                    return
                }
                
                val path = call.argument<String>("path")
                val size = call.argument<Int>("size") ?: 720
                val width = call.argument<Int>("width") ?: size
                val height = call.argument<Int>("height") ?: ((size * 9 / 16).toInt())
                val timeMs = (call.argument<Number>("timeMs"))?.toLong() ?: 1000L
                val strategyRaw = call.argument<String>("strategy") ?: "normal"
                val requestId = call.argument<String>("requestId")
                
                if (path == null) {
                    Log.e(TAG, "❌ SmartVideoThumbnailPlugin: Путь к файлу отсутствует")
                    result.error("BAD_ARGS", "File path missing", null)
                    return
                }

                // Проверка доступа к файлу
                try {
                    val f = java.io.File(path)
                    Log.d(
                        TAG,
                        "🧪 FILE CHECK:\n" +
                        "   path=$path\n" +
                        "   exists=${f.exists()}\n" +
                        "   canRead=${f.canRead()}\n" +
                        "   length=${runCatching { f.length() }.getOrNull()}\n" +
                        "   isContentUri=${path.startsWith("content://")}"
                    )
                } catch (e: Exception) {
                    Log.e(TAG, "❌ File access diagnostic failed", e)
                }

                // Нормализуем стратегию
                val normalizedStrategy = strategyRaw.lowercase(Locale.getDefault())
                val isFirstFramePolicy = normalizedStrategy == "firstframe"
                val effectiveTargetMs = if (isFirstFramePolicy) 0L else timeMs

                Log.d(
                    TAG,
                    "🎬 getThumbnail: path=$path, targetMs=$effectiveTargetMs, size=${width}x${height}, strategy=$normalizedStrategy, requestId=$requestId"
                )

                // Send progress updates if requestId is provided
                if (requestId != null) {
                    sendProgress(requestId, 0.0)
                    sendProgress(requestId, 0.2) // File opened
                    sendProgress(requestId, 0.4) // Codec initialized
                    sendProgress(requestId, 0.6) // Seeking
                }

                // Используем SmartFfmpegBridge из библиотеки
                val thumbnailData = SmartFfmpegBridge.extractThumbnail(
                    videoPath = path,
                    timeMs = effectiveTargetMs,
                    width = width,
                    height = height
                )

                if (thumbnailData == null) {
                    Log.e(TAG, "❌ getThumbnail: FFmpeg extraction failed")
                    result.error("EXTRACTION_FAILED", "FFmpeg thumbnail extraction failed", null)
                    return
                }

                // Send final progress updates
                if (requestId != null) {
                    sendProgress(requestId, 0.8) // Decoding
                    sendProgress(requestId, 0.9) // Scaling
                    sendProgress(requestId, 1.0) // Complete
                }

                result.success(thumbnailData)
                Log.d(TAG, "✅ getThumbnail: Thumbnail extracted successfully (${thumbnailData.size} bytes)")
            } catch (e: Exception) {
                Log.e(TAG, "❌ getThumbnail failed: ${e.message}", e)
                result.error("EXTRACTION_FAILED", e.message, null)
            }
        }
    }

    /// Send progress update on main thread
    private fun sendProgress(requestId: String, progress: Double) {
        mainHandler.post {
            try {
                progressEventSink?.success(mapOf(
                    "requestId" to requestId,
                    "progress" to progress
                ))
                Log.d(TAG, "📊 Progress: $requestId -> ${(progress * 100).toInt()}%")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to send progress: ${e.message}")
            }
        }
    }

    /// Обработка метода getVideoDuration
    private fun handleGetVideoDuration(call: MethodCall, result: MethodChannel.Result) {
        try {
            val path = call.argument<String>("path")
            
            if (path == null) {
                result.error("BAD_ARGS", "File path missing", null)
                return
            }

            val duration = SmartFfmpegBridge.getVideoDuration(path)
            
            if (duration < 0) {
                result.error("DURATION_FAILED", "Failed to get video duration", null)
                return
            }

            result.success(duration)
            Log.d(TAG, "✅ getVideoDuration: $duration ms")
        } catch (e: Exception) {
            Log.e(TAG, "❌ getVideoDuration failed: ${e.message}", e)
            result.error("DURATION_FAILED", e.message, null)
        }
    }

    /// Обработка метода getVideoMetadata
    private fun handleGetVideoMetadata(call: MethodCall, result: MethodChannel.Result) {
        try {
            val path = call.argument<String>("path")
            
            if (path == null) {
                result.error("BAD_ARGS", "File path missing", null)
                return
            }

            val metadata = SmartFfmpegBridge.getVideoMetadata(path)
            
            if (metadata == null) {
                result.error("METADATA_FAILED", "Failed to get video metadata", null)
                return
            }

            result.success(metadata)
            Log.d(TAG, "✅ getVideoMetadata: $metadata")
        } catch (e: Exception) {
            Log.e(TAG, "❌ getVideoMetadata failed: ${e.message}", e)
            result.error("METADATA_FAILED", e.message, null)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        progressChannel.setStreamHandler(null)
        progressEventSink = null
        Log.d(TAG, "🔄 SmartVideoThumbnailPlugin: onDetachedFromEngine")
    }
}
