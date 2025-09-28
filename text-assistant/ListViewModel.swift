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

    private let userDefaults = UserDefaults.standard
    private let peopleKey = "saved_people"
    private let placesKey = "saved_places"
    private let crmMessagesKey = "crm_messages"
    
    init() {
        loadData()
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

        saveData()
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

        saveData()
        print("Deleted place: \(place.name)")
    }

    func addPerson(_ name: String) {
        let person = Person(name: name)
        people.append(person)
        saveData()
    }
    
    
    func addMessageToCRM(_ message: Message, placeCoordinates: [String: PlaceSearchResult] = [:]) {
        // Store message permanently for CRM
        crmMessages.append(message)

        // Update people/places without incrementing counters manually
        for mention in message.mentions {
            if mention.type == .place, let placeResult = placeCoordinates[mention.text.replacingOccurrences(of: "@", with: "")] {
                addPlaceWithCoordinates(name: mention.text, coordinate: placeResult.coordinate)
            } else {
                addPersonOrPlaceIfNeeded(for: mention.text, type: mention.type)
            }
        }

        // Recalculate all counters from actual message count
        updateCountersFromMessages()

        saveData()
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

        saveData()
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
    
    
    private func saveData() {
        if let peopleData = try? JSONEncoder().encode(people) {
            userDefaults.set(peopleData, forKey: peopleKey)
        }
        if let placesData = try? JSONEncoder().encode(places) {
            userDefaults.set(placesData, forKey: placesKey)
        }
        if let crmMessagesData = try? JSONEncoder().encode(crmMessages) {
            userDefaults.set(crmMessagesData, forKey: crmMessagesKey)
        }
    }
    
    private func loadData() {
        if let peopleData = userDefaults.data(forKey: peopleKey),
           let decodedPeople = try? JSONDecoder().decode([Person].self, from: peopleData) {
            people = decodedPeople
        }


        if let placesData = userDefaults.data(forKey: placesKey),
           let decodedPlaces = try? JSONDecoder().decode([Place].self, from: placesData) {
            places = decodedPlaces
        }

        if let crmMessagesData = userDefaults.data(forKey: crmMessagesKey),
           let decodedMessages = try? JSONDecoder().decode([Message].self, from: crmMessagesData) {
            crmMessages = decodedMessages
        }
    }
}