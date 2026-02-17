/// Базовый класс для всех намерений (intents) приложения.
/// 
/// Использует sealed class для exhaustive pattern matching.
sealed class AppIntent {}

/// Намерение выбрать видео файл.
class PickVideoIntent extends AppIntent {}

/// Намерение удалить видео по ID.
class RemoveVideoIntent extends AppIntent {
  final String videoId;
  RemoveVideoIntent(this.videoId);
}

/// Намерение очистить сообщение об ошибке.
class ClearErrorIntent extends AppIntent {}
