import Foundation
@testable import ThingsMailman

actor MockMailAutomation: MailAutomating {
    var running = true
    var frontmost = true
    var authorization: MailAuthorizationState = .authorized
    var messages: [MessageReference] = []
    var health: [String: MailboxMappingHealth] = [:]
    var dispositions: [SendDisposition] = []
    var cleanupFailures: Set<UUID> = []
    var forwardingDelay: Duration?

    private(set) var selectionCalls = 0
    private(set) var validationCalls = 0
    private(set) var forwardCalls = 0
    private(set) var cleanupCalls = 0

    func isMailRunning() -> Bool { running }
    func isMailFrontmost() -> Bool { frontmost }
    func determineAuthorization(askUser: Bool) -> MailAuthorizationState { authorization }

    func selectedMessages() -> [MessageReference] {
        selectionCalls += 1
        return messages
    }

    func discoverAccounts() -> [MailAccount] { [] }
    func discoverMailboxes(for account: MailAccount?) -> [MailboxDescriptor] { [] }

    func validate(routes: [String: MailboxRoute]) -> [String: MailboxMappingHealth] {
        validationCalls += 1
        return health
    }

    func forwardAndSend(_ message: MessageReference, recipient: String) async -> SendDisposition {
        forwardCalls += 1
        if let forwardingDelay { try? await Task.sleep(for: forwardingDelay) }
        return dispositions.isEmpty ? .accepted : dispositions.removeFirst()
    }

    func cleanUp(_ message: MessageReference, action: PostSendAction, route: MailboxRoute?) throws {
        cleanupCalls += 1
        if cleanupFailures.contains(message.id) { throw MailAutomationError.eventFailed(code: -1) }
    }
}
