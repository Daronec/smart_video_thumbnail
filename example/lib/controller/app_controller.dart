import 'dart:async';
import '../models/app_state.dart';
import '../models/video_item.dart';
import '../intent/app_intent.dart';
import '../services/video_service.dart';

class AppController {
  final VideoService _videoService;
  final _stateController = StreamController<AppState>.broadcast();

  AppState _state = AppState();

  Stream<AppState> get stateStream => _stateController.stream;
  AppState get currentState => _state;

  AppController(this._videoService);

  void handleIntent(AppIntent intent) {
    switch (intent) {
      case PickVideoIntent():
        _pickVideo();
      case RemoveVideoIntent():
        _removeVideo(intent.videoId);
      case ClearErrorIntent():
        _clearError();
    }
  }

  Future<void> _pickVideo() async {
    _updateState(_state.copyWith(isPickingVideo: true, error: null));

    try {
      final videoPath = await _videoService.pickVideo();

      if (videoPath != null) {
        final videoId = DateTime.now().millisecondsSinceEpoch.toString();
        final videoName = videoPath.split('/').last;

        final newVideo = VideoItem(
          id: videoId,
          path: videoPath,
          name: videoName,
          isLoading: true,
        );

        final updatedVideos = [..._state.videos, newVideo];
        _updateState(
          _state.copyWith(videos: updatedVideos, isPickingVideo: false),
        );

        _generateThumbnail(videoId, videoPath);
      } else {
        _updateState(_state.copyWith(isPickingVideo: false));
      }
    } catch (e) {
      _updateState(
        _state.copyWith(
          isPickingVideo: false,
          error: 'Ошибка выбора видео: $e',
        ),
      );
    }
  }

  Future<void> _generateThumbnail(String videoId, String videoPath) async {
    try {
      final thumbnail = await _videoService.generateThumbnail(videoPath);

      final updatedVideos = _state.videos.map((video) {
        if (video.id == videoId) {
          return video.copyWith(thumbnail: thumbnail, isLoading: false);
        }
        return video;
      }).toList();

      _updateState(_state.copyWith(videos: updatedVideos));
    } catch (e) {
      final updatedVideos = _state.videos.map((video) {
        if (video.id == videoId) {
          return video.copyWith(isLoading: false);
        }
        return video;
      }).toList();

      _updateState(
        _state.copyWith(
          videos: updatedVideos,
          error: 'Ошибка генерации обложки: $e',
        ),
      );
    }
  }

  void _removeVideo(String videoId) {
    final updatedVideos = _state.videos
        .where((video) => video.id != videoId)
        .toList();

    _updateState(_state.copyWith(videos: updatedVideos));
  }

  void _clearError() {
    _updateState(_state.copyWith(error: null));
  }

  void _updateState(AppState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  void dispose() {
    _stateController.close();
  }
}
