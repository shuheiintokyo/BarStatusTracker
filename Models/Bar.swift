import Foundation
import CoreLocation

struct Bar: Identifiable, Codable {
    let id = UUID()
    let name: String
    let location: CLLocationCoordinate2D
    let address: String
    var status: BarStatus
    var description: String
    var socialLinks: SocialLinks
    var lastUpdated: Date
    var ownerID: String?
    
    // New authentication fields
    let username: String        // Will be the bar name
    let password: String        // 4-digit password
    
    enum CodingKeys: String, CodingKey {
        case name, address, status, description, socialLinks, lastUpdated, ownerID, username, password
        case latitude, longitude
    }
    
    init(name: String, latitude: Double, longitude: Double, address: String, status: BarStatus = .closed, description: String = "", socialLinks: SocialLinks = SocialLinks(), ownerID: String? = nil, password: String) {
        self.name = name
        self.location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.address = address
        self.status = status
        self.description = description
        self.socialLinks = socialLinks
        self.lastUpdated = Date()
        self.ownerID = ownerID
        self.username = name        // Username is the bar name
        self.password = password    // 4-digit password
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decode(String.self, forKey: .address)
        status = try container.decode(BarStatus.self, forKey: .status)
        description = try container.decode(String.self, forKey: .description)
        socialLinks = try container.decode(SocialLinks.self, forKey: .socialLinks)
        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        ownerID = try container.decodeIfPresent(String.self, forKey: .ownerID)
        username = try container.decode(String.self, forKey: .username)
        password = try container.decode(String.self, forKey: .password)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(location.latitude, forKey: .latitude)
        try container.encode(location.longitude, forKey: .longitude)
        try container.encode(address, forKey: .address)
        try container.encode(status, forKey: .status)
        try container.encode(description, forKey: .description)
        try container.encode(socialLinks, forKey: .socialLinks)
        try container.encode(lastUpdated, forKey: .lastUpdated)
        try container.encodeIfPresent(ownerID, forKey: .ownerID)
        try container.encode(username, forKey: .username)
        try container.encode(password, forKey: .password)
    }
}

struct SocialLinks: Codable {
    var instagram: String = ""
    var twitter: String = ""
    var facebook: String = ""
    var website: String = ""
}
