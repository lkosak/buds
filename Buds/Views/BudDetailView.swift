import SwiftUI

struct BudDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let bud: Bud
    let photo: UIImage?
    @State private var showingArchiveConfirmation = false
    @State private var interactionToEdit: ContactInteraction?
    @State private var newInteraction: ContactInteraction?
    @State private var eventToEdit: Event?
    @State private var newEvent: Event?
    @State private var birthday: DateComponents?
    @State private var loadingBirthday = true
    @State private var showingBirthdayEditor = false

    private var urgency: UrgencyLevel {
        .from(lastContact: bud.lastContactDate, cadenceDays: bud.contactCadenceDays)
    }

    private let cadenceOptions = [90, 180, 365]

    private func cadenceLabel(_ days: Int) -> String {
        switch days {
        case 90: return "3 months"
        case 180: return "6 months"
        case 365: return "12 months"
        default: return "\(days) days"
        }
    }

    private var sortedInteractions: [ContactInteraction] {
        (bud.interactions ?? []).sorted { $0.date > $1.date }
    }

    private var upcomingEvents: [Event] {
        let today = Calendar.current.startOfDay(for: Date())
        return (bud.events ?? [])
            .filter { $0.date >= today }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        if let photo {
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color(.systemGray4))
                                .frame(width: 80, height: 80)
                                .overlay {
                                    Text(initials(for: bud.name))
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                        }

                        Text(bud.name)
                            .font(.title2)
                            .fontWeight(.semibold)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(urgency.color)
                                .frame(width: 10, height: 10)
                            Text(relativeTimeString(from: bud.lastContactDate))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section("Contact History") {
                if sortedInteractions.isEmpty {
                    Text("No contact history yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedInteractions) { interaction in
                        Button {
                            interactionToEdit = interaction
                        } label: {
                            InteractionRowView(interaction: interaction)
                        }
                        .tint(.primary)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            let interaction = sortedInteractions[index]
                            modelContext.delete(interaction)
                        }
                        updateLastContact()
                    }
                }
                Button {
                    logContact()
                } label: {
                    Label("Log Contact", systemImage: "message.fill")
                }
            }

            Section("Events") {
                if upcomingEvents.isEmpty {
                    Text("No upcoming events")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(upcomingEvents) { event in
                        Button {
                            eventToEdit = event
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline)
                                    if !event.note.isEmpty {
                                        Text(event.note)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .tint(.primary)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            modelContext.delete(upcomingEvents[index])
                        }
                    }
                }
                Button {
                    addNewEvent()
                } label: {
                    Label("Add Event", systemImage: "calendar.badge.plus")
                }
            }

            Section("Notes") {
                TextField("Add notes...", text: Bindable(bud).notes, axis: .vertical)
                    .lineLimit(3...)
            }

            Section("Target Frequency") {
                Picker("Frequency", selection: Bindable(bud).contactCadenceDays) {
                    ForEach(cadenceOptions, id: \.self) { days in
                        Text(cadenceLabel(days)).tag(days)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Details") {
                if loadingBirthday {
                    LabeledContent("Birthday") {
                        ProgressView()
                    }
                } else if let birthday, let month = birthday.month, let day = birthday.day {
                    Button {
                        showingBirthdayEditor = true
                    } label: {
                        LabeledContent("Birthday", value: formattedBirthday(month: month, day: day))
                            .foregroundStyle(.primary)
                    }
                } else {
                    Button {
                        showingBirthdayEditor = true
                    } label: {
                        LabeledContent("Birthday") {
                            Text("Add")
                                .foregroundStyle(.blue)
                        }
                        .foregroundStyle(.primary)
                    }
                }
                LabeledContent("Added", value: bud.addedDate.formatted(date: .abbreviated, time: .omitted))
                LabeledContent("Times contacted", value: "\((bud.interactions ?? []).count)")
            }

            Section {
                Button(role: .destructive) {
                    showingArchiveConfirmation = true
                } label: {
                    Label("Archive Contact", systemImage: "archivebox")
                }
            }
        }
        .navigationTitle(bud.name)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Archive \(bud.name)?",
            isPresented: $showingArchiveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Archive", role: .destructive) {
                bud.isArchived = true
                dismiss()
            }
        } message: {
            Text("They'll be moved to your archive. You can restore them from Settings.")
        }
        .sheet(item: $interactionToEdit) { interaction in
            NavigationStack {
                InteractionDetailView(interaction: interaction)
            }
        }
        .sheet(item: $newInteraction) { interaction in
            NavigationStack {
                InteractionDetailView(interaction: interaction, isNew: true)
            }
        }
        .sheet(item: $eventToEdit) { event in
            NavigationStack {
                EventDetailView(event: event)
            }
        }
        .sheet(item: $newEvent) { event in
            NavigationStack {
                EventDetailView(event: event, isNew: true)
            }
        }
        .sheet(isPresented: $showingBirthdayEditor) {
            NavigationStack {
                BirthdayEditorView(contactID: bud.contactID, birthday: birthday) { updated in
                    birthday = updated
                }
            }
        }
        .task {
            birthday = await BirthdayProvider.shared.birthday(for: bud.contactID)
            loadingBirthday = false
        }
        .onDisappear {
            Task { await rescheduleAllNotifications(context: modelContext) }
        }
    }

    private func logContact() {
        let interaction = ContactInteraction()
        appendInteraction(interaction)
        newInteraction = interaction
    }

    private func addNewEvent() {
        let event = Event()
        modelContext.insert(event)
        if bud.events != nil {
            bud.events!.append(event)
        } else {
            bud.events = [event]
        }
        newEvent = event
    }

    private func appendInteraction(_ interaction: ContactInteraction) {
        if bud.interactions != nil {
            bud.interactions!.append(interaction)
        } else {
            bud.interactions = [interaction]
        }
    }

    private func updateLastContact() {
        bud.lastContactDate = (bud.interactions ?? []).map(\.date).max()
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }

    private func formattedBirthday(month: Int, day: Int) -> String {
        var components = DateComponents()
        components.month = month
        components.day = day
        components.year = 2000
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(month)/\(day)"
    }
}

private struct BirthdayEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let contactID: String
    let birthday: DateComponents?
    let onSave: (DateComponents?) -> Void

    @State private var date: Date
    @State private var errorMessage: String?

    init(contactID: String, birthday: DateComponents?, onSave: @escaping (DateComponents?) -> Void) {
        self.contactID = contactID
        self.birthday = birthday
        self.onSave = onSave
        var components = DateComponents()
        components.month = birthday?.month ?? 1
        components.day = birthday?.day ?? 1
        components.year = 2000
        _date = State(initialValue: Calendar.current.date(from: components) ?? Date())
    }

    var body: some View {
        Form {
            Section {
                DatePicker("Birthday", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
            }

            if birthday != nil {
                Section {
                    Button(role: .destructive) {
                        Task {
                            do {
                                try await BirthdayProvider.shared.setBirthday(nil, for: contactID)
                                onSave(nil)
                                dismiss()
                            } catch {
                                errorMessage = "Could not update birthday. This contact may not exist in your address book."
                            }
                        }
                    } label: {
                        Label("Remove Birthday", systemImage: "trash")
                    }
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Birthday")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        let cal = Calendar.current
                        var components = DateComponents()
                        components.month = cal.component(.month, from: date)
                        components.day = cal.component(.day, from: date)
                        do {
                            try await BirthdayProvider.shared.setBirthday(components, for: contactID)
                            onSave(components)
                            dismiss()
                        } catch {
                            errorMessage = "Could not save birthday. This contact may not exist in your address book."
                        }
                    }
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}

private struct InteractionRowView: View {
    let interaction: ContactInteraction

    var body: some View {
        HStack {
            Image(systemName: interaction.channel?.systemImage ?? "message.fill")
                .foregroundStyle(.green)
                .font(.caption)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(interaction.date.formatted(date: .abbreviated, time: .omitted))
                    if let channel = interaction.channel {
                        Text("· \(channel.rawValue)")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
                if let note = interaction.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}
