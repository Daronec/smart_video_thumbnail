#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint smart_video_thumbnail.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'smart_video_thumbnail'
  s.version          = '0.4.0'
  s.summary          = 'High-performance Flutter plugin for extracting video thumbnails using native AVFoundation.'
  s.description      = <<-DESC
High-performance Flutter plugin for extracting video thumbnails using native AVFoundation engine. Supports all video formats (MP4, MOV, M4V, etc.) with native iOS performance.
                       DESC
  s.homepage         = 'https://github.com/Daronec/smart_video_thumbnail'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'PathCreator Team' => 'support@pathcreator.ru' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
