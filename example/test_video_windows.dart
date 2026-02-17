import 'dart:io';
import 'package:smart_video_thumbnail/smart_video_thumbnail.dart';

void main() async {
  final videoPath = r'C:\Users\daron\Downloads\Man_Playing_Bass_preview_2189729.mp4';
  
  print('Testing video: $videoPath');
  print('File exists: ${File(videoPath).existsSync()}');
  
  if (File(videoPath).existsSync()) {
    final fileSize = File(videoPath).lengthSync();
    print('File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
  }
  
  print('\nAttempting to extract thumbnail...');
  
  final thumbnail = await SmartVideoThumbnail.getThumbnail(
    videoPath: videoPath,
    timeMs: 1000,
    width: 320,
    height: 180,
    strategy: ThumbnailStrategy.normal,
  );
  
  if (thumbnail != null) {
    print('✅ Success! Thumbnail size: ${thumbnail.length} bytes');
    print('Expected size: ${320 * 180 * 4} bytes');
  } else {
    print('❌ Failed to extract thumbnail');
  }
}
