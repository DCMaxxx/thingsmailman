import SwiftUI

struct HistoryMenu: View {
    @Environment(\.openWindow) private var openWindow
    let state: AppState

    var body: some View {
        Menu("History", systemImage: "clock.arrow.circlepath") {
            if state.history.entries.isEmpty {
                Text("No activity this session")
            } else {
                ForEach(state.history.entries) { entry in
                    if entry.outcome.isHistoryInteractive {
                        Button {
                            showHistoryDetail(entry)
                        } label: {
                            HistoryMenuRow(entry: entry)
                        }
                    } else {
                        HistoryMenuRow(entry: entry)
                    }
                }
                Divider()
                Button("Clear History", action: state.history.clear)
            }
        }
    }

    private func showHistoryDetail(_ entry: HistoryEntry) {
        guard state.showHistoryDetail(entry) else { return }
        state.requestedSetupStep = .mailboxes
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "setup")
    }
}
