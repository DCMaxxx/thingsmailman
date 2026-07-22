import Foundation
import Testing
@testable import ThingsMailman

struct ProcessingCoordinatorTests {
    private let recipient = "private@things.email"

    @Test func emptySelectionDoesNotSendOrNotify() async {
        let (coordinator, mail, notifier) = makeCoordinator()
        let result = await coordinator.process(trigger: .menu, recipient: recipient, destinations: [:])
        #expect(result == .emptySelection)
        #expect(await mail.forwardCalls == 0)
        #expect(await notifier.requests.isEmpty)
    }

    @Test func mixedValidAndInvalidAccountsProcessesValidMessages() async {
        let (coordinator, mail, _) = makeCoordinator()
        let valid = message("Valid", account: "work")
        let invalid = message("Invalid", account: "home")
        await mail.configure(messages: [valid, invalid], health: ["work": .valid, "home": .missing])
        let routes = [
            "work": MailboxRoute(scope: .account(identifier: "work"), components: ["Archive"]),
            "home": MailboxRoute(scope: .account(identifier: "home"), components: ["Archive"])
        ]

        let result = await coordinator.process(
            trigger: .menu,
            recipient: recipient,
            destinations: routes.mapValues { MailAccountDestination(action: .archive, route: $0) }
        )
        guard case .completed(let entries) = result else { Issue.record("Expected completed batch"); return }
        #expect(entries.map(\.outcome) == [.sent, .skippedMapping])
        #expect(await mail.forwardCalls == 1)
        #expect(await mail.cleanupCalls == 1)
    }

    @Test func recordsRejectionIndeterminateAndCleanupFailureSeparately() async {
        let (coordinator, mail, notifier) = makeCoordinator()
        let rejected = message("Rejected")
        let timedOut = message("Timed out")
        let cleanup = message("Cleanup")
        await mail.configure(
            messages: [rejected, timedOut, cleanup],
            dispositions: [.rejected(code: -100), .indeterminate(code: -1712), .accepted],
            cleanupFailures: [cleanup.id]
        )

        let result = await coordinator.process(trigger: .menu, recipient: recipient, destinations: [:])
        guard case .completed(let entries) = result else { Issue.record("Expected completed batch"); return }
        #expect(entries.map(\.outcome) == [.sendFailed, .sendIndeterminate, .sentCleanupFailed])
        #expect(await notifier.requests == [3])
    }

    @Test func confirmationRequiredForElevenThroughOneHundred() async {
        let (coordinator, mail, _) = makeCoordinator()
        await mail.configure(messages: (0..<11).map { message("Message \($0)") })
        let first = await coordinator.process(trigger: .menu, recipient: recipient, destinations: [:])
        #expect(first == .confirmationRequired(11))
        #expect(await mail.forwardCalls == 0)

        let confirmed = await coordinator.process(
            trigger: .menu,
            confirmation: .confirmed,
            recipient: recipient,
            destinations: [:]
        )
        guard case .completed(let entries) = confirmed else { Issue.record("Expected confirmed batch"); return }
        #expect(entries.count == 11)
        #expect(await mail.selectionCalls == 1)
    }

    @Test func rejectsAboveOneHundredBeforeAnyMutation() async {
        let (coordinator, mail, _) = makeCoordinator()
        await mail.configure(messages: (0..<101).map { message("Message \($0)") })
        let result = await coordinator.process(trigger: .menu, recipient: recipient, destinations: [:])
        #expect(result == .tooMany(101))
        #expect(await mail.forwardCalls == 0)
        #expect(await mail.cleanupCalls == 0)
        #expect(await mail.validationCalls == 0)
    }

    @Test func reentrantTriggerIsIgnoredWhileBusy() async {
        let (coordinator, mail, _) = makeCoordinator()
        await mail.configure(messages: [message("Slow")], forwardingDelay: .milliseconds(150))
        async let first = coordinator.process(trigger: .menu, recipient: recipient, destinations: [:])
        try? await Task.sleep(for: .milliseconds(20))
        let second = await coordinator.process(trigger: .hotkey, recipient: recipient, destinations: [:])
        #expect(second == .alreadyProcessing)
        _ = await first
        #expect(await mail.forwardCalls == 1)
    }

    @Test func hotkeyRequiresMailFrontmost() async {
        let (coordinator, mail, _) = makeCoordinator()
        await mail.setFrontmost(false)
        let result = await coordinator.process(trigger: .hotkey, recipient: recipient, destinations: [:])
        #expect(result == .mailNotFrontmost)
        #expect(await mail.selectionCalls == 0)
    }

    @Test func notificationIsNotRequestedForSuccessOrPreflight() async {
        let (coordinator, mail, notifier) = makeCoordinator()
        _ = await coordinator.process(trigger: .menu, recipient: nil, destinations: [:])
        await mail.configure(messages: [message("Success")])
        _ = await coordinator.process(trigger: .menu, recipient: recipient, destinations: [:])
        #expect(await notifier.requests.isEmpty)
    }

    private func makeCoordinator() -> (ProcessingCoordinator, MockMailAutomation, MockFailureNotifier) {
        let mail = MockMailAutomation()
        let notifier = MockFailureNotifier()
        return (ProcessingCoordinator(automation: mail, notifier: notifier), mail, notifier)
    }

    private func message(_ subject: String, account: String = "work") -> MessageReference {
        MessageReference(token: Data(subject.utf8), subject: subject, accountIdentifier: account)
    }
}

private extension MockMailAutomation {
    func configure(
        messages: [MessageReference],
        health: [String: MailboxMappingHealth] = [:],
        dispositions: [SendDisposition] = [],
        cleanupFailures: Set<UUID> = [],
        forwardingDelay: Duration? = nil
    ) {
        self.messages = messages
        self.health = health
        self.dispositions = dispositions
        self.cleanupFailures = cleanupFailures
        self.forwardingDelay = forwardingDelay
    }

    func setFrontmost(_ value: Bool) { frontmost = value }
}
