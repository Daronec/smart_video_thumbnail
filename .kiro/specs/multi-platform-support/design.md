# Design Document: Multi-Platform Support

## Overview

This design extends the smart_video_thumbnail Flutter plugin to support iOS, Windows, Linux, macOS, and Web platforms while maintaining the existing Android implementation. The design preserves API compatibility across all platforms while using platform-appropriate video processing libraries: AVFoundation for Apple platforms (iOS/macOS), FFmpeg for desktop platforms (Windows/Linux), and HTML5 Video API for Web.

The architecture follows Flutter's federated plugin pattern, with a common Dart API layer and platform-specific implementations. Each platform implementation handles video decoding, frame extraction, and pixel format conversion to produce consistent RGBA8888 output.

### Key Design Principles

1. **API Compatibility**: Identical Dart API across all platforms
2. **Platform Optimization**: Use native libraries best suited for each platform
3. **Consistent Output**: All platforms return RGBA8888 pixel data with identical dimensions
4. **Graceful Degradation**: Handle platform limitations transparently
5. **Minimal Dependencies**: Leverage platform-native capabilities where possible

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter App (Dart)                      │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│              smart_video_thumbnail.dart (API)               │
│  • getThumbnail()  • clearCache()  • getCacheStats()        │
└────────────────────────────┬────────────────────────────────┘
                             │ MethodChannel
              ┌──────────────┼──────────────┐
              │              │              │
    ┌─────────▼────┐  ┌──────▼──────┐  ┌──▼─────────┐
    │   Android    │  │     iOS     │  │   macOS    │
    │   (Kotlin)   │  │   (Swift)   │  │  (Swift)   │
    │   + FFmpeg   │  │ AVFoundation│  │AVFoundation│
    └──────────────┘  └─────────────┘  └────────────┘
              │              │              │
    ┌─────────▼────┐  ┌──────▼──────┐  ┌──▼─────────┐
    │   Windows    │  │    Linux    │  │    Web     │
    │    (C++)     │  │    (C++)    │  │ (Dart/JS)  │
    │   + FFmpeg   │  │  + FFmpeg   │  │ HTML5 API  │
    └──────────────┘  └─────────────┘  └────────────┘
```

### Plugin Structure

The plugin follows Flutter's federated plugin architecture:

```
smart_video_thumbnail/
├── lib/
│   ├── smart_video_thumbnail.dart          # Main API
│   └── src/
│       ├── cache/                          # Platform-agnostic caching
│       ├── models/                         # Data models
│       └── progress/                       # Progress handling
├── android/                                # Android implementation (existing)
├── ios/                                    # iOS implementation (new)
├── macos/                                  # macOS implementation (new)
├── windows/                                # Windows implementation (new)
├── linux/                                  # Linux implementation (new)
└── web/                                    # Web implementation (new)
```

### Platform Communication

All platforms use Flutter's MethodChannel for communication:

**Method**: `getThumbnail`
**Parameters**:

- `path`: String - Video file path or URL
- `timeMs`: int - Target time in milliseconds
- `width`: int - Output width in pixels
- `height`: int - Output height in pixels
- `size`: int - Alternative dimension specification
- `strategy`: String - Extraction strategy ("normal", "keyframe", "firstFrame")
- `requestId`: String? - Optional ID for progress tracking

**Returns**: `Uint8List?` - RGBA8888 pixel data or null on error

**Progress Channel**: `smart_video_thumbnail/progress`

- Event stream for progress updates
- Payload: `{ "requestId": String, "progress": double }`

## Components and Interfaces

### 1. Dart API Layer (Existing)

The existing Dart API remains unchanged, providing a consistent interface across all platforms.

**Key Components**:

- `SmartVideoThumbnail` class: Main API entry point
- `ThumbnailCache`: File-based caching system
- `ProgressHandler`: Progress callback management
- `ThumbnailStrategy` enum: Frame extraction strategies

### 2. iOS Implementation (Swift + AVFoundation)

**File**: `ios/Classes/SwiftSmartVideoThumbnailPlugin.swift`

**Core Components**:

```swift
class SwiftSmartVideoThumbnailPlugin: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar)
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult)
}

class ThumbnailGenerator {
    func generateThumbnail(
        videoPath: String,
        timeMs: Int64,
        width: Int,
        height: Int,
        strategy: String,
        progressCallback: ((Double) -> Void)?
    ) -> Data?
}

