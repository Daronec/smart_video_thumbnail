import 'dart:ui' as ui;

/// Модель элемента видео с метаданными и миниатюрой.
class VideoItem {
  final String id;
  final String path;
  final String name;
  final ui.Image? thumbnail;
  final bool isLoading;

  VideoItem({
    required this.id,
    required this.path,
    required this.name,
    this.thumbnail,
    this.isLoading = false,
  });

  /// Создает копию видео элемента с измененными полями.
  VideoItem copyWith({
    String? id,
    String? path,
    String? name,
    ui.Image? thumbnail,
    bool? isLoading,
  }) {
    return VideoItem(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      thumbnail: thumbnail ?? this.thumbnail,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
