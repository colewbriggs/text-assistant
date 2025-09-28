import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var listViewModel = ListViewModel()
    @StateObject private var chatViewModel = ChatViewModel()
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar with settings
            TopBarView(showingSettings: $showingSettings)

            TabView {
            NavigationView {
                ChatViewWithList()
                    .environmentObject(listViewModel)
                    .environmentObject(chatViewModel)
                    .navigationTitle("Add Entry")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Image(systemName: "plus.circle.fill")
                Text("Add Entry")
            }
            
            NavigationView {
                ListView()
                    .environmentObject(listViewModel)
                    .environmentObject(chatViewModel)
                    .navigationTitle("People")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Image(systemName: "person.2.fill")
                Text("People")
            }

            NavigationView {
                LocationsView()
                    .environmentObject(listViewModel)
                    .navigationTitle("Locations")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Image(systemName: "location.fill")
                Text("Locations")
            }
        }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(isPresented: $showingSettings)
                .environmentObject(authManager)
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