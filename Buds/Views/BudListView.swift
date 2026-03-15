import SwiftData
import SwiftUI

struct BudListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var buds: [Bud]
    @State private var showingContactPicker = false
    @State private var showingSettings = false
    @State private var photoCache = ContactPhotoCache()

    private var activeBuds: [Bud] {
        buds.filter { !$0.isArchived }
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
            .navigationTitle("Buds")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
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
                    // If archived, unarchive instead of creating duplicate
                    if let existing = buds.first(where: { $0.contactID == contactID }) {
                        if existing.isArchived {
                            existing.isArchived = false
                        }
                        return
                    }
                    let bud = Bud(contactID: contactID, name: name)
                    modelContext.insert(bud)
                }
            }
        }
    }
}
