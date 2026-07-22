import Foundation

protocol MailAutomating: Sendable {
    func isMailRunning() async -> Bool
    func isMailFrontmost() async -> Bool
    func determineAuthorization(askUser: Bool) async -> MailAuthorizationState
    func selectedMessages() async throws -> [MessageReference]
    func discoverAccounts() async throws -> [MailAccount]
    func discoverMailboxes(for account: MailAccount?) async throws -> [MailboxDescriptor]
    func validate(routes: [String: MailboxRoute]) async -> [String: MailboxMappingHealth]
    func forwardAndSend(_ message: MessageReference, recipient: String) async -> SendDisposition
    func cleanUp(_ message: MessageReference, action: PostSendAction, route: MailboxRoute?) async throws
}
