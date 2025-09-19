import SwiftUI
import AuthenticationServices
import Combine

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.colorScheme) var colorScheme
    @State private var debugMessage = "Ready to sign in"
    @State private var tapCount = 0
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "message.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Personal Assistant")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your AI-powered life manager")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 20) {
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        debugMessage = "Apple button tapped - processing..."
                        tapCount += 1
                        authManager.handleSignInWithAppleRequest(request)
                    },
                    onCompletion: { result in
                        debugMessage = "Sign in completed - check result"
                        authManager.handleSignInWithAppleCompletion(result)
                    }
                )
                .signInWithAppleButtonStyle(
                    colorScheme == .dark ? .white : .black
                )
                .frame(height: 50)
                .cornerRadius(8)

                // Bypass button for development
                Button(action: {
                    debugMessage = "Bypassing authentication..."
                    authManager.bypassAuthentication()
                }) {
                    Text("Skip Sign In (Dev)")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
                
                // Debug info
                VStack {
                    Text("Debug: \(debugMessage)")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("Taps: \(tapCount) | Auth: \(authManager.isAuthenticated ? "✅" : "❌")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("User: \(authManager.userName ?? "none") | Email: \(authManager.userEmail ?? "none")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                Text("Sign in to sync across devices and backup your data")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
        .background(
            LinearGradient(
                colors: [
                    Color(UIColor.systemBackground),
                    Color(UIColor.secondarySystemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager())
}