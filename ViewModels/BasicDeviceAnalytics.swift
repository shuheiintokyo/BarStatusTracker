import Foundation
import CoreLocation
import UIKit

// MARK: - Basic Device Info Collection
class BasicDeviceAnalytics: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var deviceInfo: BasicDeviceInfo
    @Published var locationInfo: BasicLocationInfo?
    
    private let locationManager = CLLocationManager()
    
    override init() {
        // Collect device info immediately
        self.deviceInfo = BasicDeviceInfo()
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Location Services (Optional)
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer // City-level for privacy
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func getCurrentLocation() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            print("📍 Location permission not granted (optional)")
            return
        }
        
        locationManager.requestLocation()
    }
    
    // MARK: - Location Manager Delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Reverse geocoding to get city/country
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks: [CLPlacemark]?, error: Error?) in
            if let error = error {
                print("📍 Geocoding error: \(error.localizedDescription)")
                return
            }
            
            guard let placemark = placemarks?.first else { return }
            
            self?.locationInfo = BasicLocationInfo(
                city: placemark.locality,
                country: placemark.country,
                countryCode: placemark.isoCountryCode
            )
            
            print("📍 Location: \(self?.locationInfo?.summary ?? "Unknown")")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("📍 Location error (optional): \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            getCurrentLocation()
        case .denied, .restricted:
            print("📍 Location access denied (that's okay, analytics will work without it)")
        case .notDetermined:
            break
        @unknown default:
            break
        }
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

// MARK: - Basic Location Info
struct BasicLocationInfo: Codable {
    let city: String?
    let country: String?
    let countryCode: String?
    
    var summary: String {
        return "\(city ?? "Unknown"), \(country ?? "Unknown")"
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "city": city ?? "",
            "country": country ?? "",
            "countryCode": countryCode ?? ""
        ]
    }
}
