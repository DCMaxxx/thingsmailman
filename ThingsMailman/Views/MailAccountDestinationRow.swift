import SwiftUI

struct MailAccountDestinationRow: View {
    let account: MailAccount
    let state: AppState
    @State private var action: PostSendAction
    @State private var route: MailboxRoute?

    init(account: MailAccount, state: AppState) {
        self.account = account
        self.state = state
        let destination = state.preferences.destination(for: account.id)
        _action = State(initialValue: destination.action)
        _route = State(initialValue: destination.route)
    }

    var body: some View {
        Picker(account.name, selection: $action) {
            ForEach(PostSendAction.allCases) { action in
                Text(action.title).tag(action)
            }
        }
        .onChange(of: action) { _, newValue in
            if !newValue.needsMailboxMapping { route = nil }
            state.updateDestinationAction(newValue, for: account.id)
        }

        if action.needsMailboxMapping {
            MailboxDestinationPickerRow(
                route: $route,
                mailboxes: state.mailboxesByAccount[account.id] ?? [],
                title: action == .archive ? "Archive folder" : "Destination folder",
                needsAttention: destinationNeedsAttention,
                onChange: updateRoute
            )
        }
    }

    private var destinationNeedsAttention: Bool {
        route == nil || (state.mappingHealth.healthByAccount[account.id]?.needsAttention ?? false)
    }

    private func updateRoute(_ newValue: MailboxRoute?) {
        state.updateDestinationRoute(newValue, for: account.id)
    }
}
