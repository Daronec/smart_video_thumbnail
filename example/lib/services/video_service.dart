import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_video_thumbnail/smart_video_thumbnail.dart';

/// Сервис для работы с видео файлами и генерации миниатюр.
/// 
/// Предоставляет функциональность для выбора видео файлов
/// и генерации их миниатюр с использованием SmartVideoThumbnail.
class VideoService {
  /// Запрашивает разрешения на доступ к видео файлам.
  /// 
  /// Возвращает `true` если разрешение получено, иначе `false`.
  Future<bool> requestPermissions() async {
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

  /// Открывает диалог выбора видео файла.
  /// 
  /// Возвращает путь к выбранному файлу или `null` если выбор отменен.
  /// Выбрасывает исключение если нет разрешения на доступ к видео.
  Future<String?> pickVideo() async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        throw Exception('Нет разрешения на доступ к видео');
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first.path;
      }
      return null;
    } catch (e) {
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
