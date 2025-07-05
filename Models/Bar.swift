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
    
    // Computed property for location
    var location: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
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
    
    // Convert to Firebase document
    func toDictionary() -> [String: Any] {
        return [
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
            "password": password
        ]
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
