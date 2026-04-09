import SwiftData
import SwiftUI

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var buds: [Bud]
    @AppStorage("activeProfile") private var activeProfile = "Personal"
    @State private var showingContactPicker = false
    @State private var showingNewEvent = false
    @State private var selectedTab = "buds"
    @State private var eventsScrollSignal = 0

    private let profiles = ["Personal", "Professional"]

    private var profileIcon: String {
        activeProfile == "Personal" ? "person.fill" : "building.2.fill"
    }

    private var tabSelection: Binding<String> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                if newValue == "events" { eventsScrollSignal += 1 }
                selectedTab = newValue
            }
        )
    }

    var body: some View {
        TabView(selection: tabSelection) {
            Tab("Buds", systemImage: "person.2.fill", value: "buds") {
                NavigationStack {
                    BudListView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                profileButton
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    showingContactPicker = true
                                } label: {
                                    Image(systemName: "plus")
                                }
                            }
                        }
                }
            }
            Tab("Events", systemImage: "calendar", value: "events") {
                NavigationStack {
                    EventsView(scrollSignal: eventsScrollSignal)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                profileButton
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    showingNewEvent = true
                                } label: {
                                    Image(systemName: "plus")
                                }
                            }
                        }
                }
            }
            Tab(value: "search", role: .search) {
                NavigationStack {
                    SearchView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                profileButton
                            }
                        }
                }
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
        .sheet(isPresented: $showingNewEvent) {
            NavigationStack {
                NewEventView()
            }
        }
    }

    private var profileButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            activeProfile = activeProfile == "Personal" ? "Professional" : "Personal"
        } label: {
            Image(systemName: profileIcon)
                .transaction { $0.animation = nil }
        }
        .contextMenu {
            ForEach(profiles, id: \.self) { profile in
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    activeProfile = profile
                } label: {
                    if profile == activeProfile {
                        Label(profile, systemImage: "checkmark")
                    } else {
                        Text(profile)
                    }
                }
            }
        }
    }
}
