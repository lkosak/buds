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
    @State private var showingNoteField: Bool

    init(interaction: ContactInteraction, isNew: Bool = false) {
        self.interaction = interaction
        self.isNew = isNew
        _date = State(initialValue: interaction.date)
        _channel = State(initialValue: interaction.channel)
        _note = State(initialValue: interaction.note ?? "")
        _showingNoteField = State(initialValue: !isNew)
    }

    /// New + no note yet: tapping a channel logs immediately instead of requiring a separate Save.
    private var quickLogMode: Bool {
        isNew && !showingNoteField
    }

    var body: some View {
        Form {
            Section {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
            }

            Section {
                channelPicker
            } header: {
                Text("Channel")
            } footer: {
                if quickLogMode {
                    Text("Tap a channel to log today's contact.")
                }
            }

            if showingNoteField {
                Section("Note") {
                    TextField("Add a note...", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
            } else if isNew {
                Section {
                    Button {
                        withAnimation {
                            showingNoteField = true
                        }
                    } label: {
                        Label("Add a Note", systemImage: "plus.bubble")
                    }
                }
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
                    if isNew {
                        modelContext.delete(interaction)
                    }
                    dismiss()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !quickLogMode {
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

    private var channelPicker: some View {
        HStack(spacing: 8) {
            ForEach(ContactChannel.allCases, id: \.self) { ch in
                VStack(spacing: 6) {
                    Button {
                        if quickLogMode {
                            channel = ch
                            save()
                        } else {
                            channel = channel == ch ? nil : ch
                        }
                    } label: {
                        Image(systemName: ch.systemImage)
                            .font(.title3)
                            .frame(width: 48, height: 48)
                    }
                    .buttonStyle(.glass)
                    .tint(channel == ch && !quickLogMode ? Color.accentColor : nil)

                    Text(ch.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
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
        bud.lastContactDate = (bud.interactions ?? []).map(\.date).max()
    }
}
