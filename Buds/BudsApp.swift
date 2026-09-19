import CoreData
import SwiftData
import SwiftUI
import UserNotifications

@main
struct BudsApp: App {
    var container: ModelContainer
    @Environment(\.scenePhase) private var scenePhase

    init() {
        SyncMonitor.shared.start()
        let config = ModelConfiguration("Buds", cloudKitDatabase: .automatic)
        #if DEBUG
        if CommandLine.arguments.contains("-initCloudKitSchema") {
            Self.initializeCloudKitSchema(storeURL: config.url)
        }
        #endif
        container = try! ModelContainer(for: Bud.self, ContactInteraction.self, Event.self, configurations: config)
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
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
        .modelContainer(container)
    }

    #if DEBUG
    /// Pushes the full SwiftData schema to the CloudKit Development environment so it can be
    /// deployed to Production. Run a debug build with the `-initCloudKitSchema` launch argument.
    private static func initializeCloudKitSchema(storeURL: URL) {
        autoreleasepool {
            let description = NSPersistentStoreDescription(url: storeURL)
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.io.lou.app")
            description.shouldAddStoreAsynchronously = false
            guard let model = NSManagedObjectModel.makeManagedObjectModel(for: [Bud.self, ContactInteraction.self, Event.self]) else {
                fatalError("Couldn't build managed object model")
            }
            let container = NSPersistentCloudKitContainer(name: "Buds", managedObjectModel: model)
            container.persistentStoreDescriptions = [description]
            container.loadPersistentStores { _, error in
                if let error { fatalError("Loading store for schema init failed: \(error)") }
            }
            do {
                try container.initializeCloudKitSchema()
                print("✅ CloudKit schema initialized")
            } catch {
                fatalError("initializeCloudKitSchema failed: \(error)")
            }
            if let store = container.persistentStoreCoordinator.persistentStores.first {
                try? container.persistentStoreCoordinator.remove(store)
            }
        }
    }
    #endif
}
