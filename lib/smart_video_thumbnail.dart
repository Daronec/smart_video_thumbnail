import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'src/cache/thumbnail_cache.dart';
import 'src/models/cache_stats.dart';
import 'src/progress/progress_handler.dart';

export 'src/models/cache_stats.dart';

/// Стратегия извлечения кадра
enum ThumbnailStrategy {
  /// Обычный seek по времени
  normal,

  /// Seek с упором на ключевые кадры
  keyframe,

  /// Извлечение первого доступного кадра (без seek)
  firstFrame,
}

/// Flutter плагин для генерации обложек видео через нативный FFmpeg движок
///
/// Использует CPU-only декодирование FFmpeg для извлечения кадров из видео.
/// Поддерживает все форматы, которые поддерживает FFmpeg (MP4, AVI, MKV, FLV, и т.д.)
class SmartVideoThumbnail {
  static const MethodChannel _channel = MethodChannel('smart_video_thumbnail');
  static final ThumbnailCache _cache = ThumbnailCache();

  /// Получить thumbnail для видео
  ///
  /// [videoPath] - путь к видеофайлу
  /// [timeMs] - целевая позиция в миллисекундах (по умолчанию 1000ms)
  /// [width] - ширина thumbnail (по умолчанию 720px)
  /// [height] - высота thumbnail (по умолчанию вычисляется как 16:9 от width)
  /// [size] - альтернативный способ задать размер (используется если width не указан)
  /// [strategy] - стратегия извлечения кадра
  /// [useCache] - использовать кэширование (по умолчанию true)
  /// [onProgress] - callback для получения прогресса генерации (опционально)
  ///
  /// Возвращает [Uint8List] с RGBA данными или null при ошибке
  ///
  /// Пример использования:
  /// ```dart
  /// final thumbnail = await SmartVideoThumbnail.getThumbnail(
  ///   videoPath: '/path/to/video.mp4',
  ///   timeMs: 1000,
  ///   width: 320,
  ///   height: 180,
  ///   useCache: true,
  ///   onProgress: (progress) {
  ///     print('Progress: ${(progress * 100).toInt()}%');
  ///   },
  /// );
  ///
  /// if (thumbnail != null) {
  ///   // Используем thumbnail (RGBA8888 формат)
  ///   // Размер данных: width * height * 4 байта
  /// }
  /// ```
  static Future<Uint8List?> getThumbnail({
    required String videoPath,
    int timeMs = 1000,
    int? width,
    int? height,
    int size = 720,
    ThumbnailStrategy strategy = ThumbnailStrategy.normal,
    bool useCache = true,
    void Function(double progress)? onProgress,
  }) async {
    String? requestId;
    StreamSubscription<double>? progressSubscription;

    try {
      final effectiveWidth = width ?? size;
      final effectiveHeight = height ?? (size * 9 ~/ 16);

      // Check cache if enabled
      if (useCache) {
        final cacheKey = _cache.generateKey(
          videoPath,
          timeMs,
          effectiveWidth,
          effectiveHeight,
          strategy.name,
        );

        final cachedData = await _cache.get(cacheKey);
        if (cachedData != null) {
          if (kDebugMode) {
            debugPrint('✅ SmartVideoThumbnail: Cache hit for $cacheKey');
          }

          // For cache hits, immediately report 100% progress
          if (onProgress != null) {
            onProgress(1.0);
          }

          return cachedData;
        }
      }

      // Setup progress tracking if callback provided
      if (onProgress != null) {
        requestId = ProgressHandler.generateRequestId();
        final progressStream = ProgressHandler.getProgressStream(requestId);

        progressSubscription = progressStream.listen(
          (progress) {
            try {
              onProgress(progress);
            } catch (e) {
              if (kDebugMode) {
                debugPrint(
                  '⚠️ SmartVideoThumbnail: Progress callback error: $e',
                );
              }
            }
          },
          onError: (error) {
            if (kDebugMode) {
              debugPrint(
                '⚠️ SmartVideoThumbnail: Progress stream error: $error',
              );
            }
          },
        );
      }

      // Generate thumbnail
      if (kDebugMode) {
        debugPrint('🎬 SmartVideoThumbnail: Calling native getThumbnail');
        debugPrint('   videoPath: $videoPath');
        debugPrint('   timeMs: $timeMs');
        debugPrint('   size: ${effectiveWidth}x$effectiveHeight');
        debugPrint('   strategy: ${strategy.name}');
      }

      final result = await _channel.invokeMethod<Uint8List>('getThumbnail', {
        'path': videoPath,
        'timeMs': timeMs,
        'width': effectiveWidth,
        'height': effectiveHeight,
        'size': size,
        'strategy': strategy.name,
        if (requestId != null) 'requestId': requestId,
      });

      if (kDebugMode) {
        if (result != null) {
          debugPrint('✅ SmartVideoThumbnail: Native call succeeded, received ${result.length} bytes');
        } else {
          debugPrint('⚠️ SmartVideoThumbnail: Native call returned null');
        }
      }

      // Store in cache if enabled and generation succeeded
      if (useCache && result != null) {
        final cacheKey = _cache.generateKey(
          videoPath,
          timeMs,
          effectiveWidth,
          effectiveHeight,
          strategy.name,
        );

        // Cache asynchronously without waiting
        _cache.put(cacheKey, result).catchError((e) {
          if (kDebugMode) {
            debugPrint('⚠️ SmartVideoThumbnail: Failed to cache: $e');
          }
        });
      }

      return result;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '❌ SmartVideoThumbnail: PlatformException: ${e.code} - ${e.message}',
        );
        if (e.details != null) {
          debugPrint('   Details: ${e.details}');
        }
        debugPrint('   Stack trace: ${e.stacktrace}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SmartVideoThumbnail: Unexpected error: $e');
      }
      return null;
    } finally {
      // Clean up progress tracking
      if (requestId != null) {
        await progressSubscription?.cancel();
        ProgressHandler.cancelProgress(requestId);
      }
    }
  }

  /// Проверить, доступен ли плагин на текущей платформе
  static Future<bool> isAvailable() async {
    try {
      // Пытаемся вызвать метод - если плагин доступен, он ответит
      await _channel.invokeMethod('getThumbnail', {
        'path': '',
        'timeMs': 0,
        'width': 1,
        'height': 1,
      });
      return true;
    } catch (e) {
      // Если получили ошибку "BAD_ARGS" - плагин работает
      if (e is PlatformException && e.code == 'BAD_ARGS') {
        return true;
      }
      return false;
    }
  }

  /// Очистить весь кэш миниатюр
  ///
  /// Удаляет все закэшированные миниатюры из файловой системы.
  ///
  /// Пример использования:
  /// ```dart
  /// await SmartVideoThumbnail.clearCache();
  /// ```
  static Future<void> clearCache() async {
    try {
      await _cache.clear();
      if (kDebugMode) {
        debugPrint('✅ SmartVideoThumbnail: Cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SmartVideoThumbnail: Failed to clear cache: $e');
      }
      rethrow;
    }
  }

  /// Удалить закэшированные миниатюры для конкретного видео
  ///
  /// [videoPath] - путь к видеофайлу
  ///
  /// Удаляет все миниатюры, созданные для указанного видео,
  /// независимо от параметров генерации.
  ///
  /// Пример использования:
  /// ```dart
  /// await SmartVideoThumbnail.removeCacheForVideo('/path/to/video.mp4');
  /// ```
  static Future<void> removeCacheForVideo(String videoPath) async {
    try {
      await _cache.removeByVideoPath(videoPath);
      if (kDebugMode) {
        debugPrint('✅ SmartVideoThumbnail: Cache removed for $videoPath');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SmartVideoThumbnail: Failed to remove cache: $e');
      }
      rethrow;
    }
  }

  /// Получить статистику кэша
  ///
  /// Возвращает [CacheStats] с информацией о количестве файлов,
  /// общем размере и отформатированном размере.
  ///
  /// Пример использования:
  /// ```dart
  /// final stats = await SmartVideoThumbnail.getCacheStats();
  /// print('Cached files: ${stats.fileCount}');
  /// print('Total size: ${stats.formattedSize}');
  /// ```
  static Future<CacheStats> getCacheStats() async {
    try {
      return await _cache.getCacheStats();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SmartVideoThumbnail: Failed to get cache stats: $e');
      }
      rethrow;
    }
  }
}
