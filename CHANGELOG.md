# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-02-13

### 🎉 Initial Release

First public release of smart_video_thumbnail - a powerful Flutter plugin for video thumbnail generation.

### ✨ Features

- **Native FFmpeg Integration** - Uses FFmpeg 4.4.2 for reliable video decoding
- **Universal Format Support** - Works with MP4, AVI, MKV, FLV, WMV, and all FFmpeg-compatible formats
- **High Performance** - Optimized frame extraction (50-300ms per thumbnail)
- **Flexible API** - Configurable dimensions, time position, and seek strategies
- **RGBA8888 Output** - Standard pixel format for easy integration with Flutter widgets
- **Multiple Strategies** - Normal, keyframe, and firstFrame extraction modes
- **Robust Error Handling** - Comprehensive error messages and logging

### 📱 Platform Support

- ✅ **Android** - Full support for Android 8.0+ (API 26+)
  - Architectures: arm64-v8a, armeabi-v7a
  - Native FFmpeg library via [smart-ffmpeg-android](https://github.com/Daronec/smart-ffmpeg-android)
- ⏳ **iOS** - Coming in future releases

### 📦 What's Included

- Complete Flutter plugin with Dart API
- Native FFmpeg library integration (v4.4.2)
- Example app with grid layout demonstration
- Comprehensive documentation and usage examples
- GitHub Packages integration for native dependencies

### 🔧 Technical Details

- **FFmpeg Version:** 4.4.2
- **Supported Codecs:** H.264, H.265, MPEG-4, VP8, VP9, and more
- **Output Format:** RGBA8888 (4 bytes per pixel)
- **Library Size:** ~8MB (native libraries)
- **Min SDK:** Android 26 (Android 8.0)

### 📚 Documentation

- Full API reference in README.md
- Usage examples and code snippets
- Architecture documentation
- Performance benchmarks
- Debugging guide

### ⚠️ Known Limitations

- Android only (iOS support planned)
- Synchronous API (may block UI thread for large videos)
- Requires GitHub token for native library access during build

### 🔗 Links

- [GitHub Repository](https://github.com/Daronec/smart_video_thumbnail)
- [Native Library](https://github.com/Daronec/smart-ffmpeg-android)
- [Example App](https://github.com/Daronec/smart_video_thumbnail/tree/main/example)
- [Issue Tracker](https://github.com/Daronec/smart_video_thumbnail/issues)

[0.1.0]: https://github.com/Daronec/smart_video_thumbnail/releases/tag/v0.1.0
