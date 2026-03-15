import SwiftData
import SwiftUI

struct BudListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var buds: [Bud]
    @State private var showingContactPicker = false
    @State private var photoCache = ContactPhotoCache()

    private var sortedBuds: [Bud] {
        buds.sorted { a, b in
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
                if buds.isEmpty {
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
                                    bud.interactions.append(interaction)
                                    bud.lastContactDate = interaction.date
                                }
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                modelContext.delete(sortedBuds[index])
                            }
                        }
                    }
                }
            }
            .navigationTitle("Buds")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingContactPicker = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView { contactID, name in
                    // Avoid duplicates
                    guard !buds.contains(where: { $0.contactID == contactID }) else { return }
                    let bud = Bud(contactID: contactID, name: name)
                    modelContext.insert(bud)
                }
            }
        }
    }
}
