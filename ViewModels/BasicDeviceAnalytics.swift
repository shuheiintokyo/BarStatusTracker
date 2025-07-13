import Foundation
import UIKit

// MARK: - Basic Device Info Collection (No Location)
class BasicDeviceAnalytics: NSObject, ObservableObject {
    @Published var deviceInfo: BasicDeviceInfo
    
    override init() {
        // Collect device info immediately
        self.deviceInfo = BasicDeviceInfo()
        super.init()
    }
}

// MARK: - Basic Device Info
struct BasicDeviceInfo: Codable {
    let deviceType: String
    let systemName: String
    let systemVersion: String
    let timeZone: String
    let locale: String
    let appVersion: String
    let isSimulator: Bool
    
    init() {
        let device = UIDevice.current
        
        self.deviceType = BasicDeviceInfo.getDeviceType()
        self.systemName = device.systemName
        self.systemVersion = device.systemVersion
        self.timeZone = TimeZone.current.identifier
        self.locale = Locale.current.identifier
        self.appVersion = BasicDeviceInfo.getAppVersion()
        self.isSimulator = BasicDeviceInfo.isRunningOnSimulator()
    }
    
    var summary: String {
        return "\(deviceType) \(systemName) \(systemVersion)"
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "deviceType": deviceType,
            "systemName": systemName,
            "systemVersion": systemVersion,
            "timeZone": timeZone,
            "locale": locale,
            "appVersion": appVersion,
            "isSimulator": isSimulator
        ]
    }
    
    // MARK: - Helper Functions
    private static func getDeviceType() -> String {
        let model = UIDevice.current.model
        if model.contains("iPad") {
            return "iPad"
        } else if model.contains("iPhone") {
            return "iPhone"
        } else {
            return model
        }
    }
    
    private static func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private static func isRunningOnSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}
