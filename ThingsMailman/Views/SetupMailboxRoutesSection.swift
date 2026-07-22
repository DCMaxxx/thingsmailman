import SwiftUI

struct SetupMailboxRoutesSection: View {
    let state: AppState

    var body: some View {
        if state.setupAccounts.isEmpty {
            Section {
                ContentUnavailableView {
                    Label("No Mail Accounts Found", systemImage: "envelope")
                } description: {
                    Text("Open Mail and add an account, then refresh this list.")
                } actions: {
                    Button("Refresh", systemImage: "arrow.clockwise") {
                        Task { await state.refreshMailSetup() }
                    }
                    .disabled(state.isRefreshingMailSetup)
                }
                .frame(maxWidth: .infinity, minHeight: 250, alignment: .center)
            }
        } else {
            ForEach(state.setupAccounts) { account in
                Section {
                    MailAccountDestinationRow(account: account, state: state)
                }
            }
        }
    }
}
