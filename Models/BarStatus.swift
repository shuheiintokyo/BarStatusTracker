import SwiftUI

enum BarStatus: String, CaseIterable, Codable {
    case openingSoon = "opening_soon"
    case open = "open"
    case closingSoon = "closing_soon"
    case closed = "closed"
    
    var color: Color {
        switch self {
        case .openingSoon: return .mint
        case .open: return .green
        case .closingSoon: return .yellow
        case .closed: return .blue
        }
    }
    
    var displayName: String {
        switch self {
        case .openingSoon: return "Opening Soon"
        case .open: return "Open"
        case .closingSoon: return "Closing Soon"
        case .closed: return "Closed"
        }
    }
    
    var icon: String {
        switch self {
        case .openingSoon: return "clock.badge.checkmark"
        case .open: return "checkmark.circle.fill"
        case .closingSoon: return "clock.badge.exclamationmark"
        case .closed: return "xmark.circle.fill"
        }
    }
}
