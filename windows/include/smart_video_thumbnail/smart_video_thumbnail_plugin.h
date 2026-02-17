#ifndef FLUTTER_PLUGIN_SMART_VIDEO_THUMBNAIL_PLUGIN_H_
#define FLUTTER_PLUGIN_SMART_VIDEO_THUMBNAIL_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter_plugin_registrar.h>

#include <memory>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void SmartVideoThumbnailPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

namespace smart_video_thumbnail {

class SmartVideoThumbnailPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  SmartVideoThumbnailPlugin();

  virtual ~SmartVideoThumbnailPlugin();

  // Disallow copy and assign.
  SmartVideoThumbnailPlugin(const SmartVideoThumbnailPlugin&) = delete;
  SmartVideoThumbnailPlugin& operator=(const SmartVideoThumbnailPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace smart_video_thumbnail

#endif  // FLUTTER_PLUGIN_SMART_VIDEO_THUMBNAIL_PLUGIN_H_
