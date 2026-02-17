import 'dart:async';
import '../models/app_state.dart';
import '../models/video_item.dart';
import '../intent/app_intent.dart';
import '../services/video_service.dart';

/// Контроллер приложения, управляющий состоянием и бизнес-логикой.
/// 
/// Обрабатывает пользовательские намерения (intents) и обновляет состояние
/// приложения через reactive stream.
class AppController {
  final VideoService _videoService;
  final _stateController = StreamController<AppState>.broadcast();

  AppState _state = AppState();

  Stream<AppState> get stateStream => _stateController.stream;
  AppState get currentState => _state;

  AppController(this._videoService);

  /// Обрабатывает пользовательское намерение и выполняет соответствующее действие.
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
      _updateVideoById(videoId, (video) => video.copyWith(
        thumbnail: thumbnail,
        isLoading: false,
      ));
    } catch (e) {
      _updateVideoById(videoId, (video) => video.copyWith(isLoading: false));
      _updateState(_state.copyWith(error: 'Ошибка генерации обложки: $e'));
    }
  }

  /// Обновляет конкретное видео по ID, применяя функцию трансформации.
  void _updateVideoById(String videoId, VideoItem Function(VideoItem) transform) {
    final updatedVideos = _state.videos.map((video) {
      return video.id == videoId ? transform(video) : video;
    }).toList();
    _updateState(_state.copyWith(videos: updatedVideos));
  }

  void _removeVideo(String videoId) {
    final updatedVideos =
        _state.videos.where((video) => video.id != videoId).toList();

    _updateState(_state.copyWith(videos: updatedVideos));
  }

  void _clearError() {
    _updateState(_state.copyWith(error: null));
  }

  void _updateState(AppState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  /// Освобождает ресурсы контроллера.
  void dispose() {
    _stateController.close();
  }
}
