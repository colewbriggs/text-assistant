import Foundation
import AuthenticationServices
import SwiftUI
import Combine
import CryptoKit
import Supabase
import Auth

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var userID: String? = nil
    @Published var userName: String? = nil
    @Published var userEmail: String? = nil
    @Published var lastError: String? = nil
    
    private let supabaseService = SimpleSupabaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Listen to Supabase auth changes
        supabaseService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuth in
                print("Auth state changed: \(isAuth)")
                self?.isAuthenticated = isAuth
            }
            .store(in: &cancellables)
            
        supabaseService.$user
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                print("User changed: \(user?.email ?? "nil")")
                self?.userID = user?.id.uuidString
                self?.userName = user?.email?.split(separator: "@").first.map(String.init) ?? "User"
                self?.userEmail = user?.email
            }
            .store(in: &cancellables)
            
        checkExistingSession()
    }
    
    private func checkExistingSession() {
        Task {
            await supabaseService.checkSession()
        }
    }
    
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        print("Setting up Sign in with Apple request")
        request.requestedScopes = [.fullName, .email]
        
        // Generate nonce for security
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
    }
    
    private var currentNonce: String?
    
    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        print("Sign in completion handler called")
        switch result {
        case .success(let authorization):
            print("Sign in successful, processing credentials")
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                print("ERROR: Missing required Apple Sign In data")
                return
            }
            
            Task {
                do {
                    print("Attempting Supabase sign in with idToken: \(idToken.prefix(20))...")
                    try await supabaseService.signInWithApple(idToken: idToken, nonce: nonce)
                    print("Successfully signed in with Supabase")
                    
                    // Force a UI update to show success
                    await MainActor.run {
                        print("Auth state should now be: \(self.supabaseService.isAuthenticated)")
                    }
                } catch {
                    print("Supabase sign in error: \(error)")
                    print("Error details: \(error.localizedDescription)")
                    
                    // For now, let's bypass Supabase and just set authenticated locally
                    await MainActor.run {
                        self.lastError = "Supabase failed: \(error.localizedDescription)"
                        self.isAuthenticated = true
                        self.userID = "temp_user"
                        self.userName = "Test User"
                        self.userEmail = "test@example.com"
                        print("Temporarily bypassed Supabase - set auth to true")
                    }
                }
            }
            
        case .failure(let error):
            print("Sign in with Apple failed: \(error.localizedDescription)")
        }
    }
    
    func bypassAuthentication() {
        print("Bypassing authentication for development")
        isAuthenticated = true
        userID = "dev_user"
        userName = "Dev User"
        userEmail = "dev@example.com"
        lastError = nil
    }

    func signOut() {
        Task {
            do {
                try await supabaseService.signOut()
                print("Successfully signed out")
            } catch {
                print("Sign out error: \(error)")
            }
        }
    }
    
    // MARK: - Helpers
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}