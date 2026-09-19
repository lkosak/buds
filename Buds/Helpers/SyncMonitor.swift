import CloudKit
import CoreData
import Observation

/// Tracks CloudKit sync activity from SwiftData's underlying NSPersistentCloudKitContainer
/// so failures are visible in Settings instead of silently leaving data on one device.
@MainActor
@Observable
final class SyncMonitor {
    static let shared = SyncMonitor()

    enum AccountState {
        case unknown, available, unavailable(String)
    }

    private(set) var accountState: AccountState = .unknown
    private(set) var isSyncing = false
    private(set) var lastSuccess: Date?
    private(set) var lastError: String?

    private var inProgress = Set<UUID>()
    private var started = false

    private init() {}

    func start() {
        guard !started else { return }
        started = true

        Task {
            for await note in NotificationCenter.default.notifications(named: NSPersistentCloudKitContainer.eventChangedNotification) {
                guard let event = note.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event else { continue }
                handle(event)
            }
        }
        Task {
            for await _ in NotificationCenter.default.notifications(named: .CKAccountChanged) {
                await refreshAccountStatus()
            }
        }
        Task { await refreshAccountStatus() }
    }

    private func handle(_ event: NSPersistentCloudKitContainer.Event) {
        guard let endDate = event.endDate else {
            inProgress.insert(event.identifier)
            isSyncing = true
            return
        }
        inProgress.remove(event.identifier)
        isSyncing = !inProgress.isEmpty
        if event.succeeded {
            lastSuccess = endDate
            lastError = nil
        } else if let error = event.error {
            lastError = Self.describe(error)
        }
    }

    private func refreshAccountStatus() async {
        do {
            switch try await CKContainer(identifier: "iCloud.io.lou.app").accountStatus() {
            case .available: accountState = .available
            case .noAccount: accountState = .unavailable("Not signed in to iCloud")
            case .restricted: accountState = .unavailable("iCloud is restricted")
            case .temporarilyUnavailable: accountState = .unavailable("iCloud is temporarily unavailable")
            case .couldNotDetermine: accountState = .unknown
            @unknown default: accountState = .unknown
            }
        } catch {
            accountState = .unavailable(Self.describe(error))
        }
    }

    private static func describe(_ error: Error) -> String {
        if let ckError = error as? CKError, let partial = ckError.partialErrorsByItemID?.values.first {
            return describe(partial)
        }
        return (error as NSError).localizedFailureReason ?? error.localizedDescription
    }
}
