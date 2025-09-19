import SwiftUI

struct SimpleChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""
    
    var body: some View {
        VStack {
            // Messages
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.messages) { message in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(message.text)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                
                                if !message.mentions.isEmpty {
                                    Text("Mentions: \(message.mentions.map(\.text).joined(separator: ", "))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            // Simple input
            HStack {
                TextField("Type message...", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                
                Button("Send") {
                    sendMessage()
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        viewModel.sendMessage(messageText)
        messageText = ""
    }
}

#Preview {
    SimpleChatView()
}