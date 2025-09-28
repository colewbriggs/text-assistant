import Foundation
import Supabase
import Auth
import Combine

@MainActor
class SimpleSupabaseService: ObservableObject {
    static let shared = SimpleSupabaseService()
    
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://hhfrjzypqunwalpfujeb.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhoZnJqenlwcXVud2FscGZ1amViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc0MTMwNjcsImV4cCI6MjA3Mjk4OTA2N30.e3d2YvVijLjaLMce90t4qo1xkW2DqLEvhC3YAAwMmLI"
    )
    
    @Published var isAuthenticated = false
    @Published var user: User?
    
    private init() {}
    
    func signInWithApple(idToken: String, nonce: String) async throws {
        print("🔄 Starting Supabase sign in...")
        
        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
        
        print("✅ Supabase sign in successful")
        print("📧 User email: \(session.user.email ?? "nil")")
        
        await MainActor.run {
            self.user = session.user
            self.isAuthenticated = true
            print("🔄 Updated auth state: \(self.isAuthenticated)")
        }
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
        self.user = nil
        self.isAuthenticated = false
    }
    
    func checkSession() async {
        print("🔍 Checking existing Supabase session...")
        do {
            let session = try await supabase.auth.session
            print("✅ Found existing session")
            await MainActor.run {
                self.user = session.user
                self.isAuthenticated = true
            }
        } catch {
            print("❌ No existing session: \(error)")
            await MainActor.run {
                self.isAuthenticated = false
            }
        }
    }

    func setBypassMode() {
        isAuthenticated = true
    }
}

enum SimpleSupabaseError: Error {
    case notAuthenticated
}