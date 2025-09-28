import SwiftUI

struct PersonDetailView: View {
    let person: Person
    let messages: [Message]
    @EnvironmentObject var viewModel: ListViewModel

    init(person: Person, messages: [Message] = []) {
        self.person = person
        self.messages = messages
    }

    var body: some View {
        List {
            if messages.isEmpty {
                Text("No mentions found")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                ForEach(messages) { message in
                    MessageRowView(message: message, highlightedName: person.name)
                }
                .onDelete(perform: deleteMessages)
            }
        }
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func deleteMessages(offsets: IndexSet) {
        for index in offsets {
            let messageToDelete = messages[index]
            viewModel.deleteMessage(messageToDelete)
        }
    }
}

struct MessageRowView: View {
    let message: Message
    let highlightedName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(highlightedText)
                .font(.body)

            Text(message.timestamp, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var highlightedText: AttributedString {
        var attributedString = AttributedString(message.text)

        // Find and highlight the person's name
        let searchText = "@\(highlightedName)"
        if let range = attributedString.range(of: searchText, options: .caseInsensitive) {
            attributedString[range].foregroundColor = .blue
            attributedString[range].font = .body.weight(.semibold)
        }

        return attributedString
    }
}

struct PersonDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PersonDetailView(person: Person(name: "John"))
        }
    }
}