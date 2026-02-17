#include "include/smart_video_thumbnail/smart_video_thumbnail_plugin.h"

#include <flutter/plugin_registrar_windows.h>

void SmartVideoThumbnailPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  smart_video_thumbnail::SmartVideoThumbnailPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
