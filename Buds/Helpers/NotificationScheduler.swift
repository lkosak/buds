import Foundation
import SwiftData
import UserNotifications

struct BudSnapshot: Sendable {
    let id: String
    let name: String
    let contactID: String
    let lastContactDate: Date?
    let contactCadenceDays: Int
    let events: [(date: Date, note: String)]
}

actor NotificationScheduler {
    static let shared = NotificationScheduler()

    private let center = UNUserNotificationCenter.current()

    func requestPermission() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func rescheduleAll(
        buds: [BudSnapshot],
        birthdays: [(name: String, contactID: String, nextDate: Date)]
    ) async {
        center.removeAllPendingNotificationRequests()

        var thresholdRequests: [(date: Date, request: UNNotificationRequest)] = []
        var eventRequests: [(date: Date, request: UNNotificationRequest)] = []

        for bud in buds {
            if let req = makeThresholdRequest(bud) {
                thresholdRequests.append(req)
            }
            eventRequests.append(contentsOf: makeEventRequests(bud))
        }

        for birthday in birthdays {
            if let req = makeBirthdayRequest(birthday) {
                eventRequests.append(req)
            }
        }

        // Sort by date ascending (most imminent first)
        thresholdRequests.sort { $0.date < $1.date }
        eventRequests.sort { $0.date < $1.date }

        // Apply 64-notification cap: threshold first, then events
        let maxTotal = 64
        let thresholdSlice = Array(thresholdRequests.prefix(maxTotal))
        let remaining = maxTotal - thresholdSlice.count
        let eventSlice = Array(eventRequests.prefix(remaining))

        for (_, request) in thresholdSlice + eventSlice {
            try? await center.add(request)
        }
    }

    // MARK: - Threshold

    private func makeThresholdRequest(_ bud: BudSnapshot) -> (date: Date, request: UNNotificationRequest)? {
        guard let lastContact = bud.lastContactDate else { return nil }
        let dueDays = Double(bud.contactCadenceDays) * 0.95
        guard let dueDate = Calendar.current.date(byAdding: .day, value: Int(dueDays), to: lastContact) else { return nil }
        guard dueDate > Date() else { return nil }

        let content = UNMutableNotificationContent()
        content.title = "Time to reach out"
        content.body = "\(bud.name) is due for contact"
        content.sound = .default
        content.threadIdentifier = "buds-due"

        let trigger = triggerForMorning(of: dueDate)
        let request = UNNotificationRequest(
            identifier: "threshold-\(bud.id)",
            content: content,
            trigger: trigger
        )
        return (dueDate, request)
    }

    // MARK: - Events

    private func makeEventRequests(_ bud: BudSnapshot) -> [(date: Date, request: UNNotificationRequest)] {
        let today = Calendar.current.startOfDay(for: Date())
        return bud.events.compactMap { event in
            guard event.date >= today,
                  let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: event.date),
                  dayBefore > Date() else { return nil }

            let content = UNMutableNotificationContent()
            content.title = bud.name
            content.body = event.note.isEmpty ? "Event is tomorrow" : "\(event.note) is tomorrow"
            content.sound = .default
            content.threadIdentifier = "buds-events"

            let trigger = triggerForMorning(of: dayBefore)
            let dateString = event.date.formatted(.iso8601.year().month().day())
            let request = UNNotificationRequest(
                identifier: "event-\(bud.id)-\(dateString)",
                content: content,
                trigger: trigger
            )
            return (dayBefore, request)
        }
    }

    private func makeBirthdayRequest(
        _ birthday: (name: String, contactID: String, nextDate: Date)
    ) -> (date: Date, request: UNNotificationRequest)? {
        guard let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: birthday.nextDate),
              dayBefore > Date() else { return nil }

        let content = UNMutableNotificationContent()
        content.title = "\(birthday.name)'s birthday is tomorrow"
        content.sound = .default
        content.threadIdentifier = "buds-events"

        let trigger = triggerForMorning(of: dayBefore)
        let request = UNNotificationRequest(
            identifier: "birthday-\(birthday.contactID)",
            content: content,
            trigger: trigger
        )
        return (dayBefore, request)
    }

    // MARK: - Helpers

    private func triggerForMorning(of date: Date) -> UNCalendarNotificationTrigger {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        var morning = components
        morning.hour = 9
        morning.minute = 0
        return UNCalendarNotificationTrigger(dateMatching: morning, repeats: false)
    }
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

@MainActor
func rescheduleAllNotifications(context: ModelContext) async {
    let buds: [Bud]
    do {
        buds = try context.fetch(FetchDescriptor<Bud>())
    } catch {
        return
    }

    let today = Calendar.current.startOfDay(for: Date())
    let snapshots = buds.filter { !$0.isArchived }.map { bud in
        let futureEvents = (bud.events ?? [])
            .filter { $0.date >= today }
            .map { (date: $0.date, note: $0.note) }
        return BudSnapshot(
            id: "\(bud.persistentModelID.hashValue)",
            name: bud.name,
            contactID: bud.contactID,
            lastContactDate: bud.lastContactDate,
            contactCadenceDays: bud.contactCadenceDays,
            events: futureEvents
        )
    }

    let contactIDs = buds.filter { !$0.isArchived }.map(\.contactID)
    let birthdayResults = await BirthdayProvider.shared.birthdays(for: contactIDs)
    let birthdays: [(name: String, contactID: String, nextDate: Date)] = birthdayResults.compactMap { result in
        guard let bud = buds.first(where: { $0.contactID == result.contactID }),
              let next = BirthdayProvider.nextOccurrence(of: result.birthday) else { return nil }
        return (bud.name, bud.contactID, next)
    }

    await NotificationScheduler.shared.rescheduleAll(buds: snapshots, birthdays: birthdays)
}
