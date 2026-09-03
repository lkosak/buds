import SwiftUI

/// A compact popover for the common case: log today's contact in one tap.
/// "Add a Note or Change Date" escalates to the full InteractionDetailView sheet.
struct QuickLogPopoverView: View {
    let onLog: (ContactChannel) -> Void
    let onExpand: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text(Date(), style: .date)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 14) {
                ForEach(ContactChannel.allCases, id: \.self) { ch in
                    VStack(spacing: 4) {
                        Button {
                            onLog(ch)
                        } label: {
                            Image(systemName: ch.systemImage)
                                .font(.title3)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.glass)

                        Text(ch.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .fixedSize()
                    }
                }
            }

            Button("Add a Note or Change Date", action: onExpand)
                .font(.caption)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(20)
        .fixedSize()
    }
}
