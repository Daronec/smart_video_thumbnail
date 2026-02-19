# smart_video_thumbnail

[![pub package](https://img.shields.io/pub/v/smart_video_thumbnail.svg)](https://pub.dev/packages/smart_video_thumbnail)
[![Platform](https://img.shields.io/badge/platform-android-green.svg)](https://pub.dev/packages/smart_video_thumbnail)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A powerful Flutter plugin for generating video thumbnails using native FFmpeg engine. Fast, reliable, and supports all major video formats.

---

## 📸 Screenshot

![Example App](https://raw.githubusercontent.com/Daronec/smart_video_thumbnail/main/assets/screenshot.jpg)

_Example app showing video thumbnails in a grid layout_

---

## ✨ Features

- 🎬 **Native FFmpeg** - Uses CPU-only decoding for maximum compatibility
- 📦 **All Formats** - Supports MP4, AVI, MKV, FLV, WMV and other FFmpeg formats
- 🚀 **Fast** - Optimized frame extraction with minimal overhead
- 💾 **Caching** - Automatic thumbnail caching for better performance (v0.2.0)
- 📊 **Progress** - Real-time progress callbacks during generation (v0.2.0)
- 🎯 **Flexible** - Multiple seek strategies (normal, keyframe, firstFrame)
- 🔧 **Independent** - No dependency on MediaMetadataRetriever or system APIs
- 💪 **Reliable** - Works with corrupted or unusual video files
- 📱 **Optimized** - ARM-only builds for smaller APK size (v0.2.0)

## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  smart_video_thumbnail: ^0.2.0
```

Then run:

```bash
flutter pub get
```

### Android Setup

No additional setup required! The plugin automatically downloads the native FFmpeg library from JitPack.

> **Note:** The first build may take a bit longer as Gradle downloads the native library (~8MB).

### iOS Setup

No additional setup required! The plugin uses native AVFoundation framework for video processing.

> **Note:** Make sure your app has the necessary permissions in Info.plist:
>
> ```xml
> <key>NSPhotoLibraryUsageDescription</key>
> <string>This app needs access to your photo library to select videos.</string>
> ```
>
> **Implementation Note:** iOS version uses AVFoundation instead of FFmpeg for better system integration and smaller binary size.

### macOS Setup

No additional setup required! The plugin uses native AVFoundation framework for video processing.

> **Note:** Make sure your app has the necessary entitlements for file access:
>
> - `com.apple.security.files.user-selected.read-only`
> - `com.apple.security.files.user-selected.read-write`
>
> These are required for accessing video files selected by the user.
>
> **Implementation Note:** macOS version uses AVFoundation instead of FFmpeg for better system integration and smaller binary size.

---

## 🚀 Usage

### Basic Example

```dart
import 'package:smart_video_thumbnail/smart_video_thumbnail.dart';

// Extract thumbnail at 1 second
final thumbnail = await SmartVideoThumbnail.getThumbnail(
  videoPath: '/path/to/video.mp4',
  timeMs: 1000,
  width: 320,
  height: 180,
);

if (thumbnail != null) {
  // thumbnail is Uint8List with RGBA8888 data
  // Size: width * height * 4 bytes
  print('Thumbnail extracted: ${thumbnail.length} bytes');
}
```

### Display with Image Widget

```dart
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';

Future<ui.Image?> createImageFromRGBA(
  Uint8List rgba,
  int width,
  int height,
) async {
  final completer = Completer<ui.Image>();

  ui.decodeImageFromPixels(
    rgba,
    width,
    height,
    ui.PixelFormat.rgba8888,
    (ui.Image image) {
      completer.complete(image);
    },
  );

  return completer.future;
}

// In your widget
final thumbnail = await SmartVideoThumbnail.getThumbnail(
  videoPath: videoPath,
  width: 320,
  height: 180,
);

if (thumbnail != null) {
  final image = await createImageFromRGBA(thumbnail, 320, 180);
  return RawImage(image: image);
}
```

### Extraction Strategies

```dart
// Normal seek (default)
final thumbnail1 = await SmartVideoThumbnail.getThumbnail(
  videoPath: videoPath,
  strategy: ThumbnailStrategy.normal,
);

// Keyframe-focused seek (for AVI/FLV)
final thumbnail2 = await SmartVideoThumbnail.getThumbnail(
  videoPath: videoPath,
  strategy: ThumbnailStrategy.keyframe,
);

// First available frame (fastest)
final thumbnail3 = await SmartVideoThumbnail.getThumbnail(
  videoPath: videoPath,
  strategy: ThumbnailStrategy.firstFrame,
);
```

---

## 📖 API Reference

### `getThumbnail`

Extracts a thumbnail from a video file.

**Parameters:**

| Parameter   | Type                | Required | Default       | Description                       |
| ----------- | ------------------- | -------- | ------------- | --------------------------------- |
| `videoPath` | `String`            | ✅ Yes   | -             | Path to the video file            |
| `timeMs`    | `int`               | ❌ No    | `1000`        | Target position in milliseconds   |
| `width`     | `int`               | ❌ No    | `size`        | Thumbnail width in pixels         |
| `height`    | `int`               | ❌ No    | `size * 9/16` | Thumbnail height in pixels        |
| `size`      | `int`               | ❌ No    | `720`         | Alternative way to set dimensions |
| `strategy`  | `ThumbnailStrategy` | ❌ No    | `normal`      | Frame extraction strategy         |

**Returns:** `Future<Uint8List?>` - RGBA8888 pixel data or `null` on error

### Data Format

The plugin returns `Uint8List` with **RGBA8888** format:

- 4 bytes per pixel (Red, Green, Blue, Alpha)
- Data size: `width * height * 4` bytes
- Pixel order: left to right, top to bottom

---

## 📱 Platform Support

| Platform | Status       | Architectures          | Backend          |
| -------- | ------------ | ---------------------- | ---------------- |
| Android  | ✅ Supported | arm64-v8a, armeabi-v7a | FFmpeg 4.4.2     |
| iOS      | ✅ Supported | arm64, armv7           | AVFoundation     |
| macOS    | ✅ Supported | x86_64, arm64          | AVFoundation     |
| Windows  | ✅ Supported | x64                    | Media Foundation |
| Web      | ✅ Supported | All browsers           | HTML5 Video      |

### Supported Video Formats by Platform

#### 🤖 Android (FFmpeg)

**Supports all FFmpeg-compatible formats:**

- ✅ **Container formats:** MP4, AVI, MKV, FLV, WMV, MOV, 3GP, WebM, OGG, and more
- ✅ **Video codecs:** H.264, H.265/HEVC, MPEG-4, VP8, VP9, Theora, WMV, DivX, Xvid, and more
- ✅ **Audio codecs:** AAC, MP3, Vorbis, Opus, WMA, FLAC, and more

**Note:** FFmpeg provides the most comprehensive format support across all platforms.

#### 🍎 iOS (AVFoundation)

**Supports system-native formats:**

- ✅ **Container formats:** MP4, MOV, M4V, 3GP
- ✅ **Video codecs:** H.264, H.265/HEVC, MPEG-4
- ✅ **Audio codecs:** AAC, MP3, Apple Lossless

**Limitations:**

- ❌ AVI, MKV, FLV, WMV - not supported (requires FFmpeg)
- ⚠️ Smaller binary size (~2MB vs ~8MB on Android)
- ⚠️ Better battery efficiency due to hardware acceleration

#### 🖥️ macOS (AVFoundation)

**Supports system-native formats:**

- ✅ **Container formats:** MP4, MOV, M4V, 3GP
- ✅ **Video codecs:** H.264, H.265/HEVC, MPEG-4, ProRes
- ✅ **Audio codecs:** AAC, MP3, Apple Lossless, FLAC

**Limitations:**

- ❌ AVI, MKV, FLV, WMV - not supported (requires FFmpeg)
- ⚠️ Smaller binary size compared to FFmpeg
- ⚠️ Better performance due to hardware acceleration

#### 🪟 Windows (Media Foundation)

**Supports Windows-native formats:**

- ✅ **Container formats:** MP4, AVI, WMV, ASF
- ✅ **Video codecs:** H.264, H.265/HEVC, MPEG-4, WMV
- ✅ **Audio codecs:** AAC, MP3, WMA

**Limitations:**

- ❌ MKV, FLV - limited support
- ⚠️ Format support depends on installed codecs

#### 🌐 Web (HTML5 Video)

**Supports browser-native formats only:**

- ✅ **MP4** (H.264/AAC) - Best compatibility, supported by all modern browsers
- ✅ **WebM** (VP8/VP9/Vorbis/Opus) - Good support in Chrome, Firefox, Edge
- ✅ **Ogg** (Theora/Vorbis) - Supported in Firefox, Chrome

**Limitations:**

- ❌ **AVI, WMV, FLV, MKV** - NOT supported (no browser codecs)
- ⚠️ Format support varies by browser
- ⚠️ Requires video file to be loaded into memory
- 💡 **Recommendation:** Use MP4 (H.264) for maximum compatibility

**Browser Compatibility:**

| Format | Chrome | Firefox | Safari | Edge |
| ------ | ------ | ------- | ------ | ---- |
| MP4    | ✅     | ✅      | ✅     | ✅   |
| WebM   | ✅     | ✅      | ❌     | ✅   |
| Ogg    | ✅     | ✅      | ❌     | ❌   |
| AVI    | ❌     | ❌      | ❌     | ❌   |
| WMV    | ❌     | ❌      | ❌     | ❌   |

### Format Recommendations

**For maximum cross-platform compatibility:**

- 🎯 **Primary:** MP4 (H.264 video + AAC audio)
- 🎯 **Alternative:** WebM (VP9 video + Opus audio) for web

**For Android-only apps:**

- 🎯 Use any format - FFmpeg supports everything

**For iOS/macOS apps:**

- 🎯 Stick to MP4, MOV, M4V formats
- 🎯 Use H.264 or H.265 codecs

**For web apps:**

- 🎯 **Must use:** MP4 (H.264) - only reliable option
- ⚠️ Convert AVI/WMV/FLV to MP4 before using

---

## 🔧 Working with Unsupported Formats

If you need to work with formats not natively supported on your platform (e.g., AVI on iOS, WMV on Web), you have several options:

### Option 1: Convert to MP4 (Recommended)

**Using FFmpeg CLI:**

```bash
ffmpeg -i input.avi -c:v libx264 -c:a aac output.mp4
```

**Using ffmpeg_kit_flutter in your app:**

```dart
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

Future<String?> convertToMp4(String inputPath) async {
  final outputPath = inputPath.replaceAll(RegExp(r'\.\w+$'), '.mp4');
  await FFmpegKit.execute('-i "$inputPath" -c:v libx264 -c:a aac "$outputPath"');
  return outputPath;
}

// Then use the converted file
final mp4Path = await convertToMp4('/path/to/video.avi');
if (mp4Path != null) {
  final thumbnail = await SmartVideoThumbnail.getThumbnail(
    videoPath: mp4Path,
  );
}
```

### Option 2: Future FFmpeg Extension (Coming Soon)

We're planning an optional `smart_video_thumbnail_ffmpeg` package that will add support for all formats on iOS/macOS:

```yaml
dependencies:
  smart_video_thumbnail: ^0.4.0
  smart_video_thumbnail_ffmpeg: ^1.0.0 # Optional, adds +20MB
```

**Note:** This will increase app size by ~20-30 MB but provide full format support.

### Option 3: Server-Side Conversion (For Web)

For web applications, consider converting videos on your server before sending to clients.

📚 **For detailed solutions and recommendations, see [UNSUPPORTED_FORMATS_SOLUTION.md](UNSUPPORTED_FORMATS_SOLUTION.md)**

---

## 📋 Requirements

### Android

- **minSdk:** 26 (Android 8.0+)
- **targetSdk:** 34
- **NDK:** r21 or higher
- **CMake:** 3.18.1 or higher
- **FFmpeg:** Included in plugin (v4.4.2)

### iOS

- **Deployment Target:** iOS 12.0 or higher
- **Xcode:** 12.0 or higher
- **Video Processing:** Native AVFoundation framework

### macOS

- **Deployment Target:** 10.14 or higher
- **Xcode:** 12.0 or higher
- **Video Processing:** Native AVFoundation framework

---

## 🏗️ Architecture

The plugin consists of three layers:

```
┌─────────────────────────────────┐
│      Flutter App (Dart)         │
└────────────┬────────────────────┘
             │ MethodChannel
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
│  • libavformat • libavcodec     │
│  • libswscale  • libavutil      │
└─────────────────────────────────┘
```

**Layers:**

1. **Dart API** - Flutter interface (`smart_video_thumbnail.dart`)
2. **Kotlin Bridge** - JNI bridge (`SmartVideoThumbnailPlugin.kt`)
3. **Native Library** - FFmpeg decoding ([smart-ffmpeg-android](https://github.com/Daronec/smart-ffmpeg-android))

---

## ⚡ Performance

Typical frame extraction times:

| Format | Codec  | Time      |
| ------ | ------ | --------- |
| MP4    | H.264  | 50-150ms  |
| AVI    | MPEG-4 | 100-200ms |
| MKV    | H.265  | 150-300ms |
| FLV    | -      | 100-250ms |

**Performance factors:**

- Video format and codec
- Output image size
- Frame position in video
- Device performance

---

## 🐛 Debugging

Enable Android logging:

```bash
adb logcat | grep -E "SmartVideoThumbnail|SmartFfmpegBridge"
```

Example logs:

```
I/SmartVideoThumbnail: 🎬 getThumbnail: path=/path/to/video.mp4, targetMs=1000, size=320x180
I/SmartFfmpegBridge: Extracting thumbnail from: /path/to/video.mp4 at 1000 ms
I/SmartFfmpegBridge: Successfully extracted thumbnail: 230400 bytes
I/SmartVideoThumbnail: ✅ getThumbnail: Thumbnail extracted successfully (230400 bytes)
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Native Library:** [smart-ffmpeg-android](https://github.com/Daronec/smart-ffmpeg-android)
- **FFmpeg:** [ffmpeg.org](https://ffmpeg.org/)
- **Issues:** [GitHub Issues](https://github.com/Daronec/smart_video_thumbnail/issues)

---

## 👨‍💻 Author

**PathCreator Team**

If you find this plugin helpful, please give it a ⭐ on [GitHub](https://github.com/Daronec/smart_video_thumbnail)!
