import SwiftData
import SwiftUI

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var buds: [Bud]
    @AppStorage("activeProfile") private var activeProfile = "Personal"
    @State private var selectedTab = 0
    @State private var showingContactPicker = false
    @State private var showingNewEvent = false

    private let profiles = ["Personal", "Professional"]

    private var profileIcon: String {
        activeProfile == "Personal" ? "person.fill" : "building.2.fill"
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Buds", systemImage: "person.2.fill", value: 0) {
                NavigationStack {
                    BudListView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                profileButton
                            }
                        }
                }
            }
            Tab("Events", systemImage: "calendar", value: 1) {
                NavigationStack {
                    EventsView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                profileButton
                            }
                        }
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .overlay(alignment: .bottom) {
            HStack {
                Spacer()
                addButton
                    .padding(.trailing, 16)
            }
            .padding(.bottom, 2)
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

    private var addButton: some View {
        Button {
            if selectedTab == 0 {
                showingContactPicker = true
            } else {
                showingNewEvent = true
            }
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(width: 52, height: 52)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
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
