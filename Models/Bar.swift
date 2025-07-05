import Foundation
import CoreLocation
import FirebaseFirestore

struct Bar: Identifiable, Codable {
    var id: String = UUID().uuidString
    let name: String
    let latitude: Double
    let longitude: Double
    let address: String
    var status: BarStatus
    var description: String
    var socialLinks: SocialLinks
    var lastUpdated: Date
    var ownerID: String?
    
    // Authentication fields
    let username: String
    let password: String
    
    // Auto-transition timer fields
    var autoTransitionTime: Date?           // When the auto-change should happen
    var pendingStatus: BarStatus?           // What status to change to automatically
    var isAutoTransitionActive: Bool = false // Whether a timer is currently running
    
    // Computed property for location
    var location: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // Computed property to check if auto-transition should trigger
    var shouldAutoTransition: Bool {
        guard isAutoTransitionActive,
              let transitionTime = autoTransitionTime,
              transitionTime <= Date() else {
            return false
        }
        return true
    }
    
    // Computed property for remaining time until auto-transition
    var timeUntilAutoTransition: TimeInterval? {
        guard isAutoTransitionActive,
              let transitionTime = autoTransitionTime else {
            return nil
        }
        let remaining = transitionTime.timeIntervalSinceNow
        return remaining > 0 ? remaining : 0
    }
    
    init(name: String, latitude: Double, longitude: Double, address: String, status: BarStatus = .closed, description: String = "", socialLinks: SocialLinks = SocialLinks(), ownerID: String? = nil, password: String) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.status = status
        self.description = description
        self.socialLinks = socialLinks
        self.lastUpdated = Date()
        self.ownerID = ownerID
        self.username = name // Username is the bar name
        self.password = password
    }
    
    // Mutating function to start auto-transition timer
    mutating func startAutoTransition(to targetStatus: BarStatus, in minutes: Int = 60) {
        self.autoTransitionTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
        self.pendingStatus = targetStatus
        self.isAutoTransitionActive = true
        self.lastUpdated = Date()
    }
    
    // Mutating function to cancel auto-transition
    mutating func cancelAutoTransition() {
        self.autoTransitionTime = nil
        self.pendingStatus = nil
        self.isAutoTransitionActive = false
        self.lastUpdated = Date()
    }
    
    // Mutating function to execute auto-transition
    mutating func executeAutoTransition() -> Bool {
        guard shouldAutoTransition,
              let targetStatus = pendingStatus else {
            return false
        }
        
        self.status = targetStatus
        self.autoTransitionTime = nil
        self.pendingStatus = nil
        self.isAutoTransitionActive = false
        self.lastUpdated = Date()
        
        return true
    }
    
    // Convert to Firebase document
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "latitude": latitude,
            "longitude": longitude,
            "address": address,
            "status": status.rawValue,
            "description": description,
            "socialLinks": [
                "instagram": socialLinks.instagram,
                "twitter": socialLinks.twitter,
                "facebook": socialLinks.facebook,
                "website": socialLinks.website
            ],
            "lastUpdated": Timestamp(date: lastUpdated),
            "ownerID": ownerID ?? "",
            "username": username,
            "password": password,
            "isAutoTransitionActive": isAutoTransitionActive
        ]
        
        // Add auto-transition fields if active
        if let autoTransitionTime = autoTransitionTime {
            dict["autoTransitionTime"] = Timestamp(date: autoTransitionTime)
        }
        if let pendingStatus = pendingStatus {
            dict["pendingStatus"] = pendingStatus.rawValue
        }
        
        return dict
    }
    
    // Create from Firebase document
    static func fromDictionary(_ data: [String: Any], documentId: String) -> Bar? {
        guard let name = data["name"] as? String,
              let latitude = data["latitude"] as? Double,
              let longitude = data["longitude"] as? Double,
              let address = data["address"] as? String,
              let statusString = data["status"] as? String,
              let status = BarStatus(rawValue: statusString),
              let description = data["description"] as? String,
              let username = data["username"] as? String,
              let password = data["password"] as? String else {
            return nil
        }
        
        var bar = Bar(name: name, latitude: latitude, longitude: longitude, address: address, status: status, description: description, password: password)
        bar.id = documentId
        
        // Social links
        if let socialData = data["socialLinks"] as? [String: Any] {
            bar.socialLinks.instagram = socialData["instagram"] as? String ?? ""
            bar.socialLinks.twitter = socialData["twitter"] as? String ?? ""
            bar.socialLinks.facebook = socialData["facebook"] as? String ?? ""
            bar.socialLinks.website = socialData["website"] as? String ?? ""
        }
        
        // Last updated
        if let timestamp = data["lastUpdated"] as? Timestamp {
            bar.lastUpdated = timestamp.dateValue()
        }
        
        // Auto-transition fields
        bar.isAutoTransitionActive = data["isAutoTransitionActive"] as? Bool ?? false
        
        if let autoTransitionTimestamp = data["autoTransitionTime"] as? Timestamp {
            bar.autoTransitionTime = autoTransitionTimestamp.dateValue()
        }
        
        if let pendingStatusString = data["pendingStatus"] as? String,
           let pendingStatus = BarStatus(rawValue: pendingStatusString) {
            bar.pendingStatus = pendingStatus
        }
        
        bar.ownerID = data["ownerID"] as? String
        
        return bar
    }
}

struct SocialLinks: Codable {
    var instagram: String = ""
    var twitter: String = ""
    var facebook: String = ""
    var website: String = ""
}
