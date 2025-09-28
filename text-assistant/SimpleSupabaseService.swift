import Foundation
import Combine

struct SimpleUser {
    let id: UUID
    let email: String?
}

struct MessageRecord: Codable {
    let id: String
    let user_id: String
    let text: String
    let timestamp: String
    let mentions: String
}

class SimpleSupabaseService: ObservableObject {
    static let shared = SimpleSupabaseService()

    private let baseURL = "https://hhfrjzypqunwalpfujeb.supabase.co"
    private let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhoZnJqenlwcXVud2FscGZ1amViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc0MTMwNjcsImV4cCI6MjA3Mjk4OTA2N30.e3d2YvVijLjaLMce90t4qo1xkW2DqLEvhC3YAAwMmLI"

    @Published var isAuthenticated = false
    @Published var currentUserId: String?
    @Published var user: SimpleUser?
    
    private init() {}

    func setAuthenticated(userId: String, email: String? = nil) {
        Task {
            await MainActor.run {
                self.currentUserId = userId
                self.isAuthenticated = true
                self.user = SimpleUser(id: UUID(), email: email ?? "apple@user.com")
            }
        }
    }

    func setBypassMode() {
        Task {
            await MainActor.run {
                self.currentUserId = "test_user"
                self.isAuthenticated = true
                self.user = SimpleUser(id: UUID(), email: "dev@example.com")
            }
        }
    }

    func checkSession() async {
        // For simplified auth, we don't need to check sessions
        // This is a no-op for compatibility
    }

    func signOut() async throws {
        await MainActor.run {
            self.currentUserId = nil
            self.isAuthenticated = false
            self.user = nil
        }
    }

    // MARK: - Database Operations

    func saveMessage(_ message: Message) async throws {
        guard let userId = currentUserId else {
            throw SimpleSupabaseError.notAuthenticated
        }

        let mentionsJSON = try JSONEncoder().encode(message.mentions)
        let mentionsString = String(data: mentionsJSON, encoding: .utf8) ?? "[]"

        let messageRecord = MessageRecord(
            id: message.id.uuidString,
            user_id: userId,
            text: message.text,
            timestamp: String(message.timestamp.timeIntervalSince1970),
            mentions: mentionsString
        )

        let urlString = "\(baseURL)/rest/v1/messages"
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let bearerToken = "Bearer \(apiKey)"
        request.setValue(bearerToken, forHTTPHeaderField: "Authorization")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")

        let jsonData = try JSONEncoder().encode(messageRecord)
        request.httpBody = jsonData

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SimpleSupabaseError.httpError(0)
        }

        print("Save response status: \(httpResponse.statusCode)")
        if httpResponse.statusCode >= 400 {
            throw SimpleSupabaseError.httpError(httpResponse.statusCode)
        }
    }

    func loadMessages() async throws -> [Message] {
        guard let userId = currentUserId else {
            throw SimpleSupabaseError.notAuthenticated
        }

        let urlString = "\(baseURL)/rest/v1/messages?user_id=eq.\(userId)&order=timestamp.desc"
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        let bearerToken = "Bearer \(apiKey)"
        request.setValue(bearerToken, forHTTPHeaderField: "Authorization")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SimpleSupabaseError.httpError(0)
        }

        print("Load response status: \(httpResponse.statusCode)")
        if httpResponse.statusCode >= 400 {
            throw SimpleSupabaseError.httpError(httpResponse.statusCode)
        }

        let messageRecords = try JSONDecoder().decode([MessageRecord].self, from: data)

        return messageRecords.compactMap { record -> Message? in
            guard let id = UUID(uuidString: record.id),
                  let timestamp = Double(record.timestamp),
                  let mentionsData = record.mentions.data(using: .utf8),
                  let mentions = try? JSONDecoder().decode([Mention].self, from: mentionsData) else {
                return nil
            }

            return Message(
                id: id,
                text: record.text,
                timestamp: Date(timeIntervalSince1970: timestamp),
                mentions: mentions
            )
        }
    }

    func deleteMessage(_ messageId: UUID) async throws {
        guard currentUserId != nil else {
            throw SimpleSupabaseError.notAuthenticated
        }

        let urlString = "\(baseURL)/rest/v1/messages?id=eq.\(messageId.uuidString)"
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let bearerToken = "Bearer \(apiKey)"
        request.setValue(bearerToken, forHTTPHeaderField: "Authorization")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SimpleSupabaseError.httpError(0)
        }

        print("Delete response status: \(httpResponse.statusCode)")
        if httpResponse.statusCode >= 400 {
            throw SimpleSupabaseError.httpError(httpResponse.statusCode)
        }
    }
}

enum SimpleSupabaseError: Error {
    case notAuthenticated
    case httpError(Int)
}