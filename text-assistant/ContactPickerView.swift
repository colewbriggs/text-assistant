import SwiftUI
import ContactsUI
import UIKit

struct ContactPickerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onContactSelected: (String) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPickerView

        init(_ parent: ContactPickerView) {
            self.parent = parent
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let name = formatContactName(contact)
            parent.onContactSelected(name)
            parent.isPresented = false
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.isPresented = false
        }

        private func formatContactName(_ contact: CNContact) -> String {
            // Try nickname first, then combine given and family name
            if !contact.nickname.isEmpty {
                return contact.nickname
            }

            let firstName = contact.givenName
            let lastName = contact.familyName

            if !firstName.isEmpty && !lastName.isEmpty {
                return "\(firstName) \(lastName)"
            } else if !firstName.isEmpty {
                return firstName
            } else if !lastName.isEmpty {
                return lastName
            }

            return "Unknown Contact"
        }
    }
}