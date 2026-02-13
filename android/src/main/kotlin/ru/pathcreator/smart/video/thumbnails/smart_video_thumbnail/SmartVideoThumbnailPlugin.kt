package ru.pathcreator.smart.video.thumbnails.smart_video_thumbnail

import android.util.Log
import com.smartmedia.ffmpeg.SmartFfmpegBridge
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

/// Flutter плагин для генерации обложек видео через Smart FFmpeg Android Library
///
/// Использует опубликованную библиотеку com.smartmedia:smart-ffmpeg-android:1.0.0
/// из GitHub Packages вместо локальной нативной сборки.
class SmartVideoThumbnailPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel

    companion object {
        private const val TAG = "SmartVideoThumbnail"
        private const val CHANNEL_NAME = "smart_video_thumbnail"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "✅ SmartVideoThumbnailPlugin: onAttachedToEngine вызван")
        
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        
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
                val path = call.argument<String>("path")
                val size = call.argument<Int>("size") ?: 720
                val width = call.argument<Int>("width") ?: size
                val height = call.argument<Int>("height") ?: ((size * 9 / 16).toInt())
                val timeMs = (call.argument<Number>("timeMs"))?.toLong() ?: 1000L
                val strategyRaw = call.argument<String>("strategy") ?: "normal"
                
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
                    "🎬 getThumbnail: path=$path, targetMs=$effectiveTargetMs, size=${width}x${height}, strategy=$normalizedStrategy"
                )

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

                result.success(thumbnailData)
                Log.d(TAG, "✅ getThumbnail: Thumbnail extracted successfully (${thumbnailData.size} bytes)")
            } catch (e: Exception) {
                Log.e(TAG, "❌ getThumbnail failed: ${e.message}", e)
                result.error("EXTRACTION_FAILED", e.message, null)
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
        Log.d(TAG, "🔄 SmartVideoThumbnailPlugin: onDetachedFromEngine")
    }
}
