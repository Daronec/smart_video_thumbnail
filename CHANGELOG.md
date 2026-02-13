# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-02-13

### 🎉 Added

- **Thumbnail Caching:** Automatic file-based caching system for generated thumbnails
  - Cache thumbnails to avoid regeneration
  - Persistent cache across app restarts
  - Cache management methods: `clearCache()`, `removeCacheForVideo()`, `getCacheStats()`
  - Optional `useCache` parameter (default: true)
- **Progress Callbacks:** Real-time progress updates during thumbnail generation
  - Optional `onProgress` callback parameter
  - Progress values from 0.0 to 1.0
  - Instant 100% progress for cache hits
- **Usage Examples:** Comprehensive code examples
  - ListView example with thumbnails
  - GridView example with caching
  - Cache management example with statistics

### 🔧 Changed

- **Library Size Optimization:** Reduced APK size by supporting ARM architectures only
  - Supports: arm64-v8a, armeabi-v7a
  - Excludes: x86, x86_64
  - Clear error message for unsupported architectures
- **API Enhancements:** Extended `getThumbnail` method
  - Added `useCache` parameter (default: true)
  - Added `onProgress` callback parameter (optional)
  - Backward compatible with v0.1.1

### 📦 New Dependencies

- `path_provider: ^2.1.0` - For cache directory access
- `crypto: ^3.0.3` - For cache key generation
- `uuid: ^4.0.0` - For progress request tracking

### 📚 Documentation

- Updated README with caching and progress examples
- Added comprehensive API documentation
- Added architecture support information

### ✅ Benefits

- ✅ Faster thumbnail loading with caching
- ✅ Better user experience with progress feedback
- ✅ Smaller APK size (ARM-only builds)
- ✅ Backward compatible with v0.1.1

## [0.1.1] - 2026-02-13

### 🎉 Changed

- **Simplified Installation:** Switched from GitHub Packages to JitPack for native library distribution
- **No Credentials Required:** Users no longer need GitHub Personal Access Tokens
- **Easier Setup:** Removed the need for `~/.gradle/gradle.properties` configuration

### 📦 Technical Changes

- Updated native library dependency from `com.smartmedia:smart-ffmpeg-android` to `com.github.Daronec:smart-ffmpeg-android`
- Changed repository from GitHub Packages to JitPack (`https://jitpack.io`)
- Native library now automatically downloads on first build

### 🔄 Migration Guide

If you're upgrading from v0.1.0:

1. **Remove GitHub credentials** from `~/.gradle/gradle.properties` (no longer needed)
2. **Clean build cache:**
   ```bash
   flutter clean
   cd example && flutter clean
   ```
3. **Update dependency:**
   ```yaml
   dependencies:
     smart_video_thumbnail: ^0.1.1
   ```
4. **Rebuild:**
   ```bash
   flutter pub get
   flutter build apk
   ```

The plugin will now automatically download the native library from JitPack on first build.

### ✅ Benefits

- ✅ No GitHub account or token required
- ✅ Simpler installation process
- ✅ Works out of the box after `flutter pub get`
- ✅ Standard Android library distribution method

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
