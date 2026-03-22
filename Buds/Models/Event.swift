import Foundation
import SwiftData

@Model
final class Event {
    var date: Date = Date()
    var note: String = ""
    var bud: Bud?

    init(date: Date = Date(), note: String = "") {
        self.date = date
        self.note = note
    }
}
