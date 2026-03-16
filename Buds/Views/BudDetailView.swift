import SwiftUI

struct BudDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let bud: Bud
    let photo: UIImage?
    @State private var showingArchiveConfirmation = false
    @State private var interactionToEdit: ContactInteraction?
    @State private var newInteraction: ContactInteraction?

    private var urgency: UrgencyLevel {
        .from(lastContact: bud.lastContactDate)
    }

    private var sortedInteractions: [ContactInteraction] {
        (bud.interactions ?? []).sorted { $0.date > $1.date }
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

            Section {
                Button {
                    logNewInteraction()
                } label: {
                    Label("Log Contact Now", systemImage: "message.fill")
                }
                Button {
                    logPastInteraction()
                } label: {
                    Label("Log Past Contact...", systemImage: "clock.arrow.circlepath")
                }
            }

            Section("History") {
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
            }

            Section("Details") {
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
    }

    private func logNewInteraction() {
        let interaction = ContactInteraction()
        appendInteraction(interaction)
        bud.lastContactDate = Calendar.current.startOfDay(for: interaction.date)
    }

    private func logPastInteraction() {
        let interaction = ContactInteraction()
        appendInteraction(interaction)
        newInteraction = interaction
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
