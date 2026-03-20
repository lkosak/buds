import SwiftUI

enum UrgencyLevel: Comparable {
    case fresh
    case okay
    case stale
    case urgent
    case lost
    case unknown

    var color: Color {
        switch self {
        case .fresh: return .green
        case .okay: return .yellow
        case .stale: return .orange
        case .urgent: return .red
        case .lost: return Color(red: 0.6, green: 0, blue: 0)
        case .unknown: return .gray
        }
    }

    static func from(lastContact: Date?, cadenceDays: Int) -> UrgencyLevel {
        guard let ratio = urgencyRatio(lastContact: lastContact, cadenceDays: cadenceDays) else {
            return .unknown
        }
        switch ratio {
        case ..<0.95: return .fresh
        case 0.95..<1.0: return .okay
        case 1.0..<1.25: return .stale
        case 1.25..<1.5: return .urgent
        default: return .lost
        }
    }
}

func urgencyRatio(lastContact: Date?, cadenceDays: Int) -> Double? {
    guard let date = lastContact else { return nil }
    let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
    return Double(days) / Double(cadenceDays)
}

func relativeTimeString(from date: Date?) -> String {
    guard let date = date else { return "never" }
    let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
    switch days {
    case 0: return "today"
    case 1: return "yesterday"
    default: return "\(days) days ago"
    }
}
