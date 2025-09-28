import SwiftUI

struct TopBarView: View {
    @Binding var showingSettings: Bool

    var body: some View {
        HStack {
            Text("Text Assistant")
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "gearshape")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
        .shadow(radius: 1, y: 1)
    }
}

#Preview {
    TopBarView(showingSettings: .constant(false))
}