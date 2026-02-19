import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_video_thumbnail/smart_video_thumbnail.dart';

// Conditional import для web/non-web платформ
import 'web_utils_stub.dart'
    if (dart.library.html) 'web_utils_web.dart' as web_utils;

/// Сервис для работы с видео файлами и генерации миниатюр.
/// 
/// Предоставляет функциональность для выбора видео файлов
/// и генерации их миниатюр с использованием SmartVideoThumbnail.
class VideoService {
  /// Запрашивает разрешения на доступ к видео файлам.
  /// 
  /// Возвращает `true` если разрешение получено, иначе `false`.
  /// На web платформе всегда возвращает `true` (разрешения не требуются).
  Future<bool> requestPermissions() async {
    // На web разрешения не требуются
    if (kIsWeb) {
      return true;
    }

    if (await Permission.videos.isGranted) {
      return true;
    }

    final status = await Permission.videos.request();
    if (status.isDenied) {
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }

    return status.isGranted;
  }

  /// Получить MIME type для видео файла по расширению
  String _getMimeType(String? extension) {
    if (extension == null) return 'video/mp4';
    
    switch (extension.toLowerCase()) {
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      case 'ogg':
      case 'ogv':
        return 'video/ogg';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'wmv':
        return 'video/x-ms-wmv';
      case 'flv':
        return 'video/x-flv';
      case 'mkv':
        return 'video/x-matroska';
      default:
        return 'video/mp4';
    }
  }

  /// Открывает диалог выбора видео файла.
  /// 
  /// Возвращает путь к выбранному файлу или `null` если выбор отменен.
  /// Выбрасывает исключение если нет разрешения на доступ к видео.
  /// 
  /// **Важно:** На web платформе возвращается Blob URL вместо файлового пути.
  /// **Ограничения web:** Браузеры поддерживают только MP4, WebM и Ogg форматы.
  /// AVI, WMV, FLV и другие форматы могут не работать.
  Future<String?> pickVideo() async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        throw Exception('Нет разрешения на доступ к видео');
      }

      if (kDebugMode) {
        debugPrint('🎬 VideoService: Открытие диалога выбора видео файла');
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        withData: kIsWeb, // На web загружаем bytes
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // На web создаём Blob URL из bytes
        if (kIsWeb) {
          final bytes = file.bytes;
          if (bytes == null) {
            throw Exception('Не удалось получить данные файла');
          }
          
          final extension = file.extension?.toLowerCase();
          final mimeType = _getMimeType(extension);
          
          // Предупреждение о неподдерживаемых форматах
          final unsupportedFormats = ['avi', 'wmv', 'flv', 'mkv'];
          if (extension != null && unsupportedFormats.contains(extension)) {
            if (kDebugMode) {
              debugPrint('⚠️ VideoService: Формат .$extension может не поддерживаться браузером');
              debugPrint('   Рекомендуемые форматы: MP4, WebM, Ogg');
              debugPrint('   Попытка создать Blob с MIME type: $mimeType');
            }
          }
          
          // Создаём Blob URL для использования в video element
          final blob = web_utils.Blob([bytes], mimeType);
          final blobUrl = web_utils.Url.createObjectUrlFromBlob(blob);
          
          if (kDebugMode) {
            debugPrint('✅ VideoService: Создан Blob URL для web');
            debugPrint('   Имя файла: ${file.name}');
            debugPrint('   Расширение: .$extension');
            debugPrint('   MIME type: $mimeType');
            debugPrint('   Размер: ${file.size} байт');
            debugPrint('   Blob URL: $blobUrl');
          }
          
          return blobUrl;
        }
        
        // На других платформах используем обычный path
        final videoPath = file.path;
        if (kDebugMode) {
          debugPrint('✅ VideoService: Выбран файл: $videoPath');
          debugPrint('   Имя файла: ${file.name}');
          debugPrint('   Размер: ${file.size} байт');
        }
        return videoPath;
      }
      
      if (kDebugMode) {
        debugPrint('⚠️ VideoService: Выбор файла отменен пользователем');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ VideoService: Ошибка при выборе файла: $e');
      }
      rethrow;
    }
  }

  /// Генерирует миниатюру для видео файла.
  /// 
  /// Параметры:
  /// - [videoPath]: Путь к видео файлу
  /// 
  /// Возвращает [ui.Image] миниатюры или `null` при ошибке.
  Future<ui.Image?> generateThumbnail(String videoPath) async {
    try {
      final thumbnail = await SmartVideoThumbnail.getThumbnail(
        videoPath: videoPath,
        timeMs: 1000,
        width: 320,
        height: 180,
        strategy: ThumbnailStrategy.normal,
      );

      if (thumbnail != null) {
        return await _createImageFromRGBA(thumbnail, 320, 180);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<ui.Image> _createImageFromRGBA(
    Uint8List rgba,
    int width,
    int height,
  ) async {
    final completer = Completer<ui.Image>();

    ui.decodeImageFromPixels(rgba, width, height, ui.PixelFormat.rgba8888, (
      ui.Image image,
    ) {
      completer.complete(image);
    });

    return completer.future;
  }
}