class AVAssetFrameExtractor {
    func extractFrame(
        from asset: AVAsset,
        at time: CMTime,
        size: CGSize
    ) -> CGImage?

    func convertToRGBA8888(image: CGImage, size: CGSize) -> Data?
}
```

**Implementation Strategy**:

1. Use `AVAsset` to load video files
2. Use `AVAssetImageGenerator` for frame extraction
3. Configure `requestedTimeToleranceBefore` and `requestedTimeToleranceAfter` based on strategy:
   - `normal`: Default tolerance (0.1s)
   - `keyframe`: Zero tolerance for exact keyframes
   - `firstFrame`: Extract at time zero
4. Convert `CGImage` to RGBA8888 using `CGContext`
5. Report progress at key stages: asset loading (0.2), seeking (0.5), extraction (0.8), conversion (1.0)

**Error Handling**:

- File not found: Return error code `FILE_NOT_FOUND`
- Unsupported format: Return error code `UNSUPPORTED_FORMAT`
- Extraction failure: Return error code `EXTRACTION_FAILED`

### 3. macOS Implementation (Swift + AVFoundation)

**File**: `macos/Classes/SmartVideoThumbnailPlugin.swift`

The macOS implementation is nearly identical to iOS, with minor adjustments:

- Use macOS-specific `FlutterPlugin` registration
- Handle file URLs with `file://` scheme
- Same AVFoundation APIs (AVAsset, AVAssetImageGenerator)
- Identical RGBA8888 conversion logic

### 4. Windows Implementation (C++ + FFmpeg)

**File**: `windows/smart_video_thumbnail_plugin.cpp`

**Core Components**:

```cpp
class SmartVideoThumbnailPlugin : public flutter::Plugin {
public:
    static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);
    void HandleMethodCall(const flutter::MethodCall<>& method_call,
                         std::unique_ptr<flutter::MethodResult<>> result);
};

class FFmpegThumbnailGenerator {
public:
    std::vector<uint8_t> GenerateThumbnail(
        const std::string& video_path,
        int64_t time_ms,
        int width,
        int height,
        const std::string& strategy,
        std::function<void(double)> progress_callback
    );

private:
    AVFormatContext* OpenVideo(const std::string& path);
    AVFrame* ExtractFrame(AVFormatContext* format_ctx, int64_t time_ms);
    std::vector<uint8_t> ConvertToRGBA8888(AVFrame* frame, int width, int height);
};
```

**Implementation Strategy**:

1. Use `avformat_open_input` to open video files
2. Use `avcodec_find_decoder` and `avcodec_open2` to initialize decoder
3. Use `av_seek_frame` to seek to target time
4. Use `avcodec_receive_frame` to decode frame
5. Use `sws_scale` to convert to RGBA8888 and resize
6. Report progress at key stages: file open (0.2), codec init (0.4), seeking (0.6), decoding (0.8), scaling (1.0)

**FFmpeg Integration**:

- Bundle FFmpeg shared libraries (avformat, avcodec, swscale, avutil) with plugin
- Use dynamic linking to load FFmpeg DLLs
- Provide clear error if FFmpeg libraries are missing

**Error Handling**:

- File not found: Return error code `FILE_NOT_FOUND`
- FFmpeg library missing: Return error code `FFMPEG_NOT_FOUND`
- Codec not found: Return error code `UNSUPPORTED_FORMAT`
- Extraction failure: Return error code `EXTRACTION_FAILED`

### 5. Linux Implementation (C++ + FFmpeg)

**File**: `linux/smart_video_thumbnail_plugin.cc`

The Linux implementation is nearly identical to Windows:

- Same FFmpeg-based approach
- Same C++ structure and APIs
- Different library loading mechanism (dlopen vs LoadLibrary)
- Attempt to use system FFmpeg libraries first, fall back to bundled libraries

**Library Detection**:

1. Check for system FFmpeg libraries (`libavformat.so`, `libavcodec.so`, etc.)
2. If found, use system libraries
3. If not found, use bundled libraries in plugin directory
4. Provide clear error message if neither is available

### 6. Web Implementation (Dart + HTML5 Video API)

**File**: `web/smart_video_thumbnail_web.dart`

**Core Components**:

```dart
class SmartVideoThumbnailWeb extends SmartVideoThumbnailPlatform {
  Future<Uint8List?> getThumbnail({
    required String videoPath,
    required int timeMs,
    required int width,
    required int height,
    required String strategy,
    String? requestId,
  });
}

class VideoFrameExtractor {
  Future<Uint8List?> extractFrame(
    html.VideoElement video,
    double timeSeconds,
    int width,
    int height,
  );

  Uint8List convertCanvasToRGBA8888(
    html.CanvasElement canvas,
    int width,
    int height,
  );
}
```

