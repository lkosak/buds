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

private struct SyncStatusRow: View {
    private var monitor = SyncMonitor.shared

    var body: some View {
        LabeledContent("iCloud Sync") {
            VStack(alignment: .trailing, spacing: 2) {
                Text(summary)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }

    private var summary: String {
        if case .unavailable = monitor.accountState { return "Off" }
        if monitor.isSyncing { return "Syncing…" }
        if let lastSuccess = monitor.lastSuccess {
            return "Synced \(lastSuccess.formatted(.relative(presentation: .named)))"
        }
        return monitor.lastError == nil ? "Waiting" : "Failing"
    }

    private var detail: String? {
        if case .unavailable(let reason) = monitor.accountState { return reason }
        return monitor.lastError
    }
}

private struct ExportFile: Identifiable {
    let url: URL
    var id: URL { url }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Bud> { $0.isArchived })
    private var archivedBuds: [Bud]

    @State private var exportFile: ExportFile?
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
                SyncStatusRow()

                Button("Export Backup") {
                    do {
                        let data = try makeBackupData(context: modelContext)
                        let date = ISO8601DateFormatter().string(from: Date()).prefix(10)
                        let url = FileManager.default.temporaryDirectory
                            .appendingPathComponent("buds-\(date).json")
                        try data.write(to: url)
                        exportFile = ExportFile(url: url)
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
        .sheet(item: $exportFile) { file in
            ActivityView(items: [file.url])
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
