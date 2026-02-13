# 🎉 New Features

## 💾 Thumbnail Caching

Automatic file-based caching system for generated thumbnails:

- Cache thumbnails to avoid regeneration
- Persistent cache across app restarts
- Cache management: `clearCache()`, `removeCacheForVideo()`, `getCacheStats()`
- Optional `useCache` parameter (default: true)

## 📊 Progress Callbacks

Real-time progress updates during thumbnail generation:

- Optional `onProgress` callback parameter
- Progress values from 0.0 to 1.0
- Instant 100% progress for cache hits

## 📦 Library Size Optimization

Reduced APK size by supporting ARM architectures only:

- Supports: arm64-v8a, armeabi-v7a
- Excludes: x86, x86_64
- Clear error message for unsupported architectures

# 🔧 API Changes

## New Parameters

```dart
SmartVideoThumbnail.getThumbnail(
  videoPath: '/path/to/video.mp4',
  useCache: true,              // NEW: Enable/disable caching
  onProgress: (progress) {     // NEW: Progress callback
    print('${(progress * 100).toInt()}%');
  },
);
```

## New Methods

```dart
// Clear all cached thumbnails
await SmartVideoThumbnail.clearCache();

// Remove cache for specific video
await SmartVideoThumbnail.removeCacheForVideo('/path/to/video.mp4');

// Get cache statistics
final stats = await SmartVideoThumbnail.getCacheStats();
print('Cached: ${stats.fileCount} files, ${stats.formattedSize}');
```

# 📚 Examples

See the [README](https://github.com/Daronec/smart_video_thumbnail#readme) for complete examples:

- ListView with thumbnails
- GridView with caching
- Cache management
- Progress indicators

# ⚠️ Breaking Changes

None! This release is fully backward compatible with v0.1.1.

# 📦 Installation

```yaml
dependencies:
  smart_video_thumbnail: ^0.2.0
```

# 🔗 Links

- [pub.dev Package](https://pub.dev/packages/smart_video_thumbnail)
- [Documentation](https://github.com/Daronec/smart_video_thumbnail#readme)
- [Changelog](https://github.com/Daronec/smart_video_thumbnail/blob/main/CHANGELOG.md)
- [Example App](https://github.com/Daronec/smart_video_thumbnail/tree/main/example)
