import SwiftUI
import Contacts

struct SuggestionItem: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String?
    let isContact: Bool

    init(name: String, isContact: Bool) {
        self.name = name
        self.subtitle = nil
        self.isContact = isContact
    }

    init(placeResult: PlaceSearchResult) {
        self.name = placeResult.name
        self.subtitle = placeResult.address
        self.isContact = false
    }
}

struct ChatViewWithList: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var listViewModel: ListViewModel
    @StateObject private var locationService = LocationService()
    @State private var messageText = ""
    @State private var allContacts: [String] = []
    @State private var lastSubmittedEntry: String? = nil
    @State private var justSelectedSuggestion = false
    @State private var previousInput: String? = nil
    @State private var placeAddresses: [String: String] = [:]
    @State private var confirmedMentions: [Mention] = []
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Confirmation of last submitted entry
            if let lastEntry = lastSubmittedEntry {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Entry Saved")
                            .font(.headline)
                            .foregroundColor(.green)
                        Spacer()
                        Button("Dismiss") {
                            lastSubmittedEntry = nil
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }

                    Text(lastEntry)
                        .font(.body)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
                .padding()
            }

            Spacer()

            // Input area
            VStack(spacing: 0) {
                // Autocomplete dropdown
                if !chatViewModel.suggestions.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(chatViewModel.suggestions.prefix(6).enumerated()), id: \.offset) { index, suggestion in
                            Button(action: {
                                insertSuggestion(suggestion)
                            }) {
                                HStack {
                                    // Icon based on suggestion type
                                    Image(systemName: allContacts.contains(suggestion) ? "person.fill" : "location.fill")
                                        .foregroundColor(allContacts.contains(suggestion) ? .blue : .red)
                                        .frame(width: 20)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(suggestion)
                                            .font(.body)
                                            .foregroundColor(.primary)

                                        // Show address for places
                                        if let address = placeAddresses[suggestion] {
                                            Text(address)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(UIColor.systemBackground))
                            }
                            .buttonStyle(PlainButtonStyle())

                            if index < min(chatViewModel.suggestions.count, 6) - 1 {
                                Divider()
                                    .padding(.leading, 52) // Align with text
                            }
                        }
                    }
                    .background(Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(UIColor.separator), lineWidth: 0.5)
                        )
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                // Message input
                HStack(alignment: .bottom, spacing: 12) {
                    TextField("Add notes about people and places using @mentions...", text: $messageText)
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
        .onTapGesture {
            // Dismiss keyboard when tapping outside text field
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            requestContactsAccess()
            locationService.requestLocationPermission()
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Store the submitted entry for confirmation
        lastSubmittedEntry = messageText

        // Send to temporary chat (cleared on app launch)
        chatViewModel.sendMessage(messageText)

        // Also save to permanent CRM storage using confirmed mentions
        let message = Message(text: messageText, mentions: confirmedMentions)
        listViewModel.addMessageToCRM(message, placeCoordinates: chatViewModel.appleMapsPlaceResults)

        messageText = ""
        confirmedMentions = []
        chatViewModel.suggestions = []

        // Auto-dismiss confirmation after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            lastSubmittedEntry = nil
        }
    }
    
    private func insertSuggestion(_ suggestion: String) {
        if let lastAtIndex = messageText.lastIndex(of: "@") {
            let beforeAt = String(messageText[..<lastAtIndex])

            // Set flag BEFORE changing text to prevent onChange from triggering suggestions
            justSelectedSuggestion = true
            chatViewModel.suggestions = []

            messageText = beforeAt + "@" + suggestion + " "

            // Create a confirmed mention from the user's selection
            let mentionType: MentionType = allContacts.contains(suggestion) ? .person : .place
            let mention = Mention(
                text: "@" + suggestion,
                type: mentionType,
                range: NSRange(location: lastAtIndex.utf16Offset(in: messageText), length: suggestion.count + 1)
            )
            confirmedMentions.append(mention)
            print("✅ Added confirmed mention: \(mention.text) of type \(mention.type)")
        }
    }
    
    private func updateSuggestions(for input: String) {
        // Reset flag only when a new @ is typed
        if let lastAtIndex = input.lastIndex(of: "@"),
           let previousLastAt = previousInput?.lastIndex(of: "@"),
           lastAtIndex != previousLastAt {
            // New @ was typed, allow suggestions again
            justSelectedSuggestion = false
        }

        // Don't show suggestions if we just selected one
        if justSelectedSuggestion {
            chatViewModel.suggestions = []
            return
        }

        if let lastAtIndex = input.lastIndex(of: "@") {
            let afterAt = String(input[input.index(after: lastAtIndex)...])

            var suggestions: [String] = []

            // Add people suggestions (from actual device contacts) - these come first
            let peopleSuggestions = allContacts
                .filter { $0.lowercased().hasPrefix(afterAt.lowercased()) }
            suggestions += peopleSuggestions
            print("Showing \(peopleSuggestions.count) people suggestions from \(allContacts.count) total contacts")

            // Add existing place suggestions - only if no people match exactly
            let existingPlaceSuggestions = listViewModel.places
                .map { $0.name }
                .filter { $0.lowercased().hasPrefix(afterAt.lowercased()) }

            // Only add place suggestions if they don't conflict with people names
            let nonConflictingPlaces = existingPlaceSuggestions.filter { place in
                !peopleSuggestions.contains { person in
                    person.lowercased().contains(place.lowercased()) || place.lowercased().contains(person.lowercased())
                }
            }
            suggestions += nonConflictingPlaces

            // Track sources for type detection - use ALL device contacts, not just suggestions
            chatViewModel.contactPeople = Set(allContacts)

            // Search for places from Apple Maps (only if not from a recent selection)
            if afterAt.count >= 2 && !justSelectedSuggestion { // Only search after 2+ characters and not after selection
                locationService.searchPlacesWithCoordinates(query: afterAt) { placeResults in
                    // Double-check we didn't select something while search was happening
                    guard !self.justSelectedSuggestion else { return }

                    // Add Apple Maps places that aren't already in our suggestions
                    let newPlaces = placeResults.map { $0.name }.filter { place in
                        !suggestions.contains(place)
                    }
                    let finalSuggestions = suggestions + newPlaces

                    // Store the Apple Maps places and coordinates for type detection and later use
                    let placeNames = placeResults.map { $0.name }
                    chatViewModel.appleMapsPlaces = Set(placeNames)

                    // Store place results with coordinates and addresses
                    for result in placeResults {
                        chatViewModel.appleMapsPlaceResults[result.name] = result
                        self.placeAddresses[result.name] = result.address
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

        // Store current input for next comparison
        previousInput = input
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