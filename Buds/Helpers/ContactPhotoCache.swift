import Contacts
import UIKit

@Observable
final class ContactPhotoCache {
    private var cache: [String: UIImage] = [:]
    private var loading: Set<String> = []
    private let store = CNContactStore()

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
            let image = await fetchPhoto(contactID: contactID)
            await MainActor.run {
                self.cache[contactID] = image
                self.loading.remove(contactID)
            }
        }
    }

    private func fetchPhoto(contactID: String) async -> UIImage? {
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
