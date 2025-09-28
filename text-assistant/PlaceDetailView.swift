import SwiftUI
import MapKit

struct PlaceDetailView: View {
    let place: Place
    let messages: [Message]
    @EnvironmentObject var viewModel: ListViewModel

    init(place: Place, messages: [Message] = []) {
        self.place = place
        self.messages = messages
    }

    var body: some View {
        List {
            // Map section
            if let coordinate = place.coordinate {
                Section {
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )), annotationItems: [place]) { place in
                        MapMarker(coordinate: coordinate, tint: .red)
                    }
                    .frame(height: 200)
                    .cornerRadius(8)
                } header: {
                    Text("Location")
                }
            }

            // Messages section
            Section {
                if messages.isEmpty {
                    Text("No mentions found")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    ForEach(messages) { message in
                        MessageRowView(message: message, highlightedName: place.name)
                    }
                    .onDelete(perform: deleteMessages)
                }
            } header: {
                Text("Messages")
            }
        }
        .navigationTitle(place.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func deleteMessages(offsets: IndexSet) {
        for index in offsets {
            let messageToDelete = messages[index]
            viewModel.deleteMessage(messageToDelete)
        }
    }
}

#Preview {
    NavigationView {
        PlaceDetailView(place: Place(name: "Starbucks"))
    }
}