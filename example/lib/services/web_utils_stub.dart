/// Stub implementation for non-web platforms
class Blob {
  Blob(List<dynamic> parts, String type);
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) {
    throw UnsupportedError('Blob URL is only supported on web');
  }
  
  static void revokeObjectUrl(String url) {
    throw UnsupportedError('Blob URL is only supported on web');
  }
}
