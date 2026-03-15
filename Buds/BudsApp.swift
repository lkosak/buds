import SwiftData
import SwiftUI

@main
struct BudsApp: App {
    var body: some Scene {
        WindowGroup {
            BudListView()
        }
        .modelContainer(for: Bud.self)
    }
}
