import SwiftUI

struct BudDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let bud: Bud
    let photo: UIImage?

    private var urgency: UrgencyLevel {
        .from(lastContact: bud.lastContactDate)
    }

    private var sortedInteractions: [ContactInteraction] {
        bud.interactions.sorted { $0.date > $1.date }
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
                    let interaction = ContactInteraction()
                    bud.interactions.append(interaction)
                    bud.lastContactDate = interaction.date
                } label: {
                    Label("Log Contact", systemImage: "message.fill")
                }
            }

            Section("History") {
                if sortedInteractions.isEmpty {
                    Text("No contact history yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedInteractions) { interaction in
                        HStack {
                            Image(systemName: "message.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text(interaction.date.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            let interaction = sortedInteractions[index]
                            modelContext.delete(interaction)
                        }
                    }
                }
            }

            Section("Details") {
                LabeledContent("Added", value: bud.addedDate.formatted(date: .abbreviated, time: .omitted))
                LabeledContent("Times contacted", value: "\(bud.interactions.count)")
            }
        }
        .navigationTitle(bud.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }
}
