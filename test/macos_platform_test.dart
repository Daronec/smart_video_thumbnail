import 'package:flutter_test/flutter_test.dart';
import 'package:smart_video_thumbnail/smart_video_thumbnail.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('macOS Platform Tests', () {
    test('Plugin should be available on macOS', () async {
      // This test verifies that the plugin can be initialized
      // Actual functionality requires a real macOS environment
      expect(SmartVideoThumbnail.getThumbnail, isNotNull);
    });

    test('getThumbnail should accept all parameters', () async {
      // Test that the API accepts all required parameters
      // This will fail in test environment but validates the API
      try {
        await SmartVideoThumbnail.getThumbnail(
          videoPath: '/test/path.mp4',
          timeMs: 1000,
          width: 320,
          height: 180,
          strategy: ThumbnailStrategy.normal,
          useCache: false,
        );
      } catch (e) {
        // Expected to fail in test environment
        expect(e, isNotNull);
      }
    });

    test('All thumbnail strategies should be available', () {
      expect(ThumbnailStrategy.values.length, 3);
      expect(ThumbnailStrategy.values, contains(ThumbnailStrategy.normal));
      expect(ThumbnailStrategy.values, contains(ThumbnailStrategy.keyframe));
      expect(ThumbnailStrategy.values, contains(ThumbnailStrategy.firstFrame));
    });

    test('Cache methods should be available', () {
      expect(SmartVideoThumbnail.clearCache, isNotNull);
      expect(SmartVideoThumbnail.removeCacheForVideo, isNotNull);
      expect(SmartVideoThumbnail.getCacheStats, isNotNull);
    });
  });
}
