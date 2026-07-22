import AppKit
import SwiftUI

struct MenuContentView: View {
    @Environment(\.openWindow) private var openWindow
    let state: AppState

    var body: some View {
        if state.mappingHealth.needsAttention {
            Button("Mailbox setup needs attention", systemImage: "exclamationmark.triangle", action: reviewMailboxes)
            Divider()
        }

        Button("Send Selection to Things", systemImage: "paperplane", action: sendSelection)
            .disabled(state.isBusy)

        Divider()
        HistoryMenu(state: state)
        Button("Setup…", systemImage: "gearshape", action: openSetup)
        Divider()
        Button("Quit Things Mailman") { NSApplication.shared.terminate(nil) }
    }

    private func sendSelection() {
        Task { await state.invoke(trigger: .menu) }
    }

    private func reviewMailboxes() {
        state.requestedSetupStep = .mailboxes
        openSetup()
    }

    private func openSetup() {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "setup")
    }

}
