import SwiftData
import SwiftUI

struct EventsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var events: [Event]
    @Query(filter: #Predicate<Bud> { !$0.isArchived }) private var buds: [Bud]
    @AppStorage("activeProfile") private var activeProfile = "Personal"
    @State private var birthdayItems: [EventItem] = []
    @State private var showingNewEvent = false
    @State private var newEvent: Event?
    @State private var selectedBud: Bud?

    private var allItems: [EventItem] {
        let appItems = events
            .filter { $0.bud?.profileName == activeProfile }
            .map { EventItem.appEvent($0) }
        let profileBirthdays = birthdayItems.filter {
            if case .birthday(let bud, _, _) = $0 {
                return bud.profileName == activeProfile
            }
            return false
        }
        let merged = appItems + profileBirthdays
        let today = Calendar.current.startOfDay(for: Date())
        return merged
            .filter { $0.date >= today }
            .sorted { $0.date < $1.date }
    }

    private var groupedItems: [(String, [EventItem])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        var groups: [(String, [EventItem])] = []
        var currentKey = ""
        var currentItems: [EventItem] = []
        for item in allItems {
            let key = formatter.string(from: item.date)
            if key != currentKey {
                if !currentItems.isEmpty {
                    groups.append((currentKey, currentItems))
                }
                currentKey = key
                currentItems = [item]
            } else {
                currentItems.append(item)
            }
        }
        if !currentItems.isEmpty {
            groups.append((currentKey, currentItems))
        }
        return groups
    }

    var body: some View {
        Group {
            if allItems.isEmpty {
                ContentUnavailableView {
                    Label("No Upcoming Events", systemImage: "calendar")
                } description: {
                    Text("Add events to keep track of important dates.")
                } actions: {
                    Button("Add Event") { showingNewEvent = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(groupedItems, id: \.0) { month, items in
                        Section(month) {
                            ForEach(items) { item in
                                eventRow(item)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .sheet(isPresented: $showingNewEvent) {
            NavigationStack {
                NewEventView()
            }
        }
        .task {
            await loadBirthdays()
        }
    }

    @ViewBuilder
    private func eventRow(_ item: EventItem) -> some View {
        switch item {
        case .appEvent(let event):
            NavigationLink {
                EventDetailView(event: event)
            } label: {
                EventRowContent(
                    name: event.bud?.name ?? "Unknown",
                    contactID: event.bud?.contactID ?? "",
                    detail: event.note.isEmpty ? "Event" : event.note,
                    date: event.date,
                    isBirthday: false
                )
            }
        case .birthday(let bud, let nextDate, _):
            EventRowContent(
                name: bud.name,
                contactID: bud.contactID,
                detail: "Birthday",
                date: nextDate,
                isBirthday: true
            )
        }
    }

    private func loadBirthdays() async {
        let contactIDs = buds.map(\.contactID)
        let results = await BirthdayProvider.shared.birthdays(for: contactIDs)
        var items: [EventItem] = []
        for (contactID, components) in results {
            guard let bud = buds.first(where: { $0.contactID == contactID }),
                  let nextDate = BirthdayProvider.nextOccurrence(of: components) else { continue }
            items.append(.birthday(bud: bud, nextDate: nextDate, components: components))
        }
        birthdayItems = items
    }
}

private struct EventRowContent: View {
    let name: String
    let contactID: String
    let detail: String
    let date: Date
    let isBirthday: Bool

    var body: some View {
        HStack(spacing: 12) {
            ContactPhotoView(contactID: contactID, name: name)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                HStack(spacing: 4) {
                    if isBirthday {
                        Image(systemName: "gift.fill")
                            .font(.caption2)
                            .foregroundStyle(.pink)
                    }
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(date.formatted(.dateTime.month(.abbreviated).day()))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ContactPhotoView: View {
    let contactID: String
    let name: String
    @State private var photo: UIImage?

    var body: some View {
        Group {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color(.systemGray4))
                    .overlay {
                        Text(initials)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .task {
            photo = await ContactPhotoCache.shared.fetch(for: contactID)
        }
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }
}

struct NewEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Bud> { !$0.isArchived }) private var buds: [Bud]
    @State private var selectedBud: Bud?
    @State private var date = Date()
    @State private var note = ""
    var body: some View {
        Form {
            Section("Contact") {
                Picker("Bud", selection: $selectedBud) {
                    Text("Select a bud").tag(nil as Bud?)
                    ForEach(buds) { bud in
                        Text(bud.name).tag(bud as Bud?)
                    }
                }
            }

            Section {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
            }

            Section("Note") {
                TextField("Add a note...", text: $note, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle("New Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(selectedBud == nil)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }

    private func save() {
        guard let bud = selectedBud else { return }
        let event = Event(date: Calendar.current.startOfDay(for: date), note: note)
        modelContext.insert(event)
        if bud.events != nil {
            bud.events!.append(event)
        } else {
            bud.events = [event]
        }
        dismiss()
    }
}
