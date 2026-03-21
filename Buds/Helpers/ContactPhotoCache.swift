import Contacts
import UIKit

@MainActor @Observable
final class ContactPhotoCache {
    static let shared = ContactPhotoCache()

    private var cache: [String: UIImage?] = [:]
    private var inFlight: [String: Task<UIImage?, Never>] = [:]

    private init() {}

    func fetch(for contactID: String) async -> UIImage? {
        if let cached = cache[contactID] {
            return cached
        }
        if let task = inFlight[contactID] {
            return await task.value
        }
        let task = Task<UIImage?, Never> {
            await Self.fetchFromContacts(contactID: contactID)
        }
        inFlight[contactID] = task
        let image = await task.value
        cache[contactID] = image
        inFlight.removeValue(forKey: contactID)
        return image
    }

    // Synchronous check without triggering a load – used by detail view after photo is already cached
    func cachedPhoto(for contactID: String) -> UIImage? {
        cache[contactID] ?? nil
    }

    private static func fetchFromContacts(contactID: String) async -> UIImage? {
        let store = CNContactStore()
        do {
            let contact = try store.unifiedContact(
                withIdentifier: contactID,
                keysToFetch: [CNContactThumbnailImageDataKey as CNKeyDescriptor]
            )
            if let data = contact.thumbnailImageData {
                return UIImage(data: data)
            }
        } catch {
            // Contact may have been deleted or access denied
        }
        return nil
    }
}
