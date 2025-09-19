import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var listViewModel = ListViewModel()
    @StateObject private var chatViewModel = ChatViewModel()
    @State private var showingContactPicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Debug info at top
            VStack {
                Text("✅ Successfully Authenticated!")
                    .font(.headline)
                    .foregroundColor(.green)
                Text("User: \(authManager.userName ?? "none")")
                    .font(.caption)
                Text("Email: \(authManager.userEmail ?? "none")")
                    .font(.caption)
                Text("Supabase Status: \(authManager.userEmail == "test@example.com" ? "❌ Failed (using bypass)" : "✅ Working")")
                    .font(.caption)
                    .foregroundColor(authManager.userEmail == "test@example.com" ? .red : .green)
                
                if let error = authManager.lastError {
                    Text("Error: \(error)")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            
            TabView {
            NavigationView {
                ChatViewWithList()
                    .environmentObject(listViewModel)
                    .environmentObject(chatViewModel)
                    .navigationTitle("Messages")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                showingContactPicker = true
                            }) {
                                Image(systemName: "person.badge.plus")
                            }
                        }
                    }
                    .sheet(isPresented: $showingContactPicker) {
                        ContactPickerView(isPresented: $showingContactPicker) { contactName in
                            listViewModel.addPerson(contactName)
                        }
                    }
            }
            .tabItem {
                Image(systemName: "message.fill")
                Text("Messages")
            }
            
            NavigationView {
                ListView()
                    .environmentObject(listViewModel)
                    .environmentObject(chatViewModel)
                    .navigationTitle("Lists")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Sign Out") {
                                authManager.signOut()
                            }
                        }
                    }
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Lists")
            }
        }
        }
        .onAppear {
            // Clear messages on each app launch but keep Lists data
            chatViewModel.clearMessages()
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager())
}