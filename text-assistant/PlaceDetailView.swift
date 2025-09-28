import SwiftUI
import MapKit

struct PlaceDetailView: View {
    let place: Place
    let messages: [Message]

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
                }
            } header: {
                Text("Messages")
            }
        }
        .navigationTitle(place.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        PlaceDetailView(place: Place(name: "Starbucks"))
    }
}