import SwiftUI

struct TestView: View {
    @State private var text = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Keyboard Test")
                .font(.title)
            
            TextField("Test input", text: $text)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            Text("You typed: \(text)")
        }
        .padding()
    }
}

#Preview {
    TestView()
}