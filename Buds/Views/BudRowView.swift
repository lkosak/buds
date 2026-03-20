import SwiftUI

struct BudRowView: View {
    let bud: Bud
    let photo: UIImage?
    let onTalked: () -> Void
    let onTogglePin: () -> Void

    private var urgency: UrgencyLevel {
        .from(lastContact: bud.lastContactDate, cadenceDays: bud.contactCadenceDays)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Contact photo or initials
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Text(initials(for: bud.name))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
            }

            // Name and time
            VStack(alignment: .leading, spacing: 2) {
                Text(bud.name)
                    .font(.body)
                    .fontWeight(.medium)
                Text(relativeTimeString(from: bud.lastContactDate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if bud.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            // Urgency dot
            Circle()
                .fill(urgency.color)
                .frame(width: 12, height: 12)
        }
        .swipeActions(edge: .leading) {
            Button {
                onTalked()
            } label: {
                Label("Talked", systemImage: "message.fill")
            }
            .tint(.green)
        }
        .swipeActions(edge: .trailing) {
            Button {
                onTogglePin()
            } label: {
                Label(bud.isPinned ? "Unpin" : "Pin", systemImage: bud.isPinned ? "pin.slash.fill" : "pin.fill")
            }
            .tint(.orange)
        }
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }
}
