import Foundation

struct User: Codable {
    let id: String
    let email: String
    let isBarOwner: Bool
    let ownedBarIDs: [String]
}
