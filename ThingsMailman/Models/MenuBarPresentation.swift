import Foundation

struct MenuBarPresentation: Equatable, Sendable {
    let symbol: String
    let showsMailboxReview: Bool
    let affectedAccounts: [String]

    init(activity: MenuBarActivity, health: [String: MailboxMappingHealth]) {
        affectedAccounts = health.filter { $0.value.needsAttention }.map(\.key).sorted()
        showsMailboxReview = !affectedAccounts.isEmpty
        switch activity {
        case .forwarding:
            symbol = "arrow.triangle.2.circlepath"
        case .sent:
            symbol = "checkmark.circle"
        case .idle:
            symbol = showsMailboxReview ? "exclamationmark.triangle" : "envelope.badge.fill"
        }
    }
}
