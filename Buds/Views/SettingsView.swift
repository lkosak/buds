import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

private struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Bud> { $0.isArchived })
    private var archivedBuds: [Bud]

    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    @State private var showingImporter = false
    @State private var alertMessage: String?

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

            Section("Data") {
                Button("Export Backup") {
                    do {
                        let data = try makeBackupData(context: modelContext)
                        let date = ISO8601DateFormatter().string(from: Date()).prefix(10)
                        let url = FileManager.default.temporaryDirectory
                            .appendingPathComponent("buds-\(date).json")
                        try data.write(to: url)
                        exportURL = url
                        showingShareSheet = true
                    } catch {
                        alertMessage = "Export failed: \(error.localizedDescription)"
                    }
                }

                Button("Import Backup") {
                    showingImporter = true
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
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ActivityView(items: [url])
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let url):
                do {
                    guard url.startAccessingSecurityScopedResource() else {
                        alertMessage = "Could not access file."
                        return
                    }
                    defer { url.stopAccessingSecurityScopedResource() }
                    let data = try Data(contentsOf: url)
                    let count = try restoreBackup(from: data, context: modelContext)
                    alertMessage = "Imported \(count) new contact\(count == 1 ? "" : "s")."
                } catch {
                    alertMessage = "Import failed: \(error.localizedDescription)"
                }
            case .failure(let error):
                alertMessage = error.localizedDescription
            }
        }
        .alert("Backup", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK") { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
    }
}
