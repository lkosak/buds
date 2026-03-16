import Foundation
import SwiftData

enum ContactChannel: String, Codable, CaseIterable, Sendable {
    case inPerson = "In Person"
    case call = "Call"
    case text = "Text"
    case video = "Video"
    case social = "Social"

    var systemImage: String {
        switch self {
        case .inPerson: return "person.2.fill"
        case .call: return "phone.fill"
        case .text: return "message.fill"
        case .video: return "video.fill"
        case .social: return "globe"
        }
    }
}

@Model
final class ContactInteraction {
    var date: Date = Date()
    var channelRaw: String?
    var note: String?
    var bud: Bud?

    var channel: ContactChannel? {
        get { channelRaw.flatMap { ContactChannel(rawValue: $0) } }
        set { channelRaw = newValue?.rawValue }
    }

    init(date: Date = Calendar.current.startOfDay(for: Date()), channel: ContactChannel? = nil, note: String? = nil) {
        self.date = Calendar.current.startOfDay(for: date)
        self.channelRaw = channel?.rawValue
        self.note = note
    }
}
