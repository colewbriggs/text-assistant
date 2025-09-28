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

        // Highlight @ mentions in the text with contrasting colors
        for mention in message.mentions {
            if let range = attributed.range(of: mention.text, options: .caseInsensitive) {
                attributed[range].font = .body.weight(.bold)
                // Use bright contrasting colors that show up on blue background
                attributed[range].foregroundColor = brightColorForMentionType(mention.type)
            }
        }

        return attributed
    }

    private func brightColorForMentionType(_ type: MentionType) -> Color {
        switch type {
        case .person: return .yellow     // Bright yellow for people
        case .place: return .orange      // Bright orange for places
        }
    }
    
    private func colorForMentionType(_ type: MentionType) -> Color {
        switch type {
        case .person: return .blue
        case .place: return .red
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
        Mention(text: "@starbucks", type: .place, range: NSRange(location: 29, length: 10))
    ]

    let sampleMessage = Message(text: "Meeting with @john at @starbucks", mentions: sampleMentions)

    MessageBubbleView(message: sampleMessage)
        .padding()
}