import SwiftData
import SwiftUI

@main
struct BudsApp: App {
    var container: ModelContainer

    init() {
        let config = ModelConfiguration("Buds", cloudKitDatabase: .automatic)
        container = try! ModelContainer(for: Bud.self, ContactInteraction.self, Event.self, configurations: config)
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }
}
