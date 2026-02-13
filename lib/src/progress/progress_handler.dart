import 'dart:async';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

/// Handles progress events from native code via EventChannel.
class ProgressHandler {
  static const EventChannel _progressChannel = EventChannel(
    'smart_video_thumbnail/progress',
  );

  static const _uuid = Uuid();
  static Stream<Map<dynamic, dynamic>>? _eventStream;
  static final Map<String, StreamController<double>> _controllers = {};

  /// Initialize the event stream if not already initialized.
  static void _ensureStreamInitialized() {
    if (_eventStream == null) {
      _eventStream = _progressChannel
          .receiveBroadcastStream()
          .cast<Map<dynamic, dynamic>>();

      _eventStream!.listen(
        (event) {
          final requestId = event['requestId'] as String?;
          final progress = event['progress'] as double?;

          if (requestId != null && progress != null) {
            final controller = _controllers[requestId];
            if (controller != null && !controller.isClosed) {
              controller.add(progress);

              // Close controller when progress reaches 1.0
              if (progress >= 1.0) {
                controller.close();
                _controllers.remove(requestId);
              }
            }
          }
        },
        onError: (error) {
          // Handle stream errors
          for (final controller in _controllers.values) {
            if (!controller.isClosed) {
              controller.addError(error);
            }
          }
        },
      );
    }
  }

  /// Generate a unique request ID for tracking operations.
  static String generateRequestId() {
    return _uuid.v4();
  }

  /// Get a progress stream for a specific request ID.
  static Stream<double> getProgressStream(String requestId) {
    _ensureStreamInitialized();

    final controller = StreamController<double>.broadcast();
    _controllers[requestId] = controller;

    return controller.stream;
  }

  /// Cancel progress tracking for a specific request ID.
  static void cancelProgress(String requestId) {
    final controller = _controllers[requestId];
    if (controller != null && !controller.isClosed) {
      controller.close();
      _controllers.remove(requestId);
    }
  }

  /// Clean up all progress controllers.
  static void dispose() {
    for (final controller in _controllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _controllers.clear();
  }
}
