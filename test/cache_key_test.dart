import 'package:flutter_test/flutter_test.dart';
import 'package:smart_video_thumbnail/src/cache/thumbnail_cache.dart';

void main() {
  group('ThumbnailCache Key Generation', () {
    late ThumbnailCache cache;

    setUp(() {
      cache = ThumbnailCache();
    });

    test('generateKey produces consistent keys', () {
      final key1 = cache.generateKey(
        '/path/video.mp4',
        1000,
        320,
        180,
        'normal',
      );
      final key2 = cache.generateKey(
        '/path/video.mp4',
        1000,
        320,
        180,
        'normal',
      );

      expect(key1, equals(key2));
      expect(key1, contains('_1000_320x180_normal.rgba'));
    });

    test('generateKey produces different keys for different paths', () {
      final key1 = cache.generateKey(
        '/path/video1.mp4',
        1000,
        320,
        180,
        'normal',
      );
      final key2 = cache.generateKey(
        '/path/video2.mp4',
        1000,
        320,
        180,
        'normal',
      );

      expect(key1, isNot(equals(key2)));
    });

    test('generateKey produces different keys for different timeMs', () {
      final key1 = cache.generateKey(
        '/path/video.mp4',
        1000,
        320,
        180,
        'normal',
      );
      final key2 = cache.generateKey(
        '/path/video.mp4',
        2000,
        320,
        180,
        'normal',
      );

      expect(key1, isNot(equals(key2)));
      expect(key1, contains('_1000_'));
      expect(key2, contains('_2000_'));
    });

    test('generateKey produces different keys for different dimensions', () {
      final key1 = cache.generateKey(
        '/path/video.mp4',
        1000,
        320,
        180,
        'normal',
      );
      final key2 = cache.generateKey(
        '/path/video.mp4',
        1000,
        640,
        360,
        'normal',
      );

      expect(key1, isNot(equals(key2)));
      expect(key1, contains('320x180'));
      expect(key2, contains('640x360'));
    });

    test('generateKey produces different keys for different strategies', () {
      final key1 = cache.generateKey(
        '/path/video.mp4',
        1000,
        320,
        180,
        'normal',
      );
      final key2 = cache.generateKey(
        '/path/video.mp4',
        1000,
        320,
        180,
        'keyframe',
      );
      final key3 = cache.generateKey(
        '/path/video.mp4',
        1000,
        320,
        180,
        'firstFrame',
      );

      expect(key1, isNot(equals(key2)));
      expect(key1, isNot(equals(key3)));
      expect(key2, isNot(equals(key3)));

      expect(key1, contains('_normal.rgba'));
      expect(key2, contains('_keyframe.rgba'));
      expect(key3, contains('_firstFrame.rgba'));
    });

    test('generateKey handles special characters in path', () {
      final key1 = cache.generateKey(
        '/path/video with spaces.mp4',
        1000,
        320,
        180,
        'normal',
      );
      final key2 = cache.generateKey(
        '/path/видео.mp4',
        1000,
        320,
        180,
        'normal',
      );

      expect(key1, isNotEmpty);
      expect(key2, isNotEmpty);
      expect(key1, endsWith('.rgba'));
      expect(key2, endsWith('.rgba'));
    });

    test('generateKey format is correct', () {
      final key = cache.generateKey(
        '/path/video.mp4',
        1500,
        640,
        360,
        'keyframe',
      );

      // Format: {hash}_{timeMs}_{width}x{height}_{strategy}.rgba
      expect(key, matches(RegExp(r'^[a-f0-9]{16}_\d+_\d+x\d+_\w+\.rgba$')));
    });
  });
}
