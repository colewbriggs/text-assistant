import SwiftUI

struct ChatViewWithList: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var listViewModel: ListViewModel
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chatViewModel.messages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: chatViewModel.messages.count) { _, _ in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if let lastMessage = chatViewModel.messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input area
            VStack(spacing: 0) {
                // Autocomplete suggestions
                if !chatViewModel.suggestions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(chatViewModel.suggestions, id: \.self) { suggestion in
                                Button(action: {
                                    insertSuggestion(suggestion)
                                }) {
                                    Text(suggestion)
                                        .font(.system(size: 14))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(15)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                }
                
                // Message input
                HStack(alignment: .bottom, spacing: 12) {
                    TextField("Type a message with @mentions...", text: $messageText)
                        .textFieldStyle(.roundedBorder)
                        .focused($isInputFocused)
                        .onChange(of: messageText) { _, newValue in
                            updateSuggestions(for: newValue)
                        }
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(messageText.isEmpty ? .gray : .blue)
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Send to temporary chat (cleared on app launch)
        chatViewModel.sendMessage(messageText)

        // Also save to permanent CRM storage
        let mentions = chatViewModel.extractMentions(from: messageText)
        let message = Message(text: messageText, mentions: mentions)
        listViewModel.addMessageToCRM(message)

        messageText = ""
        chatViewModel.suggestions = []
    }
    
    private func insertSuggestion(_ suggestion: String) {
        if let lastAtIndex = messageText.lastIndex(of: "@") {
            let beforeAt = String(messageText[..<lastAtIndex])
            messageText = beforeAt + suggestion + " "
            chatViewModel.suggestions = []
        }
    }
    
    private func updateSuggestions(for input: String) {
        if let lastAtIndex = input.lastIndex(of: "@") {
            let afterAt = String(input[input.index(after: lastAtIndex)...])
            
            if !afterAt.contains(" ") {
                // Combine suggestions from people and projects
                var suggestions: [String] = []
                
                // Add people suggestions
                suggestions += listViewModel.people
                    .map { "@" + $0.name }
                    .filter { $0.lowercased().contains(("@" + afterAt).lowercased()) }
                
                // Add project suggestions
                suggestions += listViewModel.projects
                    .map { "@" + $0.name }
                    .filter { $0.lowercased().contains(("@" + afterAt).lowercased()) }
                
                chatViewModel.suggestions = Array(suggestions.prefix(5))
            } else {
                chatViewModel.suggestions = []
            }
        } else {
            chatViewModel.suggestions = []
        }
    }
}

#Preview {
    ChatViewWithList()
        .environmentObject(ListViewModel())
        .environmentObject(ChatViewModel())
}