import ContactsUI
import SwiftUI

struct ContactPickerView: UIViewControllerRepresentable {
    let onSelectContact: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelectContact: onSelectContact, dismiss: dismiss)
    }

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let onSelectContact: (String, String) -> Void
        let dismiss: DismissAction

        init(onSelectContact: @escaping (String, String) -> Void, dismiss: DismissAction) {
            self.onSelectContact = onSelectContact
            self.dismiss = dismiss
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let name = [contact.givenName, contact.familyName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            let displayName = name.isEmpty ? "Unknown" : name
            onSelectContact(contact.identifier, displayName)
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            dismiss()
        }
    }
}
