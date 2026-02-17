import Flutter
import UIKit
import AVFoundation

public class SwiftSmartVideoThumbnailPlugin: NSObject, FlutterPlugin {
    private static let channelName = "smart_video_thumbnail"
    private var progressHandlers: [String: FlutterEventSink] = [:]
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = SwiftSmartVideoThumbnailPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getThumbnail":
            handleGetThumbnail(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handleGetThumbnail(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let videoPath = args["path"] as? String else {
            result(FlutterError(
                code: "BAD_ARGS",
                message: "Missing required arguments: path",
                details: nil
            ))
            return
        }
        
        let timeMs = args["timeMs"] as? Int ?? 1000
        let width = args["width"] as? Int ?? 720
        let height = args["height"] as? Int ?? (width * 9 / 16)
        let strategy = args["strategy"] as? String ?? "normal"
        let requestId = args["requestId"] as? String
        
        // Log parameters
        NSLog("🎬 SmartVideoThumbnail: getThumbnail called")
        NSLog("   path: \(videoPath)")
        NSLog("   timeMs: \(timeMs)")
        NSLog("   size: \(width)x\(height)")
        NSLog("   strategy: \(strategy)")
        
        // Validate file exists
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: videoPath) else {
            NSLog("❌ SmartVideoThumbnail: File not found: \(videoPath)")
            result(FlutterError(
                code: "FILE_NOT_FOUND",
                message: "Video file not found: \(videoPath)",
                details: nil
            ))
            return
        }
        
        // Extract thumbnail asynchronously
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                // Report initial progress
                if let requestId = requestId {
                    self?.reportProgress(requestId: requestId, progress: 0.1)
                }
                
                let thumbnailData = try self?.extractThumbnail(
                    videoPath: videoPath,
                    timeMs: timeMs,
                    width: width,
                    height: height,
                    strategy: strategy,
                    requestId: requestId
                )
                
                // Report completion progress
                if let requestId = requestId {
                    self?.reportProgress(requestId: requestId, progress: 1.0)
                }
                
                DispatchQueue.main.async {
                    if let data = thumbnailData {
                        NSLog("✅ SmartVideoThumbnail: Thumbnail extracted successfully (\(data.count) bytes)")
                        result(FlutterStandardTypedData(bytes: data))
                    } else {
                        NSLog("❌ SmartVideoThumbnail: Failed to extract thumbnail")
                        result(FlutterError(
                            code: "EXTRACTION_FAILED",
                            message: "Failed to extract thumbnail",
                            details: nil
                        ))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    NSLog("❌ SmartVideoThumbnail: Error: \(error.localizedDescription)")
                    result(FlutterError(
                        code: "EXTRACTION_ERROR",
                        message: error.localizedDescription,
                        details: nil
                    ))
                }
            }
        }
    }
    
    private func extractThumbnail(
        videoPath: String,
        timeMs: Int,
        width: Int,
        height: Int,
        strategy: String,
        requestId: String?
    ) throws -> Data? {
        let url = URL(fileURLWithPath: videoPath)
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        // Configure image generator
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: width, height: height)
        
        // Set tolerance based on strategy
        switch strategy {
        case "keyframe":
            imageGenerator.requestedTimeToleranceBefore = .zero
            imageGenerator.requestedTimeToleranceAfter = CMTime(seconds: 1.0, preferredTimescale: 600)
        case "firstFrame":
            imageGenerator.requestedTimeToleranceBefore = .zero
            imageGenerator.requestedTimeToleranceAfter = .zero
        default: // normal
            imageGenerator.requestedTimeToleranceBefore = CMTime(seconds: 0.5, preferredTimescale: 600)
            imageGenerator.requestedTimeToleranceAfter = CMTime(seconds: 0.5, preferredTimescale: 600)
        }
        
        // Report progress
        if let requestId = requestId {
            reportProgress(requestId: requestId, progress: 0.5)
        }
        
        // Calculate target time
        let targetTime: CMTime
        if strategy == "firstFrame" {
            targetTime = .zero
        } else {
            targetTime = CMTime(value: Int64(timeMs), timescale: 1000)
        }
        
        // Generate thumbnail
        let cgImage = try imageGenerator.copyCGImage(at: targetTime, actualTime: nil)
        
        // Report progress
        if let requestId = requestId {
            reportProgress(requestId: requestId, progress: 0.8)
        }
        
        // Convert to RGBA8888 format
        let rgbaData = convertToRGBA8888(cgImage: cgImage, width: width, height: height)
        
        return rgbaData
    }
    
    private func convertToRGBA8888(cgImage: CGImage, width: Int, height: Int) -> Data? {
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = Data(count: width * height * bytesPerPixel)
        
        pixelData.withUnsafeMutableBytes { ptr in
            guard let context = CGContext(
                data: ptr.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return
            }
            
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        
        return pixelData
    }
    
    private func reportProgress(requestId: String, progress: Double) {
        // Progress reporting would be implemented via EventChannel
        // For now, just log it
        NSLog("📊 SmartVideoThumbnail: Progress [\(requestId)]: \(Int(progress * 100))%")
    }
}
