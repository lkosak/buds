import SwiftData
import SwiftUI

struct BudListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var buds: [Bud]
    @AppStorage("activeProfile") private var activeProfile = "Personal"
    @State private var showingContactPicker = false
    @State private var showingSettings = false
    @State private var photoCache = ContactPhotoCache()

    private let profiles = ["Personal", "Professional"]

    private var activeBuds: [Bud] {
        buds.filter { !$0.isArchived && $0.profileName == activeProfile }
    }

    private var sortedBuds: [Bud] {
        activeBuds.sorted { a, b in
            // Pinned contacts always come first
            if a.isPinned != b.isPinned {
                return a.isPinned
            }
            let ua = UrgencyLevel.from(lastContact: a.lastContactDate)
            let ub = UrgencyLevel.from(lastContact: b.lastContactDate)
            if ua.sortOrder != ub.sortOrder {
                return ua.sortOrder < ub.sortOrder
            }
            return (a.lastContactDate ?? .distantPast) < (b.lastContactDate ?? .distantPast)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if activeBuds.isEmpty {
                    EmptyStateView { showingContactPicker = true }
                } else {
                    List {
                        ForEach(sortedBuds) { bud in
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
                    // If already exists in this profile, unarchive if archived
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
}
