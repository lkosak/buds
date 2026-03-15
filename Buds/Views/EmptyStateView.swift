import SwiftUI

struct EmptyStateView: View {
    let onAddBud: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No Buds Yet", systemImage: "person.2.fill")
        } description: {
            Text("Add friends from your contacts to keep in touch with them.")
        } actions: {
            Button(action: onAddBud) {
                Text("Add a Bud")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
