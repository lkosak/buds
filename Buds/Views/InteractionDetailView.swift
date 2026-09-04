import SwiftUI

struct InteractionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let interaction: ContactInteraction
    let isNew: Bool
    /// Called on save before the bud's last-contact date is recomputed. A new
    /// interaction is attached to its bud here, so it never shows up in the
    /// contact history until the user actually saves it.
    var onSave: (() -> Void)?

    @State private var date: Date
    @State private var channel: ContactChannel?
    @State private var note: String
    @State private var showingDeleteConfirmation = false

    init(interaction: ContactInteraction, isNew: Bool = false, onSave: (() -> Void)? = nil) {
        self.interaction = interaction
        self.isNew = isNew
        self.onSave = onSave
        _date = State(initialValue: interaction.date)
        _channel = State(initialValue: interaction.channel)
        _note = State(initialValue: interaction.note ?? "")
    }

    var body: some View {
        Form {
            Section {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
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
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    if isNew, interaction.modelContext != nil {
                        modelContext.delete(interaction)
                    }
                    dismiss()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                save()
            } label: {
                Text("Save")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .confirmationDialog("Delete this interaction?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                let bud = interaction.bud
                modelContext.delete(interaction)
                if let bud {
                    bud.lastContactDate = (bud.interactions ?? [])
                        .filter { $0.persistentModelID != interaction.persistentModelID }
                        .map(\.date)
                        .max()
                }
                dismiss()
            }
        }
    }

    private func save() {
        interaction.date = Calendar.current.startOfDay(for: date)
        interaction.channel = channel
        interaction.note = note.isEmpty ? nil : note
        onSave?()
        updateBudLastContact()
        dismiss()
    }

    private func updateBudLastContact() {
        guard let bud = interaction.bud else { return }
        bud.lastContactDate = (bud.interactions ?? []).map(\.date).max()
    }
}
