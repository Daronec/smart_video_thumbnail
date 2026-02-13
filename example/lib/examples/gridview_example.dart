import 'package:flutter/material.dart';
import 'package:smart_video_thumbnail/smart_video_thumbnail.dart';
import 'dart:typed_data';

/// Example: Displaying video thumbnails in a GridView
///
/// This example demonstrates:
/// - Responsive grid layout
/// - Thumbnail caching for better performance
/// - Tap to view full-screen thumbnail
class GridViewExample extends StatefulWidget {
  final List<String> videoPaths;

  const GridViewExample({Key? key, required this.videoPaths}) : super(key: key);

  @override
  State<GridViewExample> createState() => _GridViewExampleState();
}

class _GridViewExampleState extends State<GridViewExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GridView Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Cache',
            onPressed: _clearCache,
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 16 / 9,
        ),
        itemCount: widget.videoPaths.length,
        itemBuilder: (context, index) {
          return VideoThumbnailGridItem(
            videoPath: widget.videoPaths[index],
            index: index,
          );
        },
      ),
    );
  }

  Future<void> _clearCache() async {
    try {
      await SmartVideoThumbnail.clearCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared successfully')),
        );
        // Reload the grid
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to clear cache: $e')));
      }
    }
  }
}

class VideoThumbnailGridItem extends StatefulWidget {
  final String videoPath;
  final int index;

  const VideoThumbnailGridItem({
    Key? key,
    required this.videoPath,
    required this.index,
  }) : super(key: key);

  @override
  State<VideoThumbnailGridItem> createState() => _VideoThumbnailGridItemState();
}

class _VideoThumbnailGridItemState extends State<VideoThumbnailGridItem> {
  Uint8List? _thumbnailData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use caching for better performance in grids
      final thumbnail = await SmartVideoThumbnail.getThumbnail(
        videoPath: widget.videoPath,
        timeMs: 1000,
        width: 320,
        height: 180,
        useCache: true,
      );

      if (mounted) {
        setState(() {
          _thumbnailData = thumbnail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _thumbnailData != null ? _showFullScreen : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildThumbnail(),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_error != null) {
      return Container(
        color: Colors.red[100],
        child: const Center(child: Icon(Icons.error, color: Colors.red)),
      );
    }

    if (_thumbnailData != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            _thumbnailData!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${widget.index + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
      );
    }

    return const Center(child: Icon(Icons.video_library, color: Colors.grey));
  }

  void _showFullScreen() {
    if (_thumbnailData == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text('Video ${widget.index + 1}')),
          body: Center(
            child: InteractiveViewer(child: Image.memory(_thumbnailData!)),
          ),
        ),
      ),
    );
  }
}
