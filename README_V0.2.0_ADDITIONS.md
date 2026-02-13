# v0.2.0 New Features - Add to README.md

## 💾 Caching (v0.2.0)

Thumbnails are automatically cached to improve performance:

```dart
// With caching (default)
final thumbnail = await SmartVideoThumbnail.getThumbnail(
  videoPath: '/path/to/video.mp4',
  timeMs: 1000,
  width: 320,
  height: 180,
  useCache: true, // Default
);

// Without caching
final thumbnail = await SmartVideoThumbnail.getThumbnail(
  videoPath: '/path/to/video.mp4',
  useCache: false,
);

// Clear all cache
await SmartVideoThumbnail.clearCache();

// Remove cache for specific video
await SmartVideoThumbnail.removeCacheForVideo('/path/to/video.mp4');

// Get cache statistics
final stats = await SmartVideoThumbnail.getCacheStats();
print('Cached files: ${stats.fileCount}');
print('Total size: ${stats.formattedSize}');
```

## 📊 Progress Callbacks (v0.2.0)

Get real-time progress updates during thumbnail generation:

```dart
final thumbnail = await SmartVideoThumbnail.getThumbnail(
  videoPath: '/path/to/video.mp4',
  timeMs: 1000,
  width: 320,
  height: 180,
  onProgress: (progress) {
    print('Progress: ${(progress * 100).toInt()}%');
    // Update UI with progress
  },
);
```

## 📱 Architecture Support (v0.2.0)

The plugin is optimized for ARM architectures to reduce APK size:

- ✅ **Supported:** arm64-v8a, armeabi-v7a (physical devices)
- ❌ **Not supported:** x86, x86_64 (emulators)

For x86 emulators, use ARM-based emulators or physical devices.

## 📚 Complete Examples

### ListView Example

```dart
ListView.builder(
  itemCount: videoPaths.length,
  itemBuilder: (context, index) {
    return FutureBuilder<Uint8List?>(
      future: SmartVideoThumbnail.getThumbnail(
        videoPath: videoPaths[index],
        width: 160,
        height: 90,
        useCache: true,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListTile(
            leading: Image.memory(snapshot.data!),
            title: Text('Video $index'),
          );
        }
        return ListTile(
          leading: CircularProgressIndicator(),
          title: Text('Loading...'),
        );
      },
    );
  },
);
```

### GridView with Caching

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    childAspectRatio: 16 / 9,
  ),
  itemCount: videoPaths.length,
  itemBuilder: (context, index) {
    return FutureBuilder<Uint8List?>(
      future: SmartVideoThumbnail.getThumbnail(
        videoPath: videoPaths[index],
        width: 320,
        height: 180,
        useCache: true, // Caching improves grid performance
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  },
);
```

### Progress Indicator

```dart
class ThumbnailWithProgress extends StatefulWidget {
  final String videoPath;

  @override
  State<ThumbnailWithProgress> createState() => _ThumbnailWithProgressState();
}

class _ThumbnailWithProgressState extends State<ThumbnailWithProgress> {
  double _progress = 0.0;
  Uint8List? _thumbnail;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final thumbnail = await SmartVideoThumbnail.getThumbnail(
      videoPath: widget.videoPath,
      width: 320,
      height: 180,
      onProgress: (progress) {
        setState(() => _progress = progress);
      },
    );

    setState(() => _thumbnail = thumbnail);
  }

  @override
  Widget build(BuildContext context) {
    if (_thumbnail != null) {
      return Image.memory(_thumbnail!);
    }

    return Column(
      children: [
        CircularProgressIndicator(value: _progress),
        Text('${(_progress * 100).toInt()}%'),
      ],
    );
  }
}
```

## 🔧 API Reference (v0.2.0)

### getThumbnail

```dart
static Future<Uint8List?> getThumbnail({
  required String videoPath,
  int timeMs = 1000,
  int? width,
  int? height,
  int size = 720,
  ThumbnailStrategy strategy = ThumbnailStrategy.normal,
  bool useCache = true,                          // NEW in v0.2.0
  void Function(double progress)? onProgress,    // NEW in v0.2.0
})
```

### Cache Management (NEW in v0.2.0)

```dart
// Clear all cached thumbnails
static Future<void> clearCache()

// Remove cache for specific video
static Future<void> removeCacheForVideo(String videoPath)

// Get cache statistics
static Future<CacheStats> getCacheStats()
```

### CacheStats (NEW in v0.2.0)

```dart
class CacheStats {
  final int fileCount;      // Number of cached files
  final int totalBytes;     // Total size in bytes
  final String formattedSize; // Human-readable size (e.g., "2.5 MB")
}
```
