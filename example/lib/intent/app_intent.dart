sealed class AppIntent {}

class PickVideoIntent extends AppIntent {}

class RemoveVideoIntent extends AppIntent {
  final String videoId;
  RemoveVideoIntent(this.videoId);
}

class ClearErrorIntent extends AppIntent {}
