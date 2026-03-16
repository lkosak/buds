import SwiftUI

struct InteractionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let interaction: ContactInteraction
    let isNew: Bool

    @State private var date: Date
    @State private var channel: ContactChannel?
    @State private var note: String
    @State private var showingDeleteConfirmation = false

    init(interaction: ContactInteraction, isNew: Bool = false) {
        self.interaction = interaction
        self.isNew = isNew
        _date = State(initialValue: interaction.date)
        _channel = State(initialValue: interaction.channel)
        _note = State(initialValue: interaction.note ?? "")
    }

    var body: some View {
        Form {
            Section {
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }

            Section("Channel") {
                ForEach(ContactChannel.allCases, id: \.self) { ch in
                    Button {
                        channel = channel == ch ? nil : ch
                    } label: {
                        HStack {
                            Label(ch.rawValue, systemImage: ch.systemImage)
                                .foregroundStyle(.primary)
                            Spacer()
                            if channel == ch {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }
            }

            Section("Note") {
                TextField("Add a note...", text: $note, axis: .vertical)
                    .lineLimit(3...6)
            }

            if !isNew {
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Interaction", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(isNew ? "Log Contact" : "Edit Contact")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    if isNew {
                        modelContext.delete(interaction)
                    }
                    dismiss()
                }
            }
        }
        .confirmationDialog("Delete this interaction?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(interaction)
                updateBudLastContact()
                dismiss()
            }
        }
    }

    private func save() {
        interaction.date = Calendar.current.startOfDay(for: date)
        interaction.channel = channel
        interaction.note = note.isEmpty ? nil : note
        updateBudLastContact()
        dismiss()
    }

    private func updateBudLastContact() {
        guard let bud = interaction.bud else { return }
        let latest = (bud.interactions ?? [])
            .filter { $0.persistentModelID != interaction.persistentModelID || !showingDeleteConfirmation }
            .map(\.date)
            .max()
        bud.lastContactDate = latest
    }
}
