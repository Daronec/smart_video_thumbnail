import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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

  /// Получить thumbnail для видео
  ///
  /// [videoPath] - путь к видеофайлу
  /// [timeMs] - целевая позиция в миллисекундах (по умолчанию 1000ms)
  /// [width] - ширина thumbnail (по умолчанию 720px)
  /// [height] - высота thumbnail (по умолчанию вычисляется как 16:9 от width)
  /// [size] - альтернативный способ задать размер (используется если width не указан)
  /// [strategy] - стратегия извлечения кадра
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
  }) async {
    try {
      final effectiveWidth = width ?? size;
      final effectiveHeight = height ?? (size * 9 ~/ 16);

      final result = await _channel.invokeMethod<Uint8List>('getThumbnail', {
        'path': videoPath,
        'timeMs': timeMs,
        'width': effectiveWidth,
        'height': effectiveHeight,
        'size': size,
        'strategy': strategy.name,
      });

      return result;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '❌ SmartVideoThumbnail: Error getting thumbnail: ${e.code} - ${e.message}',
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SmartVideoThumbnail: Unexpected error: $e');
      }
      return null;
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
}
