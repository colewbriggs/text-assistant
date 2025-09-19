//
//  text_assistantApp.swift
//  text-assistant
//
//  Created by Cole Briggs on 9/9/25.
//

import SwiftUI
import Combine

@main
struct text_assistantApp: App {
    @StateObject private var authManager = AuthenticationManager()
    
    init() {
        print("🚀 App starting up - console is working!")
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}

struct MainAppView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationView {
            VStack {
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
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .padding()
                
                ChatView()
            }
            .navigationTitle("Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out") {
                        authManager.signOut()
                    }
                }
            }
        }
    }
}
