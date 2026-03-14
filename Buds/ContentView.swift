import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "🌱")
                .font(.system(size: 64))
            Text("Buds")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Hello from TestFlight!")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
