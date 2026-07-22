import Foundation

struct MailboxDescriptor: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let scope: MailboxScope
    let components: [String]

    var route: MailboxRoute { MailboxRoute(scope: scope, components: components) }
    var displayName: String { components.joined(separator: " / ") }
}
