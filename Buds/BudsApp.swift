import SwiftData
import SwiftUI
import UserNotifications

@main
struct BudsApp: App {
    var container: ModelContainer
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let config = ModelConfiguration("Buds", cloudKitDatabase: .automatic)
        container = try! ModelContainer(for: Bud.self, ContactInteraction.self, Event.self, configurations: config)
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
        .task {
            await NotificationScheduler.shared.requestPermission()
            await rescheduleAllNotifications(context: container.mainContext)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await rescheduleAllNotifications(context: container.mainContext)
                }
            }
        }
    }
}
