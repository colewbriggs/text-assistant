import Foundation
import Combine
import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var currentInput: String = ""
    @Published var suggestions: [String] = []
    
    private let userDefaults = UserDefaults.standard
    private let messagesKey = "saved_messages"
    
    init() {
        loadMessages()
    }
    
    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let mentions = extractMentions(from: text)
        let message = Message(text: text, mentions: mentions)
        
        messages.append(message)
        saveMessages()
        
        print("Message sent: \(text)")
        print("Mentions found: \(mentions.count)")
    }
    
    func extractMentions(from text: String) -> [Mention] {
        var mentions: [Mention] = []
        let regex = try! NSRegularExpression(pattern: "@\\w+", options: [])
        let range = NSRange(location: 0, length: text.utf16.count)
        
        regex.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            guard let matchRange = match?.range else { return }
            
            let startIndex = text.index(text.startIndex, offsetBy: matchRange.location)
            let endIndex = text.index(startIndex, offsetBy: matchRange.length)
            let mentionText = String(text[startIndex..<endIndex])
            
            // Simple type detection based on common patterns
            let type = detectMentionType(mentionText)
            let mention = Mention(text: mentionText, type: type, range: matchRange)
            mentions.append(mention)
        }
        
        return mentions
    }
    
    private func detectMentionType(_ mention: String) -> MentionType {
        let lowercased = mention.lowercased()
        
        if lowercased.contains("project") || lowercased.contains("work") {
            return .project
        } else {
            return .person  // Default to person for most @ mentions
        }
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