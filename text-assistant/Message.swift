import Foundation

struct Message: Identifiable, Codable {
    var id = UUID()
    let text: String
    let timestamp: Date
    let mentions: [Mention]
    
    init(text: String, mentions: [Mention] = []) {
        self.id = UUID()
        self.text = text
        self.timestamp = Date()
        self.mentions = mentions
    }

    init(id: UUID, text: String, timestamp: Date, mentions: [Mention]) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.mentions = mentions
    }
}

struct Mention: Identifiable, Codable {
    var id = UUID()
    let text: String
    let type: MentionType
    let range: NSRange
    
    init(text: String, type: MentionType, range: NSRange) {
        self.id = UUID()
        self.text = text
        self.type = type
        self.range = range
    }
}

enum MentionType: String, CaseIterable, Codable {
    case person = "person"
    case place = "place"

    var color: String {
        switch self {
        case .person: return "blue"
        case .place: return "red"
        }
    }

    var icon: String {
        switch self {
        case .person: return "person.fill"
        case .place: return "location.fill"
        }
    }
}