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
                        NavigationLink(destination: PersonDetailView(person: person, messages: viewModel.getMessagesForPerson(person.name)).environmentObject(viewModel)) {
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

            
        }
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView()
            .environmentObject(ListViewModel())
    }
}