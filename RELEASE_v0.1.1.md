# 🎉 v0.1.1 - Simplified Installation (JitPack Migration)

This release makes installation much easier by switching from GitHub Packages to JitPack!

## 🚀 What's New

### Simplified Installation

- **No GitHub credentials required** - Users no longer need Personal Access Tokens
- **No gradle.properties setup** - Works out of the box after `flutter pub get`
- **Automatic library download** - Native FFmpeg library downloads from JitPack on first build

### Technical Changes

- Migrated native library from GitHub Packages to JitPack
- Updated dependency: `com.github.Daronec:smart-ffmpeg-android:1.0.4`
- Repository: `https://jitpack.io`

## 📦 Installation

```yaml
dependencies:
  smart_video_thumbnail: ^0.1.1
```

That's it! No additional setup required.

## 🔄 Upgrading from v0.1.0

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

## ✅ Benefits

- ✅ No GitHub account or token required
- ✅ Simpler installation process
- ✅ Works out of the box
- ✅ Standard Android library distribution

## 🔗 Links

- [pub.dev Package](https://pub.dev/packages/smart_video_thumbnail)
- [Native Library on JitPack](https://jitpack.io/#Daronec/smart-ffmpeg-android/1.0.4)
- [Documentation](https://github.com/Daronec/smart_video_thumbnail#readme)
- [Example App](https://github.com/Daronec/smart_video_thumbnail/tree/main/example)

## 📝 Full Changelog

See [CHANGELOG.md](https://github.com/Daronec/smart_video_thumbnail/blob/main/CHANGELOG.md) for complete details.
