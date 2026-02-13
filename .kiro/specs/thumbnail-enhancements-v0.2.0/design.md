# Design Document: Thumbnail Enhancements v0.2.0

## Overview

This design document outlines the implementation approach for version 0.2.0 of the smart_video_thumbnail Flutter plugin. The release introduces four major enhancements:

1. **Thumbnail Caching**: File-based cache system to persist generated thumbnails
2. **Progress Feedback**: Callback mechanism for real-time generation progress
3. **Library Size Optimization**: Architecture-specific builds to reduce APK size
4. **Enhanced Examples**: Comprehensive code examples for common use cases

The design maintains backward compatibility with v0.1.1 while adding optional features that developers can adopt incrementally.

## Architecture

### Current Architecture (v0.1.1)

```
┌─────────────────────────────────┐
│      Flutter App (Dart)         │
└────────────┬────────────────────┘
             │ MethodChannel (sync)
┌────────────▼────────────────────┐
│  SmartVideoThumbnailPlugin (Kt) │
└────────────┬────────────────────┘
             │ JNI
┌────────────▼────────────────────┐
│   SmartFfmpegBridge (C/C++)     │
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│  FFmpeg Libraries (v4.4.2)      │
└─────────────────────────────────┘
```

### Enhanced Architecture (v0.2.0)

```
┌─────────────────────────────────────────────┐
│           Flutter App (Dart)                │
└────────────┬────────────────────────────────┘
             │ MethodChannel
             │ + EventChannel (progress)
┌────────────▼────────────────────────────────┐
│     SmartVideoThumbnailPlugin (Kt)          │
│  ┌──────────────┐  ┌──────────────────┐    │
│  │ Cache Manager│  │ Progress Emitter │    │
│  └──────────────┘  └──────────────────┘    │
└────────────┬────────────────────────────────┘
             │ JNI
┌────────────▼────────────────────────────────┐
│        SmartFfmpegBridge (C/C++)            │
│        + Progress Callbacks                 │
└────────────┬────────────────────────────────┘
             │
┌────────────▼────────────────────────────────┐
│  FFmpeg Libraries (v4.4.2)                  │
│  arm64-v8a, armeabi-v7a only                │
└─────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. Thumbnail Cache Manager (Dart)

**Purpose**: Manages file-based caching of generated thumbnails.

**Location**: `lib/src/cache/thumbnail_cache.dart`

**Interface**:

```dart
class ThumbnailCache {
  /// Get cached thumbnail if available
  Future<Uint8List?> get(String cacheKey);

  /// Store thumbnail in cache
  Future<void> put(String cacheKey, Uint8List data);

  /// Clear all cached thumbnails
  Future<void> clear();

  /// Remove cached thumbnails for a specific video
  Future<void> removeByVideoPath(String videoPath);

  /// Generate cache key from parameters
  String generateKey(String videoPath, int timeMs, int width, int height, String strategy);

  /// Get cache directory
  Future<Directory> getCacheDirectory();
}
```

**Implementation Details**:

- Cache files stored in `<app_cache_dir>/smart_video_thumbnails/`
- Cache key format: `md5(videoPath)_${timeMs}_${width}x${height}_${strategy}.rgba`
- Uses `path_provider` package to get cache directory
- File format: raw RGBA8888 bytes
- No expiration policy in v0.2.0 (manual clearing only)

### 2. Enhanced SmartVideoThumbnail API (Dart)

**Purpose**: Extended public API with caching and progress support.

**Location**: `lib/smart_video_thumbnail.dart`

**New Methods**:

```dart
class SmartVideoThumbnail {
  /// Get thumbnail with optional caching and progress
  static Future<Uint8List?> getThumbnail({
    required String videoPath,
    int timeMs = 1000,
    int? width,
    int? height,
    int size = 720,
    ThumbnailStrategy strategy = ThumbnailStrategy.normal,
    bool useCache = true,  // NEW
    void Function(double progress)? onProgress,  // NEW
  });

  /// Clear all cached thumbnails
  static Future<void> clearCache();  // NEW

  /// Remove cached thumbnails for specific video
  static Future<void> removeCacheForVideo(String videoPath);  // NEW

  /// Get cache statistics
  static Future<CacheStats> getCacheStats();  // NEW
}

class CacheStats {
  final int fileCount;
  final int totalBytes;
  final String formattedSize;
}
```

### 3. Progress Event Channel (Dart/Kotlin)

**Purpose**: Stream progress updates from native code to Dart.

**Dart Side** (`lib/src/progress/progress_handler.dart`):

```dart
class ProgressHandler {
  static const EventChannel _progressChannel =
    EventChannel('smart_video_thumbnail/progress');

