import Foundation
import SwiftData

struct BudsBackup: Codable {
    var version: Int = 1
    var exportDate: Date = Date()
    var buds: [BudExport]

    init(buds: [BudExport]) {
        self.buds = buds
    }

    struct BudExport: Codable {
        var contactID: String
        var name: String
        var lastContactDate: Date?
        var addedDate: Date
        var isPinned: Bool
        var isArchived: Bool
        var profileName: String
        var contactCadenceDays: Int
        var interactions: [InteractionExport]
        var events: [EventExport] = []

        struct InteractionExport: Codable {
            var date: Date
            var channelRaw: String?
            var note: String?
        }

        struct EventExport: Codable {
            var date: Date
            var note: String
        }
    }
}

@MainActor
func makeBackupData(context: ModelContext) throws -> Data {
    let buds = try context.fetch(FetchDescriptor<Bud>())
    let exports = buds.map { bud in
        BudsBackup.BudExport(
            contactID: bud.contactID,
            name: bud.name,
            lastContactDate: bud.lastContactDate,
            addedDate: bud.addedDate,
            isPinned: bud.isPinned,
            isArchived: bud.isArchived,
            profileName: bud.profileName,
            contactCadenceDays: bud.contactCadenceDays,
            interactions: (bud.interactions ?? []).map {
                BudsBackup.BudExport.InteractionExport(date: $0.date, channelRaw: $0.channelRaw, note: $0.note)
            },
            events: (bud.events ?? []).map {
                BudsBackup.BudExport.EventExport(date: $0.date, note: $0.note)
            }
        )
    }
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return try encoder.encode(BudsBackup(buds: exports))
}

@MainActor
@discardableResult
func restoreBackup(from data: Data, context: ModelContext) throws -> Int {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let backup = try decoder.decode(BudsBackup.self, from: data)

    let existing = try context.fetch(FetchDescriptor<Bud>())
    let existingIDs = Set(existing.map(\.contactID))

    var count = 0
    for b in backup.buds where !existingIDs.contains(b.contactID) {
        let bud = Bud(contactID: b.contactID, name: b.name)
        bud.lastContactDate = b.lastContactDate
        bud.addedDate = b.addedDate
        bud.isPinned = b.isPinned
        bud.isArchived = b.isArchived
        bud.profileName = b.profileName
        bud.contactCadenceDays = b.contactCadenceDays
        context.insert(bud)
        for i in b.interactions {
            let interaction = ContactInteraction(
                date: i.date,
                channel: i.channelRaw.flatMap { ContactChannel(rawValue: $0) },
                note: i.note
            )
            interaction.bud = bud
            context.insert(interaction)
        }
        for e in b.events {
            let event = Event(date: e.date, note: e.note)
            event.bud = bud
            context.insert(event)
        }
        count += 1
    }
    return count
}
