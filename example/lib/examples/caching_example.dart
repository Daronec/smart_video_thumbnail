import 'package:flutter/material.dart';
import 'package:smart_video_thumbnail/smart_video_thumbnail.dart';

/// Example: Cache management and statistics
///
/// This example demonstrates:
/// - Viewing cache statistics
/// - Clearing entire cache
/// - Removing cache for specific videos
/// - Comparing cached vs non-cached performance
class CachingExample extends StatefulWidget {
  final String videoPath;

  const CachingExample({super.key, required this.videoPath});

  @override
  State<CachingExample> createState() => _CachingExampleState();
}

class _CachingExampleState extends State<CachingExample> {
  CacheStats? _cacheStats;
  bool _isLoadingStats = false;
  String _log = '';

  @override
  void initState() {
    super.initState();
    _loadCacheStats();
  }

  Future<void> _loadCacheStats() async {
    setState(() => _isLoadingStats = true);

    try {
      final stats = await SmartVideoThumbnail.getCacheStats();
      setState(() {
        _cacheStats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
      _addLog('Failed to load cache stats: $e');
    }
  }

  void _addLog(String message) {
    setState(() {
      _log = '${DateTime.now().toString().substring(11, 19)}: $message\n$_log';
    });
  }

  Future<void> _generateWithCache() async {
    _addLog('Generating thumbnail WITH cache...');
    final stopwatch = Stopwatch()..start();

    try {
      await SmartVideoThumbnail.getThumbnail(
        videoPath: widget.videoPath,
        timeMs: 1000,
        width: 320,
        height: 180,
        useCache: true,
      );

      stopwatch.stop();
      _addLog('✅ Generated in ${stopwatch.elapsedMilliseconds}ms (with cache)');
      await _loadCacheStats();
    } catch (e) {
      stopwatch.stop();
      _addLog('❌ Failed: $e');
    }
  }

  Future<void> _generateWithoutCache() async {
    _addLog('Generating thumbnail WITHOUT cache...');
    final stopwatch = Stopwatch()..start();

    try {
      await SmartVideoThumbnail.getThumbnail(
        videoPath: widget.videoPath,
        timeMs: 1000,
        width: 320,
        height: 180,
        useCache: false,
      );

      stopwatch.stop();
      _addLog('✅ Generated in ${stopwatch.elapsedMilliseconds}ms (no cache)');
    } catch (e) {
      stopwatch.stop();
      _addLog('❌ Failed: $e');
    }
  }

  Future<void> _clearCache() async {
    _addLog('Clearing entire cache...');

    try {
      await SmartVideoThumbnail.clearCache();
      _addLog('✅ Cache cleared successfully');
      await _loadCacheStats();
    } catch (e) {
      _addLog('❌ Failed to clear cache: $e');
    }
  }

  Future<void> _removeCacheForVideo() async {
    _addLog('Removing cache for current video...');

    try {
      await SmartVideoThumbnail.removeCacheForVideo(widget.videoPath);
      _addLog('✅ Cache removed for video');
      await _loadCacheStats();
    } catch (e) {
      _addLog('❌ Failed to remove cache: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Caching Example')),
      body: Column(
        children: [
          // Cache Statistics Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cache Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isLoadingStats)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadCacheStats,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_cacheStats != null) ...[
                    _buildStatRow('Files', '${_cacheStats!.fileCount}'),
                    _buildStatRow('Total Size', _cacheStats!.formattedSize),
                    _buildStatRow('Bytes', '${_cacheStats!.totalBytes}'),
                  ] else
                    const Text('No cache data available'),
                ],
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _generateWithCache,
                  icon: const Icon(Icons.cached),
                  label: const Text('Generate WITH Cache'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _generateWithoutCache,
                  icon: const Icon(Icons.block),
                  label: const Text('Generate WITHOUT Cache'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _removeCacheForVideo,
                  icon: const Icon(Icons.delete),
                  label: const Text('Remove Cache for Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _clearCache,
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Clear All Cache'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ),

          // Log Output
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Activity Log',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _log.isEmpty ? 'No activity yet' : _log,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
