import SwiftUI

struct MenuBarLabelView: View {
    let state: AppState

    var body: some View {
        Label("Things Mailman", systemImage: state.menuBarSymbol)
            .symbolEffect(
                .variableColor.iterative,
                options: .repeating,
                isActive: state.menuBarActivity == .forwarding
            )
            .accessibilityLabel(
                state.menuBarActivity == .forwarding
                    ? "Things Mailman is forwarding"
                    : "Things Mailman"
            )
    }
}
