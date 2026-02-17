#include "include/smart_video_thumbnail/smart_video_thumbnail_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For Windows Media Foundation
#include <mfapi.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <mferror.h>
#include <propvarutil.h>
#include <shlwapi.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <vector>

#pragma comment(lib, "mfplat.lib")
#pragma comment(lib, "mfreadwrite.lib")
#pragma comment(lib, "mfuuid.lib")
#pragma comment(lib, "shlwapi.lib")

namespace smart_video_thumbnail {

// Static helper functions
namespace {

// Initialize COM and Media Foundation
bool InitializeMediaFoundation() {
    HRESULT hr = CoInitializeEx(NULL, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    if (FAILED(hr) && hr != RPC_E_CHANGED_MODE) {
        return false;
    }

    hr = MFStartup(MF_VERSION);
    if (FAILED(hr)) {
        return false;
    }

    return true;
}

// Shutdown Media Foundation
void ShutdownMediaFoundation() {
    MFShutdown();
    CoUninitialize();
}

// Helper function to log messages
void LogMessage(const std::string& message) {
    OutputDebugStringA(message.c_str());
    OutputDebugStringA("\n");
}

// Convert NV12 to RGBA8888
void ConvertNV12ToRGBA(const BYTE* nv12Data, BYTE* rgbaData, UINT32 width, UINT32 height, LONG stride) {
    // If stride is 0, assume no padding
    if (stride == 0) stride = width;
    
    const BYTE* yPlane = nv12Data;
    const BYTE* uvPlane = nv12Data + (stride * height);
    
    for (UINT32 y = 0; y < height; y++) {
        for (UINT32 x = 0; x < width; x++) {
            int yIndex = y * stride + x;
            int uvIndex = (y / 2) * stride + (x & ~1);
            
            int Y = yPlane[yIndex];
            int U = uvPlane[uvIndex] - 128;
            int V = uvPlane[uvIndex + 1] - 128;
            
            // YUV to RGB conversion
            int R = Y + (int)(1.370705 * V);
            int G = Y - (int)(0.337633 * U) - (int)(0.698001 * V);
            int B = Y + (int)(1.732446 * U);
            
            // Clamp values
            R = (R < 0) ? 0 : ((R > 255) ? 255 : R);
            G = (G < 0) ? 0 : ((G > 255) ? 255 : G);
            B = (B < 0) ? 0 : ((B > 255) ? 255 : B);
            
            int rgbaIndex = (y * width + x) * 4;
            rgbaData[rgbaIndex + 0] = (BYTE)R;
            rgbaData[rgbaIndex + 1] = (BYTE)G;
            rgbaData[rgbaIndex + 2] = (BYTE)B;
            rgbaData[rgbaIndex + 3] = 255;
        }
    }
}

// Convert YUY2 to RGBA8888
void ConvertYUY2ToRGBA(const BYTE* yuy2Data, BYTE* rgbaData, UINT32 width, UINT32 height, LONG stride) {
    // If stride is 0, assume no padding
    if (stride == 0) stride = width * 2;
    
    for (UINT32 y = 0; y < height; y++) {
        for (UINT32 x = 0; x < width; x += 2) {
            int yuy2Index = y * stride + (x * 2);
            
            int Y0 = yuy2Data[yuy2Index + 0];
            int U = yuy2Data[yuy2Index + 1] - 128;
            int Y1 = yuy2Data[yuy2Index + 2];
            int V = yuy2Data[yuy2Index + 3] - 128;
            
            // Process first pixel
            int R0 = Y0 + (int)(1.370705 * V);
            int G0 = Y0 - (int)(0.337633 * U) - (int)(0.698001 * V);
            int B0 = Y0 + (int)(1.732446 * U);
            
            R0 = (R0 < 0) ? 0 : ((R0 > 255) ? 255 : R0);
            G0 = (G0 < 0) ? 0 : ((G0 > 255) ? 255 : G0);
            B0 = (B0 < 0) ? 0 : ((B0 > 255) ? 255 : B0);
            
            int rgbaIndex0 = (y * width + x) * 4;
            rgbaData[rgbaIndex0 + 0] = (BYTE)R0;
            rgbaData[rgbaIndex0 + 1] = (BYTE)G0;
            rgbaData[rgbaIndex0 + 2] = (BYTE)B0;
            rgbaData[rgbaIndex0 + 3] = 255;
            
            // Process second pixel
            int R1 = Y1 + (int)(1.370705 * V);
            int G1 = Y1 - (int)(0.337633 * U) - (int)(0.698001 * V);
            int B1 = Y1 + (int)(1.732446 * U);
            
            R1 = (R1 < 0) ? 0 : ((R1 > 255) ? 255 : R1);
            G1 = (G1 < 0) ? 0 : ((G1 > 255) ? 255 : G1);
            B1 = (B1 < 0) ? 0 : ((B1 > 255) ? 255 : B1);
            
            int rgbaIndex1 = (y * width + x + 1) * 4;
            rgbaData[rgbaIndex1 + 0] = (BYTE)R1;
            rgbaData[rgbaIndex1 + 1] = (BYTE)G1;
            rgbaData[rgbaIndex1 + 2] = (BYTE)B1;
            rgbaData[rgbaIndex1 + 3] = 255;
        }
    }
}

// Convert RGB32 to RGBA8888
void ConvertRGB32ToRGBA(const BYTE* rgb32Data, BYTE* rgbaData, UINT32 width, UINT32 height, LONG stride) {
    // If stride is 0, assume no padding
    if (stride == 0) stride = width * 4;
    
    for (UINT32 y = 0; y < height; y++) {
        for (UINT32 x = 0; x < width; x++) {
            int srcIndex = y * stride + (x * 4);
            int dstIndex = (y * width + x) * 4;
            
            // RGB32 format: B G R X -> R G B A
            rgbaData[dstIndex + 0] = rgb32Data[srcIndex + 2]; // R
            rgbaData[dstIndex + 1] = rgb32Data[srcIndex + 1]; // G
            rgbaData[dstIndex + 2] = rgb32Data[srcIndex + 0]; // B
            rgbaData[dstIndex + 3] = 255;                      // A
        }
    }
}

// Extract thumbnail from video
std::vector<uint8_t> ExtractThumbnail(
    const std::wstring& video_path,
    int64_t time_ms,
    int width,
    int height) {
    
    std::vector<uint8_t> result;

    // Log parameters
    {
        std::ostringstream log;
        log << "🎬 SmartVideoThumbnail Windows: getThumbnail called";
        LogMessage(log.str());
        
        log.str("");
        log << "   timeMs: " << time_ms;
        LogMessage(log.str());
        
        log.str("");
        log << "   size: " << width << "x" << height;
        LogMessage(log.str());
    }

    // Check if file exists
    DWORD fileAttr = GetFileAttributesW(video_path.c_str());
    if (fileAttr == INVALID_FILE_ATTRIBUTES) {
        LogMessage("❌ SmartVideoThumbnail Windows: File not found or inaccessible");
        return result;
    }
    
    LogMessage("✓ File exists and is accessible");

    // Initialize Media Foundation
    if (!InitializeMediaFoundation()) {
        LogMessage("❌ SmartVideoThumbnail Windows: Failed to initialize Media Foundation");
        return result;
    }
    
    LogMessage("✓ Media Foundation initialized");

    IMFSourceReader* source_reader = nullptr;
    HRESULT hr = MFCreateSourceReaderFromURL(
        video_path.c_str(),
        NULL,
        &source_reader
    );

    if (FAILED(hr) || !source_reader) {
        {
            std::ostringstream log;
            log << "❌ SmartVideoThumbnail Windows: Failed to create source reader, HRESULT: 0x" 
                << std::hex << hr;
            LogMessage(log.str());
        }
        ShutdownMediaFoundation();
        return result;
    }
    
    LogMessage("✓ Source reader created");

    // Configure the source reader to get uncompressed video frames
    // Try to get any uncompressed format that Media Foundation supports
    IMFMediaType* media_type = nullptr;
    hr = MFCreateMediaType(&media_type);
    if (SUCCEEDED(hr)) {
        hr = media_type->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Video);
        if (SUCCEEDED(hr)) {
            // Try RGB32 first
            hr = media_type->SetGUID(MF_MT_SUBTYPE, MFVideoFormat_RGB32);
        }
        if (SUCCEEDED(hr)) {
            hr = source_reader->SetCurrentMediaType(
                (DWORD)MF_SOURCE_READER_FIRST_VIDEO_STREAM,
                NULL,
                media_type
            );
        }
        
        // If RGB32 failed, try NV12 (more commonly supported)
        if (FAILED(hr)) {
            LogMessage("⚠️ RGB32 not supported, trying NV12...");
            hr = media_type->SetGUID(MF_MT_SUBTYPE, MFVideoFormat_NV12);
            if (SUCCEEDED(hr)) {
                hr = source_reader->SetCurrentMediaType(
                    (DWORD)MF_SOURCE_READER_FIRST_VIDEO_STREAM,
                    NULL,
                    media_type
                );
            }
        }
        
        // If NV12 failed, try YUY2
        if (FAILED(hr)) {
            LogMessage("⚠️ NV12 not supported, trying YUY2...");
            hr = media_type->SetGUID(MF_MT_SUBTYPE, MFVideoFormat_YUY2);
            if (SUCCEEDED(hr)) {
                hr = source_reader->SetCurrentMediaType(
                    (DWORD)MF_SOURCE_READER_FIRST_VIDEO_STREAM,
                    NULL,
                    media_type
                );
            }
        }
        
        media_type->Release();
    }

    if (FAILED(hr)) {
        {
            std::ostringstream log;
            log << "❌ SmartVideoThumbnail Windows: Failed to set media type, HRESULT: 0x" 
                << std::hex << hr;
            LogMessage(log.str());
        }
        source_reader->Release();
        ShutdownMediaFoundation();
        return result;
    }
    
    LogMessage("✓ Media type configured");

    // Seek to the desired time
    if (time_ms > 0) {
        PROPVARIANT var;
        PropVariantInit(&var);
        var.vt = VT_I8;
        var.hVal.QuadPart = time_ms * 10000; // Convert to 100-nanosecond units

        hr = source_reader->SetCurrentPosition(GUID_NULL, var);
        PropVariantClear(&var);
        
        if (SUCCEEDED(hr)) {
            LogMessage("✓ Seeked to target time");
        } else {
            {
                std::ostringstream log;
                log << "⚠️ SmartVideoThumbnail Windows: Seek failed, HRESULT: 0x" 
                    << std::hex << hr << ", will try first frame";
                LogMessage(log.str());
            }
            // Continue anyway - will get first available frame
        }
    }

    // Read the frame
    IMFSample* sample = nullptr;
    DWORD stream_flags = 0;
    
    LogMessage("→ Reading frame...");
    
    hr = source_reader->ReadSample(
        (DWORD)MF_SOURCE_READER_FIRST_VIDEO_STREAM,
        0,
        NULL,
        &stream_flags,
        NULL,
        &sample
    );

    {
        std::ostringstream log;
        log << "   ReadSample HRESULT: 0x" << std::hex << hr;
        LogMessage(log.str());
        
        log.str("");
        log << "   Stream flags: 0x" << std::hex << stream_flags;
        LogMessage(log.str());
    }

    if (SUCCEEDED(hr) && sample) {
        LogMessage("✓ Frame read successfully");
        
        IMFMediaBuffer* buffer = nullptr;
        hr = sample->ConvertToContiguousBuffer(&buffer);

        if (SUCCEEDED(hr) && buffer) {
            // Try to get IMF2DBuffer interface for proper stride handling
            IMF2DBuffer* buffer2D = nullptr;
            BYTE* data = nullptr;
            LONG stride = 0;
            DWORD data_length = 0;
            
            hr = buffer->QueryInterface(IID_PPV_ARGS(&buffer2D));
            
            if (SUCCEEDED(hr) && buffer2D) {
                // Use 2D buffer for proper stride
                hr = buffer2D->Lock2D(&data, &stride);
                
                if (SUCCEEDED(hr)) {
                    {
                        std::ostringstream log;
                        log << "✓ Using 2D buffer, stride: " << stride;
                        LogMessage(log.str());
                    }
                }
            } else {
                // Fallback to regular buffer
                hr = buffer->Lock(&data, NULL, &data_length);
                stride = 0; // Will calculate from width
                LogMessage("✓ Using 1D buffer (no stride info)");
            }
            
            if (SUCCEEDED(hr)) {
                // Get actual frame dimensions
                IMFMediaType* current_type = nullptr;
                hr = source_reader->GetCurrentMediaType(
                    (DWORD)MF_SOURCE_READER_FIRST_VIDEO_STREAM,
                    &current_type
                );

                if (SUCCEEDED(hr) && current_type) {
                    UINT32 frame_width = 0, frame_height = 0;
                    MFGetAttributeSize(current_type, MF_MT_FRAME_SIZE, &frame_width, &frame_height);

                    {
                        std::ostringstream log;
                        log << "✓ Frame dimensions: " << frame_width << "x" << frame_height;
                        LogMessage(log.str());
                    }

                    // Get the subtype to determine format
                    GUID subtype = GUID_NULL;
                    current_type->GetGUID(MF_MT_SUBTYPE, &subtype);

                    // Allocate result buffer
                    result.resize(frame_width * frame_height * 4);
                    
                    if (subtype == MFVideoFormat_RGB32) {
                        // RGB32 format: B G R X -> R G B A
                        LogMessage("→ Converting RGB32 to RGBA");
                        ConvertRGB32ToRGBA(data, result.data(), frame_width, frame_height, stride);
                    } else if (subtype == MFVideoFormat_NV12) {
                        LogMessage("→ Converting NV12 to RGBA");
                        ConvertNV12ToRGBA(data, result.data(), frame_width, frame_height, stride);
                    } else if (subtype == MFVideoFormat_YUY2) {
                        LogMessage("→ Converting YUY2 to RGBA");
                        ConvertYUY2ToRGBA(data, result.data(), frame_width, frame_height, stride);
                    } else {
                        LogMessage("❌ Unsupported video format");
                        result.clear();
                    }

                    current_type->Release();
                }

                // Unlock buffer
                if (buffer2D) {
                    buffer2D->Unlock2D();
                    buffer2D->Release();
                } else {
                    buffer->Unlock();
                }
            }

            buffer->Release();
        }

        sample->Release();
    } else {
        LogMessage("❌ SmartVideoThumbnail Windows: Failed to read frame");
    }

    source_reader->Release();
    ShutdownMediaFoundation();

    if (!result.empty()) {
        {
            std::ostringstream log;
            log << "✅ SmartVideoThumbnail Windows: Thumbnail extracted successfully (" << result.size() << " bytes)";
            LogMessage(log.str());
        }
    }

    return result;
}

}  // namespace

// Plugin implementation
SmartVideoThumbnailPlugin::SmartVideoThumbnailPlugin() {}

SmartVideoThumbnailPlugin::~SmartVideoThumbnailPlugin() {}

void SmartVideoThumbnailPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "smart_video_thumbnail",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<SmartVideoThumbnailPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

void SmartVideoThumbnailPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (method_call.method_name().compare("getThumbnail") == 0) {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    
    if (!arguments) {
      LogMessage("❌ SmartVideoThumbnail Windows: Missing required arguments");
      result->Error("BAD_ARGS", "Missing required arguments");
      return;
    }

    // Extract parameters
    std::string video_path;
    int64_t time_ms = 1000;
    int width = 720;
    int height = 405;

    auto path_it = arguments->find(flutter::EncodableValue("path"));
    if (path_it != arguments->end()) {
      video_path = std::get<std::string>(path_it->second);
    } else {
      LogMessage("❌ SmartVideoThumbnail Windows: Missing required argument: path");
      result->Error("BAD_ARGS", "Missing required argument: path");
      return;
    }

    auto time_it = arguments->find(flutter::EncodableValue("timeMs"));
    if (time_it != arguments->end()) {
      time_ms = std::get<int>(time_it->second);
    }

    auto width_it = arguments->find(flutter::EncodableValue("width"));
    if (width_it != arguments->end()) {
      width = std::get<int>(width_it->second);
    }

    auto height_it = arguments->find(flutter::EncodableValue("height"));
    if (height_it != arguments->end()) {
      height = std::get<int>(height_it->second);
    }

    // Log path
    {
        std::ostringstream log;
        log << "   path: " << video_path;
        LogMessage(log.str());
    }

    // Convert path to wide string
    int size_needed = MultiByteToWideChar(CP_UTF8, 0, video_path.c_str(), -1, NULL, 0);
    std::wstring wide_path(size_needed, 0);
    MultiByteToWideChar(CP_UTF8, 0, video_path.c_str(), -1, &wide_path[0], size_needed);

    // Extract thumbnail
    auto thumbnail_data = ExtractThumbnail(wide_path, time_ms, width, height);

    if (thumbnail_data.empty()) {
      LogMessage("❌ SmartVideoThumbnail Windows: Failed to extract thumbnail");
      result->Error("EXTRACTION_FAILED", "Failed to extract thumbnail");
      return;
    }

    result->Success(flutter::EncodableValue(thumbnail_data));
  } else {
    result->NotImplemented();
  }
}

}  // namespace smart_video_thumbnail
