import Contacts
import Foundation

@MainActor @Observable
final class BirthdayProvider {
    static let shared = BirthdayProvider()

    private var cache: [String: DateComponents?] = [:]

    private init() {}

    func birthday(for contactID: String) async -> DateComponents? {
        if let cached = cache[contactID] {
            return cached
        }
        let components = await Self.fetchBirthday(contactID: contactID)
        cache[contactID] = components
        return components
    }

    func birthdays(for contactIDs: [String]) async -> [(contactID: String, birthday: DateComponents)] {
        var results: [(contactID: String, birthday: DateComponents)] = []
        for id in contactIDs {
            if let bday = await birthday(for: id) {
                results.append((id, bday))
            }
        }
        return results
    }

    func setBirthday(_ components: DateComponents?, for contactID: String) async throws {
        let store = CNContactStore()
        let contact = try store.unifiedContact(
            withIdentifier: contactID,
            keysToFetch: [CNContactBirthdayKey as CNKeyDescriptor]
        )
        let mutable = contact.mutableCopy() as! CNMutableContact
        mutable.birthday = components
        let request = CNSaveRequest()
        request.update(mutable)
        try store.execute(request)
        cache[contactID] = components
    }

    func clearCache(for contactID: String) {
        cache.removeValue(forKey: contactID)
    }

    static func nextOccurrence(of components: DateComponents) -> Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let month = components.month, let day = components.day else { return nil }
        let year = calendar.component(.year, from: today)
        var next = DateComponents()
        next.year = year
        next.month = month
        next.day = day
        if let date = calendar.date(from: next), date >= today {
            return date
        }
        next.year = year + 1
        return calendar.date(from: next)
    }

    private static func fetchBirthday(contactID: String) async -> DateComponents? {
        let store = CNContactStore()
        do {
            let contact = try store.unifiedContact(
                withIdentifier: contactID,
                keysToFetch: [CNContactBirthdayKey as CNKeyDescriptor]
            )
            return contact.birthday
        } catch {
            return nil
        }
    }
}
