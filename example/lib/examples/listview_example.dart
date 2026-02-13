import 'package:flutter/material.dart';
import 'package:smart_video_thumbnail/smart_video_thumbnail.dart';
import 'dart:typed_data';

/// Example: Displaying video thumbnails in a ListView
///
/// This example demonstrates:
/// - Loading thumbnails for multiple videos
/// - Displaying thumbnails in a scrollable list
/// - Handling loading states and errors
class ListViewExample extends StatefulWidget {
  final List<String> videoPaths;

  const ListViewExample({Key? key, required this.videoPaths}) : super(key: key);

  @override
  State<ListViewExample> createState() => _ListViewExampleState();
}

class _ListViewExampleState extends State<ListViewExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ListView Example')),
      body: ListView.builder(
        itemCount: widget.videoPaths.length,
        itemBuilder: (context, index) {
          return VideoThumbnailListItem(
            videoPath: widget.videoPaths[index],
            index: index,
          );
        },
      ),
    );
  }
}

class VideoThumbnailListItem extends StatefulWidget {
  final String videoPath;
  final int index;

  const VideoThumbnailListItem({
    Key? key,
    required this.videoPath,
    required this.index,
  }) : super(key: key);

  @override
  State<VideoThumbnailListItem> createState() => _VideoThumbnailListItemState();
}

class _VideoThumbnailListItemState extends State<VideoThumbnailListItem> {
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
      final thumbnail = await SmartVideoThumbnail.getThumbnail(
        videoPath: widget.videoPath,
        timeMs: 1000,
        width: 160,
        height: 90,
        useCache: true, // Enable caching for better performance
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: SizedBox(width: 80, height: 45, child: _buildThumbnail()),
        title: Text('Video ${widget.index + 1}'),
        subtitle: Text(
          widget.videoPath.split('/').last,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      ),
    );
  }

  Widget _buildThumbnail() {
    if (_isLoading) {
      return Container(
        color: Colors.grey[300],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_error != null) {
      return Container(
        color: Colors.red[100],
        child: const Icon(Icons.error, color: Colors.red),
      );
    }

    if (_thumbnailData != null) {
      return Image.memory(
        _thumbnailData!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }

    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.video_library),
    );
  }
}
