import SwiftData
import SwiftUI

struct SearchView: View {
    var focusTrigger: Int = 0
    var onDismiss: (() -> Void)?
    @Query(filter: #Predicate<Bud> { !$0.isArchived }) private var buds: [Bud]
    @Query private var events: [Event]
    @State private var searchText = ""
    @State private var searchIsActive = false
    @FocusState private var searchIsFocused: Bool

    private var filteredBuds: [Bud] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        return buds
            .filter { $0.name.lowercased().contains(query) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var filteredEvents: [Event] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        return events
            .filter { event in
                (event.bud?.name.lowercased().contains(query) ?? false)
                    || event.note.lowercased().contains(query)
            }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        List {
            if !filteredBuds.isEmpty {
                Section("Buds") {
                    ForEach(filteredBuds) { bud in
                        NavigationLink {
                            BudDetailView(
                                bud: bud,
                                photo: ContactPhotoCache.shared.cachedPhoto(for: bud.contactID)
                            )
                        } label: {
                            BudRowView(bud: bud) { channel in
                                let interaction = ContactInteraction(channel: channel)
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

            if !filteredEvents.isEmpty {
                Section("Events") {
                    ForEach(filteredEvents) { event in
                        NavigationLink {
                            EventDetailView(event: event)
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.bud?.name ?? "Unknown")
                                        .font(.body)
                                    if !event.note.isEmpty {
                                        Text(event.note)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                                Text(event.date.formatted(.dateTime.month(.abbreviated).day()))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if searchText.isEmpty {
                ContentUnavailableView("Search Buds & Events", systemImage: "magnifyingglass", description: Text("Search by name or event note."))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else if filteredBuds.isEmpty && filteredEvents.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, isPresented: $searchIsActive, prompt: "Name or event note")
        .searchFocused($searchIsFocused)
        .navigationTitle("")
        .onChange(of: searchIsActive) { _, active in
            if !active { onDismiss?() }
        }
        .task(id: focusTrigger) {
            guard focusTrigger > 0 else { return }
            searchIsActive = true
            try? await Task.sleep(for: .milliseconds(50))
            // Speed up the keyboard slide-in animation
            let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene }).first?
                .windows.first
            window?.layer.speed = 3.0
            searchIsFocused = true
            // Reset after keyboard animation completes (~250ms / 3x = ~85ms)
            try? await Task.sleep(for: .milliseconds(150))
            window?.layer.speed = 1.0
        }
    }
}
