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
        
        let mentions = extractMentions(from: text)
        let message = Message(text: text, mentions: mentions)
        
        messages.append(message)
        saveMessages()
        
        print("Message sent: \(text)")
        print("Mentions found: \(mentions.count)")
    }
    
    func extractMentions(from text: String) -> [Mention] {
        var mentions: [Mention] = []
        // Pattern: @ followed by letters/spaces/hyphens, but stop at punctuation that would end a name
        let regex = try! NSRegularExpression(pattern: "@[\\w\\s\\-]+", options: [])
        let range = NSRange(location: 0, length: text.utf16.count)

        regex.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            guard let matchRange = match?.range else { return }

            let startIndex = text.index(text.startIndex, offsetBy: matchRange.location)
            let endIndex = text.index(startIndex, offsetBy: matchRange.length)
            var mentionText = String(text[startIndex..<endIndex])

            // Clean up the mention text
            mentionText = cleanMentionText(mentionText)

            // Skip if mention is just "@" or empty after cleaning
            guard mentionText.count > 1 else { return }

            // Simple type detection based on common patterns
            guard let type = detectMentionType(mentionText) else { return } // Skip invalid mentions
            let mention = Mention(text: mentionText, type: type, range: matchRange)
            mentions.append(mention)
        }

        return mentions
    }

    private func cleanMentionText(_ mention: String) -> String {
        var cleaned = mention

        // Remove trailing punctuation except hyphens (for hyphenated names)
        let trailingPunctuation = CharacterSet.punctuationCharacters.subtracting(CharacterSet(charactersIn: "-"))
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines.union(trailingPunctuation))

        // Remove trailing words that look like message continuation
        let words = cleaned.components(separatedBy: .whitespaces)
        if words.count > 3 {
            // If more than 3 words, likely includes message text - keep only first 2-3 words
            cleaned = words.prefix(2).joined(separator: " ")
        }

        return cleaned
    }
    
    private func detectMentionType(_ mention: String) -> MentionType? {
        let cleanMention = mention.replacingOccurrences(of: "@", with: "")

        // Check source-based detection first
        if appleMapsPlaces.contains(cleanMention) {
            return .place
        }

        if contactPeople.contains(cleanMention) {
            return .person
        }

        // Only allow contacts as people mentions - return nil for unknown mentions
        return nil
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