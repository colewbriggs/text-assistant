import Foundation
import Combine

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

struct Project: Identifiable, Codable {
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


class ListViewModel: ObservableObject {
    @Published var people: [Person] = []
    @Published var projects: [Project] = []
    @Published var crmMessages: [Message] = [] // Permanent CRM message history

    private let userDefaults = UserDefaults.standard
    private let peopleKey = "saved_people"
    private let projectsKey = "saved_projects"
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

    func deleteProject(_ project: Project) {
        // Remove project from projects array
        projects.removeAll { $0.id == project.id }

        // Remove all CRM messages that only mention this project
        crmMessages.removeAll { message in
            let mentionsOnlyThisProject = message.mentions.allSatisfy { mention in
                mention.type == .project && mention.text.replacingOccurrences(of: "@", with: "").lowercased() == project.name.lowercased()
            }
            return mentionsOnlyThisProject
        }

        saveData()
        print("Deleted project: \(project.name)")
    }
    
    func addPerson(_ name: String) {
        let person = Person(name: name)
        people.append(person)
        saveData()
    }
    
    func addProject(_ name: String) {
        let project = Project(name: name)
        projects.append(project)
        saveData()
    }
    
    func addMessageToCRM(_ message: Message) {
        // Store message permanently for CRM
        crmMessages.append(message)

        // Update people/projects without incrementing counters manually
        for mention in message.mentions {
            addPersonOrProjectIfNeeded(for: mention.text, type: mention.type)
        }

        // Recalculate all counters from actual message count
        updateCountersFromMessages()

        saveData()
    }

    private func addPersonOrProjectIfNeeded(for mentionText: String, type: MentionType) {
        let cleanName = mentionText.replacingOccurrences(of: "@", with: "")

        switch type {
        case .person:
            if !people.contains(where: { $0.name.lowercased() == cleanName.lowercased() }) {
                people.append(Person(name: cleanName))
            }
        case .project:
            if !projects.contains(where: { $0.name.lowercased() == cleanName.lowercased() }) {
                projects.append(Project(name: cleanName))
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

        for i in 0..<projects.count {
            let messagesForProject = getMessagesForProject(projects[i].name)
            projects[i].messageCount = messagesForProject.count
            projects[i].lastMentioned = messagesForProject.first?.timestamp
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
        case .project:
            if let index = projects.firstIndex(where: { $0.name.lowercased() == cleanName.lowercased() }) {
                projects[index].messageCount += 1
                projects[index].lastMentioned = Date()
            } else {
                var newProject = Project(name: cleanName)
                newProject.messageCount = 1
                newProject.lastMentioned = Date()
                projects.append(newProject)
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

    func getMessagesForProject(_ projectName: String) -> [Message] {
        return crmMessages.filter { message in
            message.mentions.contains { mention in
                mention.type == .project && mention.text.replacingOccurrences(of: "@", with: "").lowercased() == projectName.lowercased()
            }
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    
    private func saveData() {
        if let peopleData = try? JSONEncoder().encode(people) {
            userDefaults.set(peopleData, forKey: peopleKey)
        }
        if let projectsData = try? JSONEncoder().encode(projects) {
            userDefaults.set(projectsData, forKey: projectsKey)
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

        if let projectsData = userDefaults.data(forKey: projectsKey),
           let decodedProjects = try? JSONDecoder().decode([Project].self, from: projectsData) {
            projects = decodedProjects
        }

        if let crmMessagesData = userDefaults.data(forKey: crmMessagesKey),
           let decodedMessages = try? JSONDecoder().decode([Message].self, from: crmMessagesData) {
            crmMessages = decodedMessages
        }
    }
}