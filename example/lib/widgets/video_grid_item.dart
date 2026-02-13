import 'package:flutter/material.dart';
import '../models/video_item.dart';

class VideoGridItem extends StatelessWidget {
  final VideoItem video;
  final VoidCallback onRemove;

  const VideoGridItem({super.key, required this.video, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: video.isLoading
                ? Container(
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : video.thumbnail != null
                ? RawImage(image: video.thumbnail, fit: BoxFit.cover)
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.video_library,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: onRemove,
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Text(
                video.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
