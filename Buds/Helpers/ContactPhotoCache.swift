import Contacts
import UIKit

@MainActor @Observable
final class ContactPhotoCache {
    private var cache: [String: UIImage] = [:]
    private var loading: Set<String> = []

    func photo(for contactID: String) -> UIImage? {
        if let cached = cache[contactID] {
            return cached
        }
        loadPhoto(for: contactID)
        return nil
    }

    private func loadPhoto(for contactID: String) {
        guard !loading.contains(contactID) else { return }
        loading.insert(contactID)

        Task {
            let image = await Self.fetchPhoto(contactID: contactID)
            self.cache[contactID] = image
            self.loading.remove(contactID)
        }
    }

    private static func fetchPhoto(contactID: String) async -> UIImage? {
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
