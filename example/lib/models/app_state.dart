import 'video_item.dart';

/// Состояние приложения, содержащее список видео и флаги UI.
class AppState {
  final List<VideoItem> videos;
  final bool isPickingVideo;
  final String? error;

  AppState({this.videos = const [], this.isPickingVideo = false, this.error});

  /// Создает копию состояния с измененными полями.
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
