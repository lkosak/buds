import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Buds", systemImage: "person.2.fill") {
                NavigationStack {
                    BudListView()
                }
            }
            Tab("Events", systemImage: "calendar") {
                NavigationStack {
                    Text("Events coming soon")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
