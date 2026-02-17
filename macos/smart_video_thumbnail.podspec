#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint smart_video_thumbnail.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'smart_video_thumbnail'
  s.version          = '0.4.0'
  s.summary          = 'High-performance Flutter plugin for extracting video thumbnails using native FFmpeg engine.'
  s.description      = <<-DESC
High-performance Flutter plugin for extracting video thumbnails using native FFmpeg engine. Supports all video formats (MP4, AVI, MKV, FLV, etc.) with CPU-only decoding.
                       DESC
  s.homepage         = 'https://github.com/Daronec/smart_video_thumbnail'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'PathCreator Team' => 'support@pathcreator.ru' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
  
  # Note: FFmpeg functionality is provided by AVFoundation on macOS
  # No external FFmpeg dependency needed
end
