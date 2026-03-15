import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Bud> { $0.isArchived })
    private var archivedBuds: [Bud]

    var body: some View {
        List {
            Section("Archive") {
                if archivedBuds.isEmpty {
                    Text("No archived contacts")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(archivedBuds) { bud in
                        HStack {
                            Text(bud.name)
                            Spacer()
                            Button("Restore") {
                                bud.isArchived = false
                            }
                            .font(.subheadline)
                        }
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}
