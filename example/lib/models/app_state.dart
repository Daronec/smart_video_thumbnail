import 'video_item.dart';

class AppState {
  final List<VideoItem> videos;
  final bool isPickingVideo;
  final String? error;

  AppState({this.videos = const [], this.isPickingVideo = false, this.error});

  AppState copyWith({
    List<VideoItem>? videos,
    bool? isPickingVideo,
    String? error,
  }) {
    return AppState(
      videos: videos ?? this.videos,
      isPickingVideo: isPickingVideo ?? this.isPickingVideo,
      error: error,
    );
  }
}