  Stream<double> getProgressStream(String requestId);
}
```

**Kotlin Side** (in `SmartVideoThumbnailPlugin.kt`):

```kotlin
class ProgressEventHandler : EventChannel.StreamHandler {
  private var eventSink: EventChannel.EventSink? = null

  fun sendProgress(requestId: String, progress: Double) {
    eventSink?.success(mapOf(
      "requestId" to requestId,
      "progress" to progress
    ))
  }
}
```

### 4. Native Progress Callbacks (C/C++)

**Purpose**: Report progress from FFmpeg decoding to Kotlin layer.

**Modifications to SmartFfmpegBridge**:

- Add progress callback parameter to `extractThumbnail`
- Invoke callback at key stages: file open (0.2), codec init (0.4), seek (0.6), decode (0.8), scale (0.9), complete (1.0)
- Thread-safe callback invocation via JNI

**Note**: This requires updating the smart-ffmpeg-android library to v1.1.0

## Data Models

### Cache Key Structure

```
Format: {videoPathHash}_{timeMs}_{width}x{height}_{strategy}.rgba

Example: a3f5b2c1d4e6f7a8_1000_320x180_normal.rgba

Components:
- videoPathHash: MD5 hash of video file path (first 16 chars)
- timeMs: Target time in milliseconds
- width: Thumbnail width in pixels
- height: Thumbnail height in pixels
- strategy: ThumbnailStrategy name (normal, keyframe, firstFrame)
```

### Cache File Format

```
Raw binary file containing RGBA8888 pixel data
- No header or metadata
- Size: width * height * 4 bytes
- Pixel order: left-to-right, top-to-bottom
- Color format: R, G, B, A (8 bits each)
```

### Progress Event Format

```dart
{
  "requestId": "uuid-v4-string",
  "progress": 0.0 to 1.0
}
```

## Correctness Properties

_A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees._

### Caching Properties

Property 1: Cache round-trip consistency
_For any_ video file and generation parameters, if a thumbnail is generated and cached, then requesting the same thumbnail again should return identical byte data without regenerating it, and this should remain true even after simulating an app restart (clearing memory but not disk).
**Validates: Requirements 1.1, 1.2, 1.8**

Property 2: Cache key determinism
_For any_ set of generation parameters (videoPath, timeMs, width, height, strategy), generating the cache key multiple times should always produce the same result.
**Validates: Requirements 1.3**

Property 3: Cache clear completeness
_For any_ cache state with one or more cached thumbnails, clearing the cache should result in zero cached entries remaining.
**Validates: Requirements 1.4**

Property 4: Selective cache removal
_For any_ cache containing thumbnails from multiple videos, removing the cache for one specific video should remove only that video's thumbnails while leaving all other cached thumbnails intact.
**Validates: Requirements 1.5**

Property 5: Cache failure graceful degradation
_For any_ thumbnail generation where cache storage fails, the plugin should still return the generated thumbnail data successfully.
**Validates: Requirements 1.6**

### Progress Properties

Property 6: Progress sequence validity
_For any_ thumbnail generation with a progress callback, all progress values should be in the range [0.0, 1.0], the first value should be 0.0, the last value on success should be 1.0, and values should be monotonically increasing.
**Validates: Requirements 2.2, 2.3, 2.4**

Property 7: Progress callback optional
_For any_ thumbnail generation without a progress callback, the generation should complete successfully and return valid thumbnail data.
**Validates: Requirements 2.5**

Property 8: Progress main thread invocation
_For any_ thumbnail generation with a progress callback, all callback invocations should occur on the main UI thread.
**Validates: Requirements 2.6**

Property 9: Progress incomplete on failure
_For any_ thumbnail generation that fails, if a progress callback was provided, the progress value should never reach 1.0.
**Validates: Requirements 2.7**

## Error Handling

### Cache Errors

**File System Errors**:

- If cache directory creation fails: Log warning, disable caching for session, continue normal operation
- If cache write fails: Log warning, return generated thumbnail, continue normal operation
- If cache read fails: Log warning, regenerate thumbnail, continue normal operation
- If cache clear fails: Log error, return error to caller

**Invalid Cache Data**:

- If cached file size doesn't match expected size (width _ height _ 4): Delete invalid cache file, regenerate thumbnail
- If cached file is corrupted: Delete corrupted file, regenerate thumbnail

### Progress Errors

**Callback Errors**:

- If progress callback throws exception: Log error, continue generation without further progress updates
- If EventChannel is not available: Disable progress reporting, continue generation

**Threading Errors**:

- If main thread is blocked: Queue progress updates, deliver when thread becomes available
- If progress event queue overflows: Drop intermediate progress values, always deliver 0.0 and 1.0

### Native Library Errors

**Architecture Mismatch**:

- If plugin is loaded on unsupported architecture: Return clear error message: "smart_video_thumbnail only supports arm64-v8a and armeabi-v7a architectures. Current architecture: {arch}"
- If FFmpeg library fails to load: Return error with troubleshooting steps

**FFmpeg Errors**:

- All existing error handling from v0.1.1 remains unchanged
- Progress callbacks should not interfere with error handling flow

## Testing Strategy

### Dual Testing Approach

This feature requires both unit tests and property-based tests for comprehensive coverage:

**Unit Tests**: Focus on specific examples, edge cases, and integration points

- Cache directory creation and permissions
- Cache file format validation
- Progress callback invocation order
- Error message formatting
- Architecture detection logic
- Example code compilation and execution

**Property Tests**: Focus on universal properties across all inputs

- Cache round-trip consistency with random parameters
- Cache key determinism with random inputs
- Progress value ranges and sequences
- Graceful degradation under random failure conditions

### Property-Based Testing Configuration

**Framework**: Use the `test` package with custom property test helpers (or `fast_check` if available for Dart)

**Configuration**:

- Minimum 100 iterations per property test
- Each test tagged with: `Feature: thumbnail-enhancements-v0.2.0, Property {number}: {property_text}`
- Random seed logging for reproducibility

**Test Data Generators**:

- Video paths: Random valid file paths, including edge cases (special characters, long paths, Unicode)
- Time values: Random values from 0 to 3600000 ms
- Dimensions: Random values from 1x1 to 4096x4096
- Strategies: Random selection from enum values
- Thumbnail data: Random RGBA8888 byte arrays of correct size

### Integration Testing

**Cache Integration**:

- Test cache behavior across multiple thumbnail generations
- Test cache persistence across simulated app restarts
- Test cache behavior with concurrent requests

**Progress Integration**:

- Test progress updates during actual FFmpeg operations
- Test progress callback with various thumbnail sizes and video formats
- Test progress behavior with slow/fast video decoding

**End-to-End Testing**:

- Test complete flow: generate → cache → retrieve → clear
- Test complete flow: generate with progress → display in UI
- Test error recovery: cache failure → fallback → retry

### Example Code Testing

All code examples in the README must be:

1. Syntactically valid Dart code
2. Compilable without errors
3. Executable in a test environment
4. Verified to produce expected output

Create automated tests that:

- Extract code examples from README
- Compile each example
- Execute examples in test environment
- Verify no runtime errors occur

## Implementation Notes

### Backward Compatibility

All changes are backward compatible with v0.1.1:

- `useCache` parameter defaults to `true` (opt-out)
- `onProgress` parameter is optional (null by default)
- Existing API calls work without modification
- Cache is transparent to existing code

### Performance Considerations

**Cache Performance**:

- Cache lookup: O(1) file system lookup by key
- Cache write: Asynchronous, doesn't block thumbnail return
- Cache clear: O(n) where n is number of cached files
- Expected cache hit rate: 70-90% for typical usage

**Progress Performance**:

- Progress callbacks add ~5-10ms overhead per generation
- EventChannel communication is asynchronous
- No blocking on main thread

**Memory Considerations**:

- Cache files stored on disk, not in memory
- Only active thumbnail data kept in memory
- Progress events are lightweight (16 bytes each)

### Dependencies

**New Dependencies**:

- `path_provider: ^2.1.0` - For cache directory access
- `crypto: ^3.0.3` - For MD5 hash generation

**Native Library Update**:

- Requires smart-ffmpeg-android v1.1.0 with progress callback support
- Must update dependency in android/build.gradle.kts

### Migration Guide

For developers upgrading from v0.1.1 to v0.2.0:

**No Breaking Changes**: All existing code continues to work

**Opt-in to New Features**:

```dart
// Enable caching (default behavior)
final thumbnail = await SmartVideoThumbnail.getThumbnail(
  videoPath: path,
  useCache: true,  // Optional, defaults to true
);

// Add progress feedback
final thumbnail = await SmartVideoThumbnail.getThumbnail(
  videoPath: path,
  onProgress: (progress) {
    print('Progress: ${(progress * 100).toInt()}%');
  },
);

// Clear cache when needed
await SmartVideoThumbnail.clearCache();
```

**Architecture Considerations**:

- If targeting x86/x86_64 emulators, use v0.1.1 or build custom native library
- For production apps (arm64-v8a/armeabi-v7a only), v0.2.0 is recommended
