import SwiftUI

struct LocationsView: View {
    @EnvironmentObject var viewModel: ListViewModel

    var body: some View {
        List {
            if viewModel.places.isEmpty {
                Text("No locations mentioned yet")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                ForEach(viewModel.places) { place in
                    NavigationLink(destination: PlaceDetailView(place: place, messages: viewModel.getMessagesForPlace(place.name)).environmentObject(viewModel)) {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.red)
                                .frame(width: 20)
                            Text(place.name)
                            Spacer()
                            Text("\(place.messageCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deletePlace(viewModel.places[index])
                    }
                }
            }
        }
    }
}

#Preview {
    LocationsView()
        .environmentObject(ListViewModel())
}