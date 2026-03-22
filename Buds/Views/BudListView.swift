import SwiftData
import SwiftUI

struct BudListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var buds: [Bud]
    @AppStorage("activeProfile") private var activeProfile = "Personal"
    @State private var showingContactPicker = false
    @State private var showingSettings = false
    @State private var showingAllBuds = false

    private let profiles = ["Personal", "Professional"]

    // Single pass: compute ratio once per bud, partition, then sort each group.
    private var processedBuds: (due: [Bud], notDue: [Bud]) {
        var dueEntries: [(bud: Bud, ratio: Double)] = []
        var notDueEntries: [(bud: Bud, ratio: Double)] = []

        for bud in buds where !bud.isArchived && bud.profileName == activeProfile {
            let ratio = urgencyRatio(lastContact: bud.lastContactDate, cadenceDays: bud.contactCadenceDays) ?? Double.infinity
            if ratio >= 0.95 {
                dueEntries.append((bud, ratio))
            } else {
                notDueEntries.append((bud, ratio))
            }
        }

        let byUrgency: ((bud: Bud, ratio: Double), (bud: Bud, ratio: Double)) -> Bool = { a, b in
            if a.bud.isPinned != b.bud.isPinned { return a.bud.isPinned }
            return a.ratio > b.ratio
        }
        dueEntries.sort(by: byUrgency)
        notDueEntries.sort(by: byUrgency)

        return (dueEntries.map(\.bud), notDueEntries.map(\.bud))
    }

    var body: some View {
        let (dueBuds, notDueBuds) = processedBuds
        Group {
            if dueBuds.isEmpty && notDueBuds.isEmpty {
                EmptyStateView { showingContactPicker = true }
            } else {
                List {
                    Section {
                        ForEach(dueBuds) { bud in
                            budRow(bud)
                        }
                        if showingAllBuds {
                            ForEach(notDueBuds) { bud in
                                budRow(bud)
                            }
                        }
                    }

                    if !notDueBuds.isEmpty {
                        Section {
                            Button {
                                withAnimation { showingAllBuds.toggle() }
                            } label: {
                                Text(showingAllBuds ? "Show fewer" : "\(notDueBuds.count) more not due yet")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .listRowBackground(Color.clear)
                        }
                        .listSectionSpacing(4)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
            ToolbarItem(placement: .principal) {
                Menu {
                    ForEach(profiles, id: \.self) { profile in
                        Button {
                            activeProfile = profile
                        } label: {
                            if profile == activeProfile {
                                Label(profile, systemImage: "checkmark")
                            } else {
                                Text(profile)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(activeProfile)
                            .font(.headline)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.primary)
                }
            }
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Spacer()
                    Button {
                        showingContactPicker = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
            }
        }
        .sheet(isPresented: $showingContactPicker) {
            ContactPickerView { contactID, name in
                if let existing = buds.first(where: {
                    $0.contactID == contactID && $0.profileName == activeProfile
                }) {
                    if existing.isArchived {
                        existing.isArchived = false
                    }
                    return
                }
                let bud = Bud(contactID: contactID, name: name)
                bud.profileName = activeProfile
                modelContext.insert(bud)
            }
        }
    }

    @ViewBuilder
    private func budRow(_ bud: Bud) -> some View {
        NavigationLink {
            BudDetailView(
                bud: bud,
                photo: ContactPhotoCache.shared.cachedPhoto(for: bud.contactID)
            )
        } label: {
            BudRowView(bud: bud) {
                let interaction = ContactInteraction()
                if bud.interactions != nil {
                    bud.interactions!.append(interaction)
                } else {
                    bud.interactions = [interaction]
                }
                bud.lastContactDate = interaction.date
            } onTogglePin: {
                bud.isPinned.toggle()
            }
        }
    }
}
