import SwiftUI
import Contacts

struct ChatViewWithList: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var listViewModel: ListViewModel
    @StateObject private var locationService = LocationService()
    @State private var messageText = ""
    @State private var allContacts: [String] = []
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chatViewModel.messages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: chatViewModel.messages.count) { _, _ in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if let lastMessage = chatViewModel.messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input area
            VStack(spacing: 0) {
                // Autocomplete suggestions
                if !chatViewModel.suggestions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(chatViewModel.suggestions, id: \.self) { suggestion in
                                Button(action: {
                                    insertSuggestion(suggestion)
                                }) {
                                    Text(suggestion)
                                        .font(.system(size: 14))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(15)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                }
                
                // Message input
                HStack(alignment: .bottom, spacing: 12) {
                    TextField("Type a message with @mentions...", text: $messageText)
                        .textFieldStyle(.roundedBorder)
                        .focused($isInputFocused)
                        .onChange(of: messageText) { _, newValue in
                            updateSuggestions(for: newValue)
                        }
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(messageText.isEmpty ? .gray : .blue)
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .onAppear {
            requestContactsAccess()
            locationService.requestLocationPermission()
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Send to temporary chat (cleared on app launch)
        chatViewModel.sendMessage(messageText)

        // Also save to permanent CRM storage
        let mentions = chatViewModel.extractMentions(from: messageText)
        let message = Message(text: messageText, mentions: mentions)
        listViewModel.addMessageToCRM(message, placeCoordinates: chatViewModel.appleMapsPlaceResults)

        messageText = ""
        chatViewModel.suggestions = []
    }
    
    private func insertSuggestion(_ suggestion: String) {
        if let lastAtIndex = messageText.lastIndex(of: "@") {
            let beforeAt = String(messageText[..<lastAtIndex])
            messageText = beforeAt + "@" + suggestion + " "
            chatViewModel.suggestions = []
        }
    }
    
    private func updateSuggestions(for input: String) {
        if let lastAtIndex = input.lastIndex(of: "@") {
            let afterAt = String(input[input.index(after: lastAtIndex)...])

            var suggestions: [String] = []

            // Add people suggestions (from actual device contacts)
            let peopleSuggestions = allContacts
                .filter { $0.lowercased().hasPrefix(afterAt.lowercased()) }
            suggestions += peopleSuggestions
            print("Showing \(peopleSuggestions.count) people suggestions from \(allContacts.count) total contacts")

            // Add existing place suggestions
            let existingPlaceSuggestions = listViewModel.places
                .map { $0.name }
                .filter { $0.lowercased().hasPrefix(afterAt.lowercased()) }
            suggestions += existingPlaceSuggestions

            // Track sources for type detection - use ALL device contacts, not just suggestions
            chatViewModel.contactPeople = Set(allContacts)

            // Search for places from Apple Maps
            if afterAt.count >= 2 { // Only search after 2+ characters
                locationService.searchPlacesWithCoordinates(query: afterAt) { placeResults in
                    // Add Apple Maps places that aren't already in our suggestions
                    let newPlaces = placeResults.map { $0.name }.filter { place in
                        !suggestions.contains(place)
                    }
                    let finalSuggestions = suggestions + newPlaces

                    // Store the Apple Maps places and coordinates for type detection and later use
                    let placeNames = placeResults.map { $0.name }
                    chatViewModel.appleMapsPlaces = Set(placeNames)

                    // Store place results with coordinates
                    for result in placeResults {
                        chatViewModel.appleMapsPlaceResults[result.name] = result
                    }

                    print("Location search returned \(placeResults.count) places for '\(afterAt)'")
                    chatViewModel.suggestions = Array(finalSuggestions.prefix(8))
                }
            } else {
                chatViewModel.suggestions = Array(suggestions.prefix(8))
            }
        } else {
            chatViewModel.suggestions = []
        }
    }

    private func requestContactsAccess() {
        let store = CNContactStore()

        store.requestAccess(for: .contacts) { granted, error in
            if granted {
                fetchContacts()
            }
        }
    }

    private func fetchContacts() {
        let store = CNContactStore()
        let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactNicknameKey] as [CNKeyDescriptor]

        do {
            let contacts = try store.unifiedContacts(matching: CNContact.predicateForContactsInContainer(withIdentifier: store.defaultContainerIdentifier()), keysToFetch: keysToFetch)

            let contactNames = contacts.compactMap { contact in
                formatContactName(contact)
            }

            DispatchQueue.main.async {
                self.allContacts = contactNames
                print("Fetched \(contactNames.count) contacts: \(contactNames.prefix(3))")
            }
        } catch {
            print("Failed to fetch contacts: \(error)")
        }
    }

    private func formatContactName(_ contact: CNContact) -> String? {
        // Prefer nickname if available
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

        return nil
    }
}

#Preview {
    ChatViewWithList()
        .environmentObject(ListViewModel())
        .environmentObject(ChatViewModel())
}