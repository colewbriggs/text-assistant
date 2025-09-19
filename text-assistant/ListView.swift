import SwiftUI

struct ListView: View {
    @EnvironmentObject var viewModel: ListViewModel

    var body: some View {
        List {
            Section("People") {
                if viewModel.people.isEmpty {
                    Text("No people mentioned yet")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    ForEach(viewModel.people) { person in
                        NavigationLink(destination: PersonDetailView(person: person, messages: viewModel.getMessagesForPerson(person.name))) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 20)
                                Text(person.name)
                                Spacer()
                                Text("\(person.messageCount)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deletePerson(viewModel.people[index])
                        }
                    }
                }
            }
            
            Section("Projects") {
                if viewModel.projects.isEmpty {
                    Text("No projects mentioned yet")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    ForEach(viewModel.projects) { project in
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.green)
                                .frame(width: 20)
                            Text(project.name)
                            Spacer()
                            Text("\(project.messageCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deleteProject(viewModel.projects[index])
                        }
                    }
                }
            }
        }
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView()
            .environmentObject(ListViewModel())
    }
}