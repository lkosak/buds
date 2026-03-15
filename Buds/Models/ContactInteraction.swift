import Foundation
import SwiftData

@Model
final class ContactInteraction {
    var date: Date = Date()
    var bud: Bud?

    init(date: Date = Date()) {
        self.date = date
    }
}
