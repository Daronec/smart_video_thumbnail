import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Web implementation of SmartVideoThumbnail plugin
class SmartVideoThumbnailWeb {
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'smart_video_thumbnail',
      const StandardMethodCodec(),
      registrar,
    );

    final pluginInstance = SmartVideoThumbnailWeb();
    channel.setMethodCallHandler(pluginInstance.handleMethodCall);
  }

  /// Handles method calls from Dart
  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'getThumbnail':
        return await _getThumbnail(call.arguments);
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'smart_video_thumbnail for web doesn\'t implement \'${call.method}\'',
        );
    }
  }

  /// Extract thumbnail from video
  Future<Uint8List?> _getThumbnail(dynamic arguments) async {
    try {
      final args = arguments as Map<dynamic, dynamic>;
      final String videoPath = args['path'] as String;
      final int timeMs = args['timeMs'] as int? ?? 1000;
      final int width = args['width'] as int? ?? 720;
      final int height = args['height'] as int? ?? 405;

      if (kDebugMode) {
        print('🎬 SmartVideoThumbnail Web: getThumbnail called');
        print('   path: $videoPath');
        print('   timeMs: $timeMs');
        print('   size: ${width}x$height');
      }

      // Create video element
      final video = html.VideoElement()
        ..crossOrigin = 'anonymous'
        ..preload = 'metadata'
        ..style.display = 'none';

      // Add to DOM temporarily
      html.document.body?.append(video);

      try {
        // Load video
        final completer = Completer<void>();
        
        void onLoadedMetadata(html.Event event) {
          completer.complete();
        }

        void onError(html.Event event) {
          completer.completeError('Failed to load video');
        }

        video.onLoadedMetadata.listen(onLoadedMetadata);
        video.onError.listen(onError);

        video.src = videoPath;
        video.load();

        // Wait for metadata to load
        await completer.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Video loading timeout');
          },
        );

        // Seek to desired time
        final seekCompleter = Completer<void>();
        
        void onSeeked(html.Event event) {
          seekCompleter.complete();
        }

        video.onSeeked.listen(onSeeked);
        video.currentTime = timeMs / 1000.0; // Convert to seconds

        // Wait for seek to complete
        await seekCompleter.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException('Video seek timeout');
          },
        );

        // Create canvas to capture frame
        final canvas = html.CanvasElement(width: width, height: height);
        final context = canvas.context2D;

        // Draw video frame to canvas
        context.drawImageScaled(video, 0, 0, width, height);

        // Get image data
        final imageData = context.getImageData(0, 0, width, height);
        final data = imageData.data;

        // Convert RGBA to Uint8List
        final result = Uint8List(width * height * 4);
        for (int i = 0; i < data.length; i++) {
          result[i] = data[i];
        }

        if (kDebugMode) {
          print('✅ SmartVideoThumbnail Web: Thumbnail extracted successfully (${result.length} bytes)');
        }

        return result;
      } finally {
        // Clean up
        video.remove();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ SmartVideoThumbnail Web: Error: $e');
      }
      return null;
    }
  }
}