**Implementation Strategy**:

1. Create `VideoElement` and set `src` to video path/URL
2. Wait for `loadedmetadata` event
3. Set `currentTime` to target time in seconds
4. Wait for `seeked` event
5. Create `CanvasElement` with target dimensions
6. Draw video frame to canvas using `drawImage`
7. Get `ImageData` from canvas using `getImageData`
8. Convert from RGBA (canvas format) to RGBA8888 (plugin format)
9. Report progress at key stages: loading (0.3), seeking (0.6), rendering (0.9), complete (1.0)

**Strategy Handling**:

- `normal`: Standard seeking behavior
- `firstFrame`: Set currentTime to 0
- `keyframe`: Fall back to normal (browsers don't expose keyframe control)

**Error Handling**:

- Video load error: Return error code `VIDEO_LOAD_FAILED`
- Unsupported format: Return error code `UNSUPPORTED_FORMAT`
- Canvas rendering error: Return error code `RENDERING_FAILED`

**CORS Considerations**:

- Document that video URLs must be CORS-enabled
- Provide clear error message for CORS failures

## Data Models

### ThumbnailRequest

```dart
class ThumbnailRequest {
  final String videoPath;
  final int timeMs;
  final int width;
  final int height;
  final ThumbnailStrategy strategy;
  final String? requestId;

  ThumbnailRequest({
    required this.videoPath,
    required this.timeMs,
    required this.width,
    required this.height,
    required this.strategy,
    this.requestId,
  });

  Map<String, dynamic> toMap();
}
```

### ThumbnailResponse

```dart
class ThumbnailResponse {
  final Uint8List? data;
  final String? errorCode;
  final String? errorMessage;

  ThumbnailResponse({
    this.data,
    this.errorCode,
    this.errorMessage,
  });

  bool get isSuccess => data != null;
  bool get isError => errorCode != null;
}
```

### ProgressUpdate

```dart
class ProgressUpdate {
  final String requestId;
  final double progress; // 0.0 to 1.0

  ProgressUpdate({
    required this.requestId,
    required this.progress,
  });

  factory ProgressUpdate.fromMap(Map<String, dynamic> map);
}
```

### Platform-Specific Error Codes

```dart
class ThumbnailErrorCode {
  static const String fileNotFound = 'FILE_NOT_FOUND';
  static const String unsupportedFormat = 'UNSUPPORTED_FORMAT';
  static const String extractionFailed = 'EXTRACTION_FAILED';
  static const String ffmpegNotFound = 'FFMPEG_NOT_FOUND';
  static const String videoLoadFailed = 'VIDEO_LOAD_FAILED';
  static const String renderingFailed = 'RENDERING_FAILED';
  static const String unsupportedArchitecture = 'UNSUPPORTED_ARCHITECTURE';
  static const String badArgs = 'BAD_ARGS';
}
```

## Correctness Properties

A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.

### Property 1: Output Dimensions Consistency

_For any_ supported platform, video file, and valid dimensions (width, height), when getThumbnail is called, the returned data SHALL have exactly width × height × 4 bytes (RGBA8888 format).

**Validates: Requirements 1.3, 2.3, 3.3, 4.3, 5.3**

### Property 2: Cross-Platform Dimension Agreement

_For any_ valid video file and dimensions, when getThumbnail is called with identical parameters on different platforms, all platforms SHALL return data with identical byte length (width × height × 4).

**Validates: Requirements 6.2**

### Property 3: Strategy Support

_For any_ supported platform and valid video file, when getThumbnail is called with each supported strategy (normal, keyframe, firstFrame), the call SHALL complete successfully and return valid RGBA8888 data.

**Validates: Requirements 1.5, 2.5, 3.5, 4.5, 5.5**

### Property 4: Invalid Path Error Handling

_For any_ supported platform and invalid file path (non-existent, malformed, or inaccessible), when getThumbnail is called, the method SHALL return null without crashing.

**Validates: Requirements 1.4, 6.4, 9.1**

### Property 5: Unsupported Format Error Handling

_For any_ supported platform and unsupported video format, when getThumbnail is called, the method SHALL return null and log an appropriate error.

**Validates: Requirements 5.8, 9.2**

### Property 6: Invalid Time Position Error Handling

_For any_ supported platform and valid video file, when getThumbnail is called with a time position beyond the video duration, the method SHALL return null.

**Validates: Requirements 9.5**

### Property 7: Cache Key Consistency

_For any_ set of parameters (videoPath, timeMs, width, height, strategy), the cache key generation algorithm SHALL produce identical keys across all platforms.

**Validates: Requirements 7.2**

### Property 8: Cache Storage and Retrieval

_For any_ valid video file and parameters, when getThumbnail is called with useCache=true, then calling getThumbnail again with identical parameters SHALL return the cached result (verifiable by checking cache stats or timing).

**Validates: Requirements 7.1, 7.3**

### Property 9: Cache Clearing

_For any_ cache state with N cached thumbnails, when clearCache is called, getCacheStats SHALL report 0 cached files and 0 bytes.

**Validates: Requirements 7.4**

### Property 10: Video-Specific Cache Removal

_For any_ cache state with thumbnails from multiple videos, when removeCacheForVideo is called for one video, getCacheStats SHALL show reduced file count equal to the number of thumbnails for that video only.

**Validates: Requirements 7.5**

### Property 11: Cache Stats Accuracy

_For any_ sequence of cache operations (put, get, remove), getCacheStats SHALL return accurate counts and sizes reflecting the actual cached data.

**Validates: Requirements 7.6**

### Property 12: Cache Failure Resilience

_For any_ cache operation failure (disk full, permission denied), the Plugin SHALL continue to function and generate thumbnails without crashing.

**Validates: Requirements 7.7**

### Property 13: Progress Callback Range

_For any_ thumbnail generation with a progress callback, all progress values reported SHALL be in the range [0.0, 1.0].

**Validates: Requirements 8.1**

### Property 14: Progress Callback Completion

_For any_ thumbnail generation with a progress callback, the final progress value reported SHALL be 1.0 when generation completes successfully.

**Validates: Requirements 8.3**

### Property 15: Cached Thumbnail Progress

_For any_ cached thumbnail request with a progress callback, the callback SHALL be invoked with 1.0 immediately.

**Validates: Requirements 8.4**

### Property 16: Progress Callback Frequency

_For any_ non-cached thumbnail generation with a progress callback, the callback SHALL be invoked at least 3 times.

**Validates: Requirements 8.5**

### Property 17: Progress Callback Exception Handling

_For any_ thumbnail generation where the progress callback throws an exception, the generation SHALL complete successfully and return valid data.

**Validates: Requirements 8.6**

### Property 18: API Method Signature Consistency

_For any_ supported platform, the getThumbnail method SHALL accept the same parameter types (String videoPath, int timeMs, int width, int height, int size, ThumbnailStrategy strategy, bool useCache, Function? onProgress).

**Validates: Requirements 6.1, 6.3**

### Property 19: Error Return Consistency

_For any_ error condition on any platform, getThumbnail SHALL return null (not throw an exception).

**Validates: Requirements 6.4**

## Error Handling

### Error Code Standardization

All platforms use standardized error codes for consistent error handling:

| Error Code                 | Description                                     | Platforms      |
| -------------------------- | ----------------------------------------------- | -------------- |
| `FILE_NOT_FOUND`           | Video file does not exist or is inaccessible    | All            |
| `UNSUPPORTED_FORMAT`       | Video format not supported on this platform     | All            |
| `EXTRACTION_FAILED`        | Frame extraction failed for unknown reason      | All            |
| `FFMPEG_NOT_FOUND`         | FFmpeg libraries not found (Windows/Linux only) | Windows, Linux |
| `VIDEO_LOAD_FAILED`        | Video failed to load (Web only)                 | Web            |
| `RENDERING_FAILED`         | Canvas rendering failed (Web only)              | Web            |
| `UNSUPPORTED_ARCHITECTURE` | CPU architecture not supported                  | Android        |
| `BAD_ARGS`                 | Invalid arguments provided                      | All            |

### Error Handling Strategy

1. **Graceful Degradation**: All errors return null instead of throwing exceptions
2. **Detailed Logging**: All errors are logged with platform-specific context
3. **User-Friendly Messages**: Error messages provide actionable information
4. **Resource Cleanup**: All platform implementations clean up resources on error

### Platform-Specific Error Scenarios

**iOS/macOS (AVFoundation)**:

- Asset loading failures → `FILE_NOT_FOUND` or `UNSUPPORTED_FORMAT`
- Image generator failures → `EXTRACTION_FAILED`
- Memory allocation failures → `EXTRACTION_FAILED`

**Windows/Linux (FFmpeg)**:

- Library not found → `FFMPEG_NOT_FOUND` with installation instructions
- Format context open failure → `FILE_NOT_FOUND`
- Codec not found → `UNSUPPORTED_FORMAT`
- Decode errors → `EXTRACTION_FAILED`

**Web (HTML5)**:

- Video load error → `VIDEO_LOAD_FAILED`
- CORS errors → `VIDEO_LOAD_FAILED` with CORS explanation
- Unsupported format → `UNSUPPORTED_FORMAT`
- Canvas errors → `RENDERING_FAILED`

## Testing Strategy

### Dual Testing Approach

The plugin requires both unit tests and property-based tests for comprehensive coverage:

**Unit Tests**: Verify specific examples, edge cases, and error conditions

- Specific video files with known characteristics
- Boundary conditions (time=0, time=duration)
- Error scenarios (missing files, invalid formats)
- Platform-specific integration points

**Property Tests**: Verify universal properties across all inputs

- Random video files, dimensions, and time positions
- Cache behavior with random parameters
- Progress callback behavior with random inputs
- Cross-platform consistency with random parameters

### Property-Based Testing Configuration

- **Library**: Use `fast_check` (JavaScript/TypeScript) or equivalent for each platform
- **Iterations**: Minimum 100 iterations per property test
- **Tagging**: Each property test references its design document property
- **Tag Format**: `Feature: multi-platform-support, Property N: [property text]`

### Test Organization

```
test/
├── unit/
│   ├── api_test.dart                    # Dart API unit tests
│   ├── cache_test.dart                  # Cache unit tests
│   ├── progress_test.dart               # Progress callback unit tests
│   └── platform_specific/
│       ├── ios_test.dart                # iOS-specific tests
│       ├── android_test.dart            # Android-specific tests
│       ├── windows_test.dart            # Windows-specific tests
│       ├── linux_test.dart              # Linux-specific tests
│       ├── macos_test.dart              # macOS-specific tests
│       └── web_test.dart                # Web-specific tests
├── property/
│   ├── dimensions_property_test.dart    # Properties 1, 2
│   ├── strategy_property_test.dart      # Property 3
│   ├── error_handling_property_test.dart # Properties 4, 5, 6, 19
│   ├── cache_property_test.dart         # Properties 7-12
│   └── progress_property_test.dart      # Properties 13-17
└── integration/
    ├── cross_platform_test.dart         # Cross-platform consistency tests
    └── performance_test.dart            # Performance benchmarks
```

### Platform-Specific Test Requirements

**iOS/macOS Tests**:

- Test with common AVFoundation formats (MP4, MOV, M4V)
- Test keyframe strategy with H.264 videos
- Test firstFrame strategy
- Verify RGBA8888 conversion accuracy

**Windows/Linux Tests**:

- Test FFmpeg library detection
- Test with various FFmpeg formats (MP4, AVI, MKV, FLV)
- Test all three strategies
- Verify RGBA8888 conversion accuracy
- Test error handling when FFmpeg is missing

**Web Tests**:

- Test with browser-supported formats (MP4, WebM)
- Test CORS scenarios
- Test keyframe fallback to normal strategy
- Verify canvas-based RGBA8888 conversion

**Android Tests** (existing):

- Continue existing test coverage
- Add cross-platform consistency tests

### Test Data

**Test Videos**:

- Short videos (5-10 seconds) in multiple formats
- Videos with different resolutions (480p, 720p, 1080p)
- Videos with different codecs (H.264, H.265, VP9)
- Corrupted or invalid video files for error testing

**Test Parameters**:

- Dimensions: 320x180, 640x360, 1280x720, 1920x1080
- Time positions: 0ms, 1000ms, 5000ms, end of video
- Strategies: normal, keyframe, firstFrame
- Cache enabled/disabled

### Continuous Integration

- Run unit tests on all platforms in CI
- Run property tests with reduced iterations (50) in CI
- Run full property tests (100+ iterations) nightly
- Test on multiple OS versions (iOS 13+, Android 8+, Windows 10+, macOS 10.15+)
- Test in multiple browsers (Chrome, Firefox, Safari) for Web

### Performance Benchmarks

Track performance metrics across platforms:

- Thumbnail generation time (50th, 95th, 99th percentile)
- Memory usage during generation
- Cache hit/miss ratios
- Progress callback overhead

Target: <500ms for 720p thumbnail extraction on modern devices
