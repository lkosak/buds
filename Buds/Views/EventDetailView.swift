import SwiftUI

struct EventDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let event: Event
    let isNew: Bool

    @State private var date: Date
    @State private var note: String
    @State private var showingDeleteConfirmation = false

    init(event: Event, isNew: Bool = false) {
        self.event = event
        self.isNew = isNew
        _date = State(initialValue: event.date)
        _note = State(initialValue: event.note)
    }

    var body: some View {
        Form {
            Section {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
            }

            Section("Note") {
                TextField("Add a note...", text: $note, axis: .vertical)
                    .lineLimit(3...6)
            }

            if let bud = event.bud {
                Section("Contact") {
                    LabeledContent("Bud", value: bud.name)
                }
            }

            if !isNew {
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Event", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(isNew ? "New Event" : "Edit Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    if isNew {
                        modelContext.delete(event)
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
        .confirmationDialog("Delete this event?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(event)
                dismiss()
            }
        }
    }

    private func save() {
        event.date = Calendar.current.startOfDay(for: date)
        event.note = note
        dismiss()
    }
}
