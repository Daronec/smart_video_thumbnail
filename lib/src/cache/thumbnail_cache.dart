import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/cache_stats.dart';

/// Manages file-based caching of generated thumbnails.
class ThumbnailCache {
  static const String _cacheDirectoryName = 'smart_video_thumbnails';

  Directory? _cacheDir;

  /// Get the cache directory, creating it if necessary.
  Future<Directory> getCacheDirectory() async {
    if (_cacheDir != null) {
      return _cacheDir!;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory(path.join(tempDir.path, _cacheDirectoryName));

      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      _cacheDir = cacheDir;
      return _cacheDir!;
    } catch (e) {
      throw Exception('Failed to get cache directory: $e');
    }
  }

  /// Generate a unique cache key from generation parameters.
  String generateKey(
    String videoPath,
    int timeMs,
    int width,
    int height,
    String strategy,
  ) {
    // Generate MD5 hash of video path
    final videoPathBytes = utf8.encode(videoPath);
    final videoPathHash =
        md5.convert(videoPathBytes).toString().substring(0, 16);

    // Format: {hash}_{timeMs}_{width}x{height}_{strategy}.rgba
    return '${videoPathHash}_${timeMs}_${width}x${height}_$strategy.rgba';
  }

  /// Get cached thumbnail if available.
  Future<Uint8List?> get(String cacheKey) async {
    try {
      final cacheDir = await getCacheDirectory();
      final cacheFile = File(path.join(cacheDir.path, cacheKey));

      if (!await cacheFile.exists()) {
        return null;
      }

      final data = await cacheFile.readAsBytes();
      return data;
    } catch (e) {
      // Log warning and return null on error
      debugPrint('Warning: Failed to read from cache: $e');
      return null;
    }
  }

  /// Store thumbnail in cache asynchronously.
  Future<void> put(String cacheKey, Uint8List data) async {
    try {
      final cacheDir = await getCacheDirectory();
      final cacheFile = File(path.join(cacheDir.path, cacheKey));

      // Write asynchronously
      await cacheFile.writeAsBytes(data);
    } catch (e) {
      // Log warning but don't throw - cache failure should not break generation
      debugPrint('Warning: Failed to write to cache: $e');
    }
  }

  /// Clear all cached thumbnails.
  Future<void> clear() async {
    try {
      final cacheDir = await getCacheDirectory();

      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list()) {
          if (entity is File && entity.path.endsWith('.rgba')) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to clear cache: $e');
    }
  }

  /// Remove cached thumbnails for a specific video path.
  Future<void> removeByVideoPath(String videoPath) async {
    try {
      final cacheDir = await getCacheDirectory();

      if (!await cacheDir.exists()) {
        return;
      }

      // Generate hash prefix for this video
      final videoPathBytes = utf8.encode(videoPath);
      final videoPathHash =
          md5.convert(videoPathBytes).toString().substring(0, 16);

      // Delete all files starting with this hash
      await for (final entity in cacheDir.list()) {
        if (entity is File &&
            entity.path.endsWith('.rgba') &&
            path.basename(entity.path).startsWith(videoPathHash)) {
          await entity.delete();
        }
      }
    } catch (e) {
      throw Exception('Failed to remove cache for video: $e');
    }
  }

  /// Get cache statistics.
  Future<CacheStats> getCacheStats() async {
    try {
      final cacheDir = await getCacheDirectory();

      if (!await cacheDir.exists()) {
        return const CacheStats(
          fileCount: 0,
          totalBytes: 0,
          formattedSize: '0 B',
        );
      }

      int fileCount = 0;
      int totalBytes = 0;

      await for (final entity in cacheDir.list()) {
        if (entity is File && entity.path.endsWith('.rgba')) {
          fileCount++;
          final stat = await entity.stat();
          totalBytes += stat.size;
        }
      }

      return CacheStats(
        fileCount: fileCount,
        totalBytes: totalBytes,
        formattedSize: _formatBytes(totalBytes),
      );
    } catch (e) {
      throw Exception('Failed to get cache stats: $e');
    }
  }

  /// Format bytes into human-readable string.
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
