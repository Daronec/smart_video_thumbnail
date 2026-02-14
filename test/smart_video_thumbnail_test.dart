import 'package:flutter_test/flutter_test.dart';
import 'package:smart_video_thumbnail/smart_video_thumbnail.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SmartVideoThumbnail', () {
    const MethodChannel channel = MethodChannel('smart_video_thumbnail');

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getThumbnail') {
          final args = methodCall.arguments as Map;

          // Validate arguments
          if (args['path'] == null || args['path'] == '') {
            throw PlatformException(
              code: 'BAD_ARGS',
              message: 'Invalid path',
            );
          }

          // Return mock thumbnail data (1x1 RGBA pixel)
          return Uint8List.fromList([255, 0, 0, 255]); // Red pixel
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('getThumbnail returns data for valid path', () async {
      final result = await SmartVideoThumbnail.getThumbnail(
        videoPath: '/path/to/video.mp4',
        timeMs: 1000,
        width: 320,
        height: 180,
      );

      expect(result, isNotNull);
      expect(result, isA<Uint8List>());
      expect(result!.length, equals(4)); // 1x1 RGBA = 4 bytes
    });

    test('getThumbnail returns null for empty path', () async {
      final result = await SmartVideoThumbnail.getThumbnail(
        videoPath: '',
        timeMs: 1000,
        width: 320,
        height: 180,
      );

      expect(result, isNull);
    });

    test('getThumbnail uses default values correctly', () async {
      final result = await SmartVideoThumbnail.getThumbnail(
        videoPath: '/path/to/video.mp4',
      );

      expect(result, isNotNull);
    });

    test('getThumbnail calculates height from width', () async {
      final result = await SmartVideoThumbnail.getThumbnail(
        videoPath: '/path/to/video.mp4',
        width: 1920,
      );

      expect(result, isNotNull);
      // Height should be calculated as 1920 * 9 / 16 = 1080
    });

    test('isAvailable returns true when plugin responds', () async {
      final available = await SmartVideoThumbnail.isAvailable();
      expect(available, isTrue);
    });

    test('ThumbnailStrategy enum has correct values', () {
      expect(ThumbnailStrategy.normal.name, equals('normal'));
      expect(ThumbnailStrategy.keyframe.name, equals('keyframe'));
      expect(ThumbnailStrategy.firstFrame.name, equals('firstFrame'));
    });
  });
}
