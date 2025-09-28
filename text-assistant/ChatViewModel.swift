import Foundation
import Combine
import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var currentInput: String = ""
    @Published var suggestions: [String] = []

    // Track sources for type detection
    var appleMapsPlaces: Set<String> = []
    var appleMapsPlaceResults: [String: PlaceSearchResult] = [:]
    var contactPeople: Set<String> = []
    
    private let userDefaults = UserDefaults.standard
    private let messagesKey = "saved_messages"
    
    init() {
        loadMessages()
    }
    
    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let message = Message(text: text, mentions: [])

        messages.append(message)
        saveMessages()

        print("Message sent: \(text)")
    }
    
    
    func updateSuggestions(for input: String) {
        // Find the current @ mention being typed
        if let lastAtIndex = input.lastIndex(of: "@") {
            let afterAt = String(input[input.index(after: lastAtIndex)...])
            
            if !afterAt.contains(" ") {  // Still typing the mention
                // No suggestions yet - will be populated from actual people/projects
                suggestions = []
            } else {
                suggestions = []
            }
        } else {
            suggestions = []
        }
    }
    
    private func saveMessages() {
        if let encoded = try? JSONEncoder().encode(messages) {
            userDefaults.set(encoded, forKey: messagesKey)
        }
    }
    
    private func loadMessages() {
        if let data = userDefaults.data(forKey: messagesKey),
           let decoded = try? JSONDecoder().decode([Message].self, from: data) {
            messages = decoded
        }
    }

    func clearMessages() {
        messages = []
        userDefaults.removeObject(forKey: messagesKey)
        print("Messages cleared on app launch")
    }
}