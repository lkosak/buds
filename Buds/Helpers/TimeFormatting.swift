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

    var sortOrder: Int {
        switch self {
        case .lost: return 0
        case .urgent: return 1
        case .stale: return 2
        case .okay: return 3
        case .unknown: return 4
        case .fresh: return 5
        }
    }

    static func from(lastContact: Date?) -> UrgencyLevel {
        guard let date = lastContact else { return .unknown }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        switch days {
        case ..<3: return .fresh
        case 3..<7: return .okay
        case 7..<14: return .stale
        case 14..<28: return .urgent
        default: return .lost
        }
    }
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
