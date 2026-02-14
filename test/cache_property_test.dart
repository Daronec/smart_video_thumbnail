import 'package:flutter_test/flutter_test.dart';
import 'package:smart_video_thumbnail/src/cache/thumbnail_cache.dart';
import 'dart:typed_data';
import 'dart:math';

/// Property-Based Tests for ThumbnailCache
///
/// These tests validate universal properties that should hold
/// across all valid inputs, not just specific examples.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cache Properties', () {
    late ThumbnailCache cache;
    final random = Random(42); // Fixed seed for reproducibility

    setUp(() {
      cache = ThumbnailCache();
    });

    /// Property 1: Cache round-trip consistency
    ///
    /// **Validates: Requirements 1.1, 1.2, 1.8**
    ///
    /// For any video file and generation parameters, if a thumbnail is
    /// generated and cached, then requesting the same thumbnail again
    /// should return identical byte data.
    test('Property 1: Cache round-trip consistency', () async {
      const iterations = 20; // Reduced for unit tests

      for (int i = 0; i < iterations; i++) {
        // Generate random parameters
        final videoPath = '/test/video_${random.nextInt(1000)}.mp4';
        final timeMs = random.nextInt(10000);
        final width = 100 + random.nextInt(1000);
        final height = 100 + random.nextInt(1000);
        final strategy =
            ['normal', 'keyframe', 'firstFrame'][random.nextInt(3)];

        // Generate random thumbnail data
        final dataSize = width * height * 4;
        final originalData = Uint8List.fromList(
          List.generate(dataSize, (_) => random.nextInt(256)),
        );

        // Generate cache key
        final cacheKey =
            cache.generateKey(videoPath, timeMs, width, height, strategy);

        // Store in cache
        await cache.put(cacheKey, originalData);

        // Retrieve from cache
        final retrievedData = await cache.get(cacheKey);

        // Verify consistency
        expect(retrievedData, isNotNull,
            reason: 'Iteration $i: Cache should return data for stored key');
        expect(retrievedData!.length, equals(originalData.length),
            reason:
                'Iteration $i: Retrieved data length should match original');
        expect(retrievedData, equals(originalData),
            reason:
                'Iteration $i: Retrieved data should be identical to original');
      }
    });

    /// Property 2: Cache key determinism
    ///
    /// **Validates: Requirements 1.3**
    ///
    /// For any set of generation parameters, generating the cache key
    /// multiple times should always produce the same result.
    test('Property 2: Cache key determinism', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        // Generate random parameters
        final videoPath = '/test/video_${random.nextInt(1000)}.mp4';
        final timeMs = random.nextInt(10000);
        final width = 100 + random.nextInt(1000);
        final height = 100 + random.nextInt(1000);
        final strategy =
            ['normal', 'keyframe', 'firstFrame'][random.nextInt(3)];

        // Generate key multiple times
        final key1 =
            cache.generateKey(videoPath, timeMs, width, height, strategy);
        final key2 =
            cache.generateKey(videoPath, timeMs, width, height, strategy);
        final key3 =
            cache.generateKey(videoPath, timeMs, width, height, strategy);

        // Verify determinism
        expect(key1, equals(key2),
            reason:
                'Iteration $i: Keys should be identical for same parameters');
        expect(key2, equals(key3),
            reason:
                'Iteration $i: Keys should be identical across multiple calls');

        // Verify format
        expect(key1, matches(RegExp(r'^[a-f0-9]{16}_\d+_\d+x\d+_\w+\.rgba$')),
            reason: 'Iteration $i: Key should match expected format');
      }
    });

    /// Property 3: Cache key uniqueness
    ///
    /// **Validates: Requirements 1.3**
    ///
    /// Different parameters should produce different cache keys.
    test('Property 3: Cache key uniqueness', () {
      const iterations = 30;
      final seenKeys = <String>{};

      for (int i = 0; i < iterations; i++) {
        // Generate unique random parameters
        final videoPath = '/test/video_$i.mp4';
        final timeMs = i * 100;
        final width = 320 + i;
        final height = 180 + i;
        final strategy = ['normal', 'keyframe', 'firstFrame'][i % 3];

        final key =
            cache.generateKey(videoPath, timeMs, width, height, strategy);

        // Verify uniqueness
        expect(seenKeys.contains(key), isFalse,
            reason:
                'Iteration $i: Key should be unique for different parameters');

        seenKeys.add(key);
      }

      // Verify we generated expected number of unique keys
      expect(seenKeys.length, equals(iterations),
          reason: 'Should have generated $iterations unique keys');
    });

    /// Property 4: Cache handles edge cases
    ///
    /// **Validates: Requirements 1.6, 1.8**
    ///
    /// Cache should handle edge cases gracefully without throwing.
    test('Property 4: Cache handles edge cases', () async {
      final edgeCases = [
        // Empty data
        Uint8List(0),
        // Single byte
        Uint8List.fromList([255]),
        // Large data
        Uint8List.fromList(List.generate(1024 * 1024, (i) => i % 256)),
        // All zeros
        Uint8List(1000),
        // All ones
        Uint8List.fromList(List.filled(1000, 255)),
      ];

      for (int i = 0; i < edgeCases.length; i++) {
        final data = edgeCases[i];
        final key = 'edge_case_$i.rgba';

        // Should not throw
        await cache.put(key, data);
        final retrieved = await cache.get(key);

        expect(retrieved, isNotNull,
            reason: 'Edge case $i: Should retrieve stored data');
        expect(retrieved, equals(data),
            reason: 'Edge case $i: Retrieved data should match original');
      }
    });

    /// Property 5: Cache key collision resistance
    ///
    /// **Validates: Requirements 1.3**
    ///
    /// Similar but different parameters should produce different keys.
    test('Property 5: Cache key collision resistance', () {
      final basePath = '/test/video.mp4';
      final baseTime = 1000;
      final baseWidth = 320;
      final baseHeight = 180;
      final baseStrategy = 'normal';

      final baseKey = cache.generateKey(
          basePath, baseTime, baseWidth, baseHeight, baseStrategy);

      // Test variations
      final variations = [
        cache.generateKey(
            '$basePath.', baseTime, baseWidth, baseHeight, baseStrategy),
        cache.generateKey(
            basePath, baseTime + 1, baseWidth, baseHeight, baseStrategy),
        cache.generateKey(
            basePath, baseTime, baseWidth + 1, baseHeight, baseStrategy),
        cache.generateKey(
            basePath, baseTime, baseWidth, baseHeight + 1, baseStrategy),
        cache.generateKey(
            basePath, baseTime, baseWidth, baseHeight, 'keyframe'),
      ];

      for (int i = 0; i < variations.length; i++) {
        expect(variations[i], isNot(equals(baseKey)),
            reason: 'Variation $i: Should produce different key');
      }
    });
  });
}
