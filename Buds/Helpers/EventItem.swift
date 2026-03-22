import Foundation

enum EventItem: Identifiable {
    case appEvent(Event)
    case birthday(bud: Bud, nextDate: Date, components: DateComponents)

    var id: String {
        switch self {
        case .appEvent(let event):
            return "event-\(event.persistentModelID.hashValue)"
        case .birthday(let bud, _, _):
            return "birthday-\(bud.contactID)"
        }
    }

    var date: Date {
        switch self {
        case .appEvent(let event): return event.date
        case .birthday(_, let nextDate, _): return nextDate
        }
    }

    var title: String {
        switch self {
        case .appEvent(let event):
            return event.note.isEmpty ? "Event" : event.note
        case .birthday:
            return "Birthday"
        }
    }

    var budName: String {
        switch self {
        case .appEvent(let event): return event.bud?.name ?? ""
        case .birthday(let bud, _, _): return bud.name
        }
    }

    var isBirthday: Bool {
        if case .birthday = self { return true }
        return false
    }
}
