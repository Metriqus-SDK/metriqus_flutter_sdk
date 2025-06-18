import Flutter
import UIKit
import Metal
import MetalKit
import AdSupport
import AppTrackingTransparency
import StoreKit

// AdServices is only available on iOS 14.3+
#if canImport(AdServices)
import AdServices
#endif

public class MetriqusFlutterSdkPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "metriqus_flutter_sdk/device_info", binaryMessenger: registrar.messenger())
    let instance = MetriqusFlutterSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getGpuInfo":
      getGpuInfo(result: result)
    case "getScreenInfo":
      getScreenInfo(result: result)
    case "getAdId":
      getAdId(result: result)

    case "getLanguageDisplayName":
      getLanguageDisplayName(call: call, result: result)
    case "registerSKAdNetwork":
      registerSKAdNetwork(result: result)
    case "reportAdNetworkAttribution":
      reportAdNetworkAttribution(result: result)
    case "updateConversionValue":
      updateConversionValue(call: call, result: result)
    case "requestTrackingPermission":
      requestTrackingPermission(result: result)
    case "readAttributionToken":
      readAttributionToken(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func getGpuInfo(result: @escaping FlutterResult) {
    var gpuInfo: [String: Any] = [:]
    
    // Get GPU information using Metal
    guard let device = MTLCreateSystemDefaultDevice() else {
      gpuInfo["renderer"] = "Apple GPU"
      gpuInfo["graphicsMemory"] = 0
      gpuInfo["systemMemory"] = Int(ProcessInfo.processInfo.physicalMemory)
      result(gpuInfo)
      return
    }
    
    gpuInfo["renderer"] = device.name
    
    // Get memory information safely
    if #available(iOS 16.0, *) {
      gpuInfo["graphicsMemory"] = Int(device.recommendedMaxWorkingSetSize)
    } else {
      let maxBufferSize = device.maxBufferLength
      let physicalMemory = ProcessInfo.processInfo.physicalMemory
      
      if maxBufferSize > Int(physicalMemory) || maxBufferSize == 0 {
        gpuInfo["graphicsMemory"] = Int(Double(physicalMemory) * 0.4)
      } else {
        gpuInfo["graphicsMemory"] = Int(min(UInt64(maxBufferSize), physicalMemory))
      }
    }
    
    // Get system memory
    let physicalMemory = ProcessInfo.processInfo.physicalMemory
    gpuInfo["systemMemory"] = Int(physicalMemory)
    
    result(gpuInfo)
  }
  
  private func getScreenInfo(result: @escaping FlutterResult) {
    let screen = UIScreen.main
    let bounds = screen.bounds
    let scale = screen.scale
    
    let screenInfo: [String: Any] = [
      "width": Int(bounds.width * scale),
      "height": Int(bounds.height * scale),
      "dpi": scale * 160.0 // iOS base DPI is 160
    ]
    
    result(screenInfo)
  }
  
  private func getAdId(result: @escaping FlutterResult) {
    if #available(iOS 14, *) {
      // iOS 14+ için ATTrackingManager kullan
      let trackingStatus = ATTrackingManager.trackingAuthorizationStatus
      let isTrackingEnabled = trackingStatus == .authorized
      
      let advertisingId = ASIdentifierManager.shared().advertisingIdentifier.uuidString
      
      let adInfo: [String: Any] = [
        "success": true,
        "trackingEnabled": isTrackingEnabled,
        "adId": isTrackingEnabled && advertisingId != "00000000-0000-0000-0000-000000000000" ? advertisingId : ""
      ]
      
      result(adInfo)
    } else {
      // iOS 14 öncesi için ASIdentifierManager kullan
      let advertisingManager = ASIdentifierManager.shared()
      let isTrackingEnabled = advertisingManager.isAdvertisingTrackingEnabled
      let advertisingId = advertisingManager.advertisingIdentifier.uuidString
      
      let adInfo: [String: Any] = [
        "success": true,
        "trackingEnabled": isTrackingEnabled,
        "adId": isTrackingEnabled && advertisingId != "00000000-0000-0000-0000-000000000000" ? advertisingId : ""
      ]
      
      result(adInfo)
    }
  }
  
  
  
  private func getLanguageDisplayName(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let languageCode = args["languageCode"] as? String else {
      result("")
      return
    }
    
    // Locale oluştur ve display name al
    let locale = Locale(identifier: languageCode)
    let englishLocale = Locale(identifier: "en_US")
    
    // Her zaman İngilizce locale'e göre bu dilin adını al
    if let displayName = englishLocale.localizedString(forLanguageCode: languageCode) {
      // İlk harfi büyük yap
      let capitalizedName = displayName.prefix(1).uppercased() + displayName.dropFirst()
      result(String(capitalizedName))
    } else {
             result("")
     }
   }
   
       private func registerSKAdNetwork(result: @escaping FlutterResult) {
      // iOS 11.3+ için SKAdNetwork support
      if #available(iOS 11.3, *) {
        SKAdNetwork.registerAppForAdNetworkAttribution()
        result(["success": true, "message": "SKAdNetwork registered successfully"])
        print("✅ SKAdNetwork registered for attribution")
      } else {
        result(["success": false, "message": "SKAdNetwork not supported on this iOS version"])
        print("❌ SKAdNetwork not supported on iOS < 11.3")
      }
    }
    
    private func reportAdNetworkAttribution(result: @escaping FlutterResult) {
      print("[Metriqus] Reporting ad network attribution...")
      
      if #available(iOS 15.4, *) {
        print("[Metriqus] Using updatePostbackConversionValue.")
        SKAdNetwork.updatePostbackConversionValue(0) { error in
          self.handleSKAdNetworkCompletion(error: error, result: result)
        }
      } else if #available(iOS 14.0, *) {
        print("[Metriqus] Using deprecated updateConversionValue.")
        SKAdNetwork.updateConversionValue(0)
        result(["success": true, "message": "Fallback to updateConversionValue for older iOS versions (14.0 - 15.4)."])
      } else if #available(iOS 11.3, *) {
        print("[Metriqus] Using registerAppForAdNetworkAttribution.")
        SKAdNetwork.registerAppForAdNetworkAttribution()
        result(["success": true, "message": "Fallback to registerAppForAdNetworkAttribution for older iOS versions (11.3 - 15.3)."])
      } else {
        print("[Metriqus] SKAdNetwork not supported on this iOS version.")
        result(["success": false, "message": "SKAdNetwork is not supported on iOS versions below 11.3."])
      }
    }
    
    private func updateConversionValue(call: FlutterMethodCall, result: @escaping FlutterResult) {
      guard let args = call.arguments as? [String: Any],
            let value = args["value"] as? Int else {
        result(["success": false, "message": "Invalid conversion value parameter"])
        return
      }
      
      print("[Metriqus] Updating conversion value: \(value)")
      
      if #available(iOS 15.4, *) {
        print("[Metriqus] Using updatePostbackConversionValue.")
        SKAdNetwork.updatePostbackConversionValue(value) { error in
          self.handleSKAdNetworkCompletion(error: error, result: result)
        }
      } else if #available(iOS 14.0, *) {
        print("[Metriqus] Using deprecated updateConversionValue.")
        SKAdNetwork.updateConversionValue(value)
        result(["success": true, "message": "Fallback to updateConversionValue for older iOS versions (14.0 - 15.4)."])
      } else {
        print("[Metriqus] SKAdNetwork not supported on this iOS version.")
        result(["success": false, "message": "SKAdNetwork is not supported on iOS versions below 14.0."])
      }
    }
    
    private func requestTrackingPermission(result: @escaping FlutterResult) {
      if #available(iOS 14, *) {
        let currentStatus = ATTrackingManager.trackingAuthorizationStatus
        
        if currentStatus == .notDetermined {
          ATTrackingManager.requestTrackingAuthorization { status in
            DispatchQueue.main.async {
              self.handleTrackingAuthorizationStatus(status: status, result: result)
            }
          }
        } else {
          handleTrackingAuthorizationStatus(status: currentStatus, result: result)
        }
      } else {
        // iOS 14 öncesi
        let advertisingManager = ASIdentifierManager.shared()
        let idfa = advertisingManager.advertisingIdentifier
        let isTrackingEnabled = advertisingManager.isAdvertisingTrackingEnabled
        
        if isTrackingEnabled && idfa.uuidString != "00000000-0000-0000-0000-000000000000" {
          result(["success": true, "idfa": idfa.uuidString, "authorized": true])
        } else {
          result(["success": true, "idfa": "", "authorized": false])
        }
      }
    }
    
    @available(iOS 14, *)
    private func handleTrackingAuthorizationStatus(status: ATTrackingManager.AuthorizationStatus, result: @escaping FlutterResult) {
      let idfa = ASIdentifierManager.shared().advertisingIdentifier
      
      switch status {
      case .authorized:
        if idfa.uuidString != "00000000-0000-0000-0000-000000000000" {
          result(["success": true, "idfa": idfa.uuidString, "authorized": true])
        } else {
          result(["success": true, "idfa": "", "authorized": true])
        }
      case .denied:
        result(["success": true, "idfa": "", "authorized": false])
      case .restricted:
        result(["success": true, "idfa": "", "authorized": false])
      case .notDetermined:
        result(["success": true, "idfa": "", "authorized": false])
      @unknown default:
        result(["success": true, "idfa": "", "authorized": false])
      }
    }
    
    private func readAttributionToken(result: @escaping FlutterResult) {
      print("[Metriqus] Reading attribution token...")
      
      #if canImport(AdServices)
      if #available(iOS 14.3, *) {
        do {
          let token = try AAAttribution.attributionToken()
          print("[Metriqus] Successfully retrieved attribution token.")
          result(["success": true, "token": token])
        } catch {
          print("[Metriqus] Failed to retrieve attribution token: \(error.localizedDescription)")
          result(["success": false, "error": "Failed to retrieve attribution token: \(error.localizedDescription)"])
        }
      } else {
        print("[Metriqus] Attribution token requires iOS 14.3 or later.")
        result(["success": false, "error": "Attribution token requires iOS 14.3 or later."])
      }
      #else
      print("[Metriqus] AdServices framework not available.")
      result(["success": false, "error": "AdServices framework not available."])
      #endif
    }
    

    
    private func handleSKAdNetworkCompletion(error: Error?, result: @escaping FlutterResult) {
      if let error = error {
        print("[Metriqus] SKAdNetwork completion failed: \(error.localizedDescription) (Code: \(error._code), Domain: \(error._domain))")
        result(["success": false, "message": "Error updating postback conversion value: \(error.localizedDescription) (Code: \(error._code), Domain: \(error._domain))"])
      } else {
        print("[Metriqus] Postback conversion value updated successfully.")
        result(["success": true, "message": "Postback conversion value updated successfully."])
      }
    }
}  