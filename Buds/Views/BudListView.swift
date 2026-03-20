import SwiftData
import SwiftUI

struct BudListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var buds: [Bud]
    @AppStorage("activeProfile") private var activeProfile = "Personal"
    @State private var showingContactPicker = false
    @State private var showingSettings = false
    @State private var photoCache = ContactPhotoCache()
    @State private var showingAllBuds = false

    private let profiles = ["Personal", "Professional"]

    private var activeBuds: [Bud] {
        buds.filter { !$0.isArchived && $0.profileName == activeProfile }
    }

    // Ratio >= 0.95 or never contacted: show in main list
    private var dueBuds: [Bud] {
        activeBuds
            .filter { bud in
                let ratio = urgencyRatio(lastContact: bud.lastContactDate, cadenceDays: bud.contactCadenceDays)
                return ratio == nil || ratio! >= 0.95
            }
            .sorted { a, b in
                if a.isPinned != b.isPinned { return a.isPinned }
                let ra = urgencyRatio(lastContact: a.lastContactDate, cadenceDays: a.contactCadenceDays) ?? Double.infinity
                let rb = urgencyRatio(lastContact: b.lastContactDate, cadenceDays: b.contactCadenceDays) ?? Double.infinity
                return ra > rb
            }
    }

    // Ratio < 0.95: hidden behind See All
    private var notDueBuds: [Bud] {
        activeBuds
            .filter { bud in
                guard let ratio = urgencyRatio(lastContact: bud.lastContactDate, cadenceDays: bud.contactCadenceDays) else { return false }
                return ratio < 0.95
            }
            .sorted { a, b in
                if a.isPinned != b.isPinned { return a.isPinned }
                let ra = urgencyRatio(lastContact: a.lastContactDate, cadenceDays: a.contactCadenceDays) ?? 0
                let rb = urgencyRatio(lastContact: b.lastContactDate, cadenceDays: b.contactCadenceDays) ?? 0
                return ra > rb
            }
    }

    var body: some View {
        NavigationStack {
            Group {
                if activeBuds.isEmpty {
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
                                        .foregroundStyle(.tertiary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                                .listRowBackground(Color.clear)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .animation(.default, value: showingAllBuds)
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingContactPicker = true
                    } label: {
                        Image(systemName: "plus")
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
    }

    @ViewBuilder
    private func budRow(_ bud: Bud) -> some View {
        NavigationLink {
            BudDetailView(
                bud: bud,
                photo: photoCache.photo(for: bud.contactID)
            )
        } label: {
            BudRowView(
                bud: bud,
                photo: photoCache.photo(for: bud.contactID)
            ) {
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
