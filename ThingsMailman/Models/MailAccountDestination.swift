import Foundation

struct MailAccountDestination: Codable, Equatable, Sendable {
    var action: PostSendAction
    var route: MailboxRoute?

    static let leaveInMail = MailAccountDestination(action: .leave, route: nil)
}
