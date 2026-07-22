import Foundation

enum MailAutomationError: Error, Equatable, Sendable {
    case mailNotRunning
    case authorizationDenied
    case malformedReply
    case eventFailed(code: Int)
    case mailboxNotFound
}
