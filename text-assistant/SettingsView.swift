import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    HStack {
                        Text("User")
                        Spacer()
                        Text(authManager.userName ?? "Unknown")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Email")
                        Spacer()
                        Text(authManager.userEmail ?? "Unknown")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Status")
                        Spacer()
                        Text(authManager.userEmail == "test@example.com" ? "Demo Mode" : "Connected")
                            .foregroundColor(authManager.userEmail == "test@example.com" ? .orange : .green)
                    }
                }

                Section("Actions") {
                    Button(action: {
                        authManager.signOut()
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                }

                if let error = authManager.lastError {
                    Section("Debug Info") {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView(isPresented: .constant(true))
        .environmentObject(AuthenticationManager())
}