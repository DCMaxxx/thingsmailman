import SwiftUI

struct SetupHeaderView: View {
    let mode: SetupPresentationMode

    var body: some View {
        Label {
            VStack(alignment: .leading) {
                Text(mode == .editing ? "Things Mailman" : "Set up Things Mailman")
                    .font(.title)
                    .bold()
                Text("Post selected Mail messages to Things, then file the originals your way.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: "envelope.badge.fill")
                .font(.title)
                .accessibilityHidden(true)
        }
    }
}
