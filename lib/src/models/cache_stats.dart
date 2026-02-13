/// Statistics about the thumbnail cache.
class CacheStats {
  /// Number of cached thumbnail files.
  final int fileCount;

  /// Total size of cached files in bytes.
  final int totalBytes;

  /// Human-readable formatted size string.
  final String formattedSize;

  const CacheStats({
    required this.fileCount,
    required this.totalBytes,
    required this.formattedSize,
  });

  @override
  String toString() {
    return 'CacheStats(fileCount: $fileCount, totalBytes: $totalBytes, formattedSize: $formattedSize)';
  }
}
