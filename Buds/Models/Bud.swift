import Foundation
import SwiftData

@Model
final class Bud {
    var contactID: String = ""
    var name: String = ""
    var lastContactDate: Date?
    var addedDate: Date = Date()
    var isPinned: Bool = false
    var isArchived: Bool = false
    var profileName: String = "Personal"
    var contactCadenceDays: Int = 90
    @Relationship(deleteRule: .cascade, inverse: \ContactInteraction.bud)
    var interactions: [ContactInteraction]? = []
    @Relationship(deleteRule: .cascade, inverse: \Event.bud)
    var events: [Event]? = []

    init(contactID: String, name: String) {
        self.contactID = contactID
        self.name = name
        self.addedDate = Calendar.current.startOfDay(for: Date())
    }
}
