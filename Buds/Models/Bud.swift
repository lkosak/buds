import Foundation
import SwiftData

@Model
final class Bud {
    var contactID: String
    var name: String = ""
    var lastContactDate: Date?
    var addedDate: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \ContactInteraction.bud)
    var interactions: [ContactInteraction] = []

    init(contactID: String, name: String) {
        self.contactID = contactID
        self.name = name
        self.addedDate = Date()
    }
}
