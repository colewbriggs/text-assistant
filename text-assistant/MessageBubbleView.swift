import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                // Message text with highlighted mentions
                Text(attributedText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(18)
                
                // Show parsed mentions below if any
                if !message.mentions.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Detected mentions:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            ForEach(message.mentions) { mention in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(colorForMentionType(mention.type))
                                        .frame(width: 8, height: 8)
                                    Text(mention.text)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(colorForMentionType(mention.type).opacity(0.2))
                                        .cornerRadius(10)
                                }
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Timestamp
                Text(formatTimestamp(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
            }
            Spacer()
        }
    }
    
    private var attributedText: AttributedString {
        var attributed = AttributedString(message.text)
        
        // Highlight @ mentions in the text
        for mention in message.mentions {
            let startIndex = message.text.index(message.text.startIndex, offsetBy: mention.range.location)
            let endIndex = message.text.index(startIndex, offsetBy: mention.range.length)
            
            if let attributedRange = Range(startIndex..<endIndex, in: attributed) {
                attributed[attributedRange].font = .boldSystemFont(ofSize: 16)
            }
        }
        
        return attributed
    }
    
    private func colorForMentionType(_ type: MentionType) -> Color {
        switch type {
        case .person: return .blue
        case .project: return .green
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    let sampleMentions = [
        Mention(text: "@john", type: .person, range: NSRange(location: 13, length: 5)),
        Mention(text: "@project-alpha", type: .project, range: NSRange(location: 29, length: 14))
    ]
    
    let sampleMessage = Message(text: "Meeting with @john about @project-alpha", mentions: sampleMentions)
    
    return MessageBubbleView(message: sampleMessage)
        .padding()
}