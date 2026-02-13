import 'package:flutter_test/flutter_test.dart';
import 'package:smart_video_thumbnail/src/cache/thumbnail_cache.dart';
import 'dart:typed_data';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThumbnailCache', () {
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

    test('generateKey produces different keys for different parameters', () {
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
      final key3 = cache.generateKey(
        '/path/video.mp4',
        1000,
        640,
        360,
        'normal',
      );
      final key4 = cache.generateKey(
        '/path/video.mp4',
        1000,
        320,
        180,
        'keyframe',
      );

      expect(key1, isNot(equals(key2)));
      expect(key1, isNot(equals(key3)));
      expect(key1, isNot(equals(key4)));
    });

    test('cache round-trip stores and retrieves data', () async {
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final cacheKey = 'test_key.rgba';

      // Store data
      await cache.put(cacheKey, testData);

      // Retrieve data
      final retrieved = await cache.get(cacheKey);

      expect(retrieved, isNotNull);
      expect(retrieved, equals(testData));
    });

    test('cache returns null for non-existent key', () async {
      final retrieved = await cache.get('non_existent_key.rgba');

      expect(retrieved, isNull);
    });

    test('cache clear removes all entries', () async {
      final testData1 = Uint8List.fromList([1, 2, 3]);
      final testData2 = Uint8List.fromList([4, 5, 6]);

      await cache.put('key1.rgba', testData1);
      await cache.put('key2.rgba', testData2);

      // Verify data exists
      expect(await cache.get('key1.rgba'), isNotNull);
      expect(await cache.get('key2.rgba'), isNotNull);

      // Clear cache
      await cache.clear();

      // Verify data is gone
      expect(await cache.get('key1.rgba'), isNull);
      expect(await cache.get('key2.rgba'), isNull);
    });

    test('removeByVideoPath removes only matching entries', () async {
      final testData = Uint8List.fromList([1, 2, 3, 4]);

      // Create keys for two different videos
      final key1 = cache.generateKey(
        '/path/video1.mp4',
        1000,
        320,
        180,
        'normal',
      );
      final key2 = cache.generateKey(
        '/path/video1.mp4',
        2000,
        320,
        180,
        'normal',
      );
      final key3 = cache.generateKey(
        '/path/video2.mp4',
        1000,
        320,
        180,
        'normal',
      );

      // Store all
      await cache.put(key1, testData);
      await cache.put(key2, testData);
      await cache.put(key3, testData);

      // Remove video1 entries
      await cache.removeByVideoPath('/path/video1.mp4');

      // Verify video1 entries are gone, video2 remains
      expect(await cache.get(key1), isNull);
      expect(await cache.get(key2), isNull);
      expect(await cache.get(key3), isNotNull);
    });

    test('getCacheStats returns correct statistics', () async {
      final testData = Uint8List.fromList(List.generate(1024, (i) => i % 256));

      // Initially empty
      var stats = await cache.getCacheStats();
      expect(stats.fileCount, equals(0));
      expect(stats.totalBytes, equals(0));

      // Add some data
      await cache.put('test1.rgba', testData);
      await cache.put('test2.rgba', testData);

      // Check stats
      stats = await cache.getCacheStats();
      expect(stats.fileCount, equals(2));
      expect(stats.totalBytes, greaterThan(0));
      expect(stats.formattedSize, isNotEmpty);
    });

    test('cache handles write errors gracefully', () async {
      // This should not throw even if write fails
      final testData = Uint8List.fromList([1, 2, 3]);

      // Using invalid characters in filename might cause issues on some systems
      // but the cache should handle it gracefully
      await cache.put('', testData); // Empty key

      // Should complete without throwing
    });
  });
}
