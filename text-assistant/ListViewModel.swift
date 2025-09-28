import Foundation
import Combine
import CoreLocation

struct Person: Identifiable, Codable {
    var id = UUID()
    let name: String
    var messageCount: Int = 0
    var lastMentioned: Date?
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.messageCount = 0
        self.lastMentioned = nil
    }
}


struct Place: Identifiable, Codable {
    var id = UUID()
    let name: String
    var messageCount: Int = 0
    var lastMentioned: Date?
    let latitude: Double?
    let longitude: Double?

    init(name: String, latitude: Double? = nil, longitude: Double? = nil) {
        self.id = UUID()
        self.name = name
        self.messageCount = 0
        self.lastMentioned = nil
        self.latitude = latitude
        self.longitude = longitude
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}


class ListViewModel: ObservableObject {
    @Published var people: [Person] = []
    @Published var places: [Place] = []
    @Published var crmMessages: [Message] = [] // Permanent CRM message history

    private let supabaseService = SimpleSupabaseService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadData()

        // Listen for authentication changes and reload data
        supabaseService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuth in
                if isAuth {
                    self?.loadData()
                }
            }
            .store(in: &cancellables)
    }

    func deletePerson(_ person: Person) {
        // Remove person from people array
        people.removeAll { $0.id == person.id }

        // Remove all CRM messages that only mention this person
        // (Keep messages that mention other people/projects too)
        crmMessages.removeAll { message in
            let mentionsOnlyThisPerson = message.mentions.allSatisfy { mention in
                mention.type == .person && mention.text.replacingOccurrences(of: "@", with: "").lowercased() == person.name.lowercased()
            }
            return mentionsOnlyThisPerson
        }

        print("Deleted person: \(person.name)")
    }

    func deletePlace(_ place: Place) {
        // Remove place from places array
        places.removeAll { $0.id == place.id }

        // Remove all CRM messages that only mention this place
        crmMessages.removeAll { message in
            let mentionsOnlyThisPlace = message.mentions.allSatisfy { mention in
                mention.type == .place && mention.text.replacingOccurrences(of: "@", with: "").lowercased() == place.name.lowercased()
            }
            return mentionsOnlyThisPlace
        }

        print("Deleted place: \(place.name)")
    }

    func deleteMessage(_ message: Message) {
        Task {
            do {
                try await supabaseService.deleteMessage(message.id)
                await MainActor.run {
                    crmMessages.removeAll { $0.id == message.id }
                    updateCountersFromMessages()
                }
                print("Deleted message: \(message.text)")
            } catch {
                print("Error deleting message: \(error)")
            }
        }
    }

    func addPerson(_ name: String) {
        let person = Person(name: name)
        people.append(person)
    }
    
    
    func addMessageToCRM(_ message: Message, placeCoordinates: [String: PlaceSearchResult] = [:]) {
        print("💾 Adding message to CRM: '\(message.text)'")
        print("💾 Message mentions: \(message.mentions.map { "\($0.text) (\($0.type))" })")

        Task {
            do {
                // Save to Supabase
                try await supabaseService.saveMessage(message)
                print("✅ Message saved to Supabase successfully")

                await MainActor.run {
                    // Store message locally for immediate UI update
                    crmMessages.append(message)
                    print("📱 Message added to local array. Total messages: \(crmMessages.count)")

                    // Update people/places without incrementing counters manually
                    for mention in message.mentions {
                        print("🔍 Processing mention: \(mention.text) (\(mention.type))")
                        if mention.type == .place, let placeResult = placeCoordinates[mention.text.replacingOccurrences(of: "@", with: "")] {
                            addPlaceWithCoordinates(name: mention.text, coordinate: placeResult.coordinate)
                        } else {
                            addPersonOrPlaceIfNeeded(for: mention.text, type: mention.type)
                        }
                    }

                    // Recalculate all counters from actual message count
                    updateCountersFromMessages()
                    print("👥 After adding message - People count: \(people.count)")
                    print("👥 People: \(people.map { $0.name })")
                }
            } catch {
                print("💥 Error saving message to Supabase: \(error)")
            }
        }
    }

    private func addPlaceWithCoordinates(name: String, coordinate: CLLocationCoordinate2D) {
        let cleanName = name.replacingOccurrences(of: "@", with: "")

        if !places.contains(where: { $0.name.lowercased() == cleanName.lowercased() }) {
            places.append(Place(name: cleanName, latitude: coordinate.latitude, longitude: coordinate.longitude))
        }
    }

    private func addPersonOrPlaceIfNeeded(for mentionText: String, type: MentionType) {
        let cleanName = mentionText.replacingOccurrences(of: "@", with: "")

        switch type {
        case .person:
            if !people.contains(where: { $0.name.lowercased() == cleanName.lowercased() }) {
                people.append(Person(name: cleanName))
            }
        case .place:
            if !places.contains(where: { $0.name.lowercased() == cleanName.lowercased() }) {
                places.append(Place(name: cleanName))
            }
        }
    }

    private func updateCountersFromMessages() {
        // Reset all counters and recalculate from actual messages
        for i in 0..<people.count {
            let messagesForPerson = getMessagesForPerson(people[i].name)
            people[i].messageCount = messagesForPerson.count
            people[i].lastMentioned = messagesForPerson.first?.timestamp
        }


        for i in 0..<places.count {
            let messagesForPlace = getMessagesForPlace(places[i].name)
            places[i].messageCount = messagesForPlace.count
            places[i].lastMentioned = messagesForPlace.first?.timestamp
        }
    }

    func incrementMentionCount(for mentionText: String, type: MentionType) {
        let cleanName = mentionText.replacingOccurrences(of: "@", with: "")

        switch type {
        case .person:
            if let index = people.firstIndex(where: { $0.name.lowercased() == cleanName.lowercased() }) {
                people[index].messageCount += 1
                people[index].lastMentioned = Date()
            } else {
                var newPerson = Person(name: cleanName)
                newPerson.messageCount = 1
                newPerson.lastMentioned = Date()
                people.append(newPerson)
            }
        case .place:
            if let index = places.firstIndex(where: { $0.name.lowercased() == cleanName.lowercased() }) {
                places[index].messageCount += 1
                places[index].lastMentioned = Date()
            } else {
                var newPlace = Place(name: cleanName)
                newPlace.messageCount = 1
                newPlace.lastMentioned = Date()
                places.append(newPlace)
            }
        }

    }

    func getMessagesForPerson(_ personName: String) -> [Message] {
        return crmMessages.filter { message in
            message.mentions.contains { mention in
                mention.text.replacingOccurrences(of: "@", with: "").lowercased() == personName.lowercased()
            }
        }.sorted { $0.timestamp > $1.timestamp }
    }


    func getMessagesForPlace(_ placeName: String) -> [Message] {
        return crmMessages.filter { message in
            message.mentions.contains { mention in
                mention.type == .place && mention.text.replacingOccurrences(of: "@", with: "").lowercased() == placeName.lowercased()
            }
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    
    
    private func loadData() {
        print("🔄 ListViewModel.loadData() called")
        print("🔐 Authentication status: \(supabaseService.isAuthenticated)")
        print("👤 Current user ID: \(supabaseService.currentUserId ?? "nil")")

        Task {
            do {
                if supabaseService.isAuthenticated {
                    let messages = try await supabaseService.loadMessages()
                    await MainActor.run {
                        crmMessages = messages
                        print("📝 Loaded \(messages.count) messages from Supabase")
                        print("📝 Messages: \(messages.map { "\($0.text) - mentions: \($0.mentions.count)" })")
                        rebuildPeopleAndPlacesFromMessages()
                        print("👥 After rebuild - People count: \(people.count)")
                        print("👥 People: \(people.map { $0.name })")
                    }
                } else {
                    print("❌ Not authenticated, skipping Supabase data load")
                }
            } catch {
                print("💥 Error loading data from Supabase: \(error)")
            }
        }
    }

    private func rebuildPeopleAndPlacesFromMessages() {
        people = []
        places = []

        for message in crmMessages {
            for mention in message.mentions {
                let cleanName = mention.text.replacingOccurrences(of: "@", with: "")

                switch mention.type {
                case .person:
                    if !people.contains(where: { $0.name.lowercased() == cleanName.lowercased() }) {
                        people.append(Person(name: cleanName))
                    }
                case .place:
                    if !places.contains(where: { $0.name.lowercased() == cleanName.lowercased() }) {
                        places.append(Place(name: cleanName))
                    }
                }
            }
        }

        updateCountersFromMessages()
    }

    func refreshData() {
        loadData()
    }
}