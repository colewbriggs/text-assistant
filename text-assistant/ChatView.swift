import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if let lastMessage = viewModel.messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input area
            VStack(spacing: 0) {
                // Autocomplete suggestions
                if !viewModel.suggestions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.suggestions, id: \.self) { suggestion in
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
                            viewModel.updateSuggestions(for: newValue)
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
        
        viewModel.sendMessage(messageText)
        messageText = ""
        viewModel.suggestions = []
    }
    
    private func insertSuggestion(_ suggestion: String) {
        if let lastAtIndex = messageText.lastIndex(of: "@") {
            let beforeAt = String(messageText[..<lastAtIndex])
            messageText = beforeAt + suggestion + " "
            viewModel.suggestions = []
        }
    }
}

#Preview {
    ChatView()
}