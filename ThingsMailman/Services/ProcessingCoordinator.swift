import Foundation

actor ProcessingCoordinator {
    private let automation: any MailAutomating
    private let notifier: any FailureNotifying
    private var isProcessing = false
    private var pendingConfirmation: (
        messages: [MessageReference],
        recipient: String,
        destinations: [String: MailAccountDestination]
    )?

    init(automation: any MailAutomating, notifier: any FailureNotifying) {
        self.automation = automation
        self.notifier = notifier
    }

    func process(
        trigger: BatchTrigger,
        confirmation: BatchConfirmation = .notRequested,
        recipient: String?,
        destinations: [String: MailAccountDestination]
    ) async -> BatchResult {
        guard !isProcessing else { return .alreadyProcessing }
        isProcessing = true
        defer { isProcessing = false }

        guard let recipient, ThingsAddressValidator.isValid(recipient) else { return .missingAddress }
        guard await automation.isMailRunning() else { return .mailNotRunning }
        if case .hotkey = trigger, !(await automation.isMailFrontmost()) { return .mailNotFrontmost }
        guard await automation.determineAuthorization(askUser: false) == .authorized else { return .authorizationDenied }

        let messages: [MessageReference]
        let batchRecipient: String
        let batchDestinations: [String: MailAccountDestination]
        if confirmation == .confirmed, let pendingConfirmation {
            messages = pendingConfirmation.messages
            batchRecipient = pendingConfirmation.recipient
            batchDestinations = pendingConfirmation.destinations
            self.pendingConfirmation = nil
        } else {
            pendingConfirmation = nil
            do {
                messages = try await automation.selectedMessages()
            } catch {
                return .authorizationDenied
            }
            batchRecipient = recipient
            batchDestinations = destinations
        }
        guard !messages.isEmpty else { return .emptySelection }
        guard messages.count <= 100 else { return .tooMany(messages.count) }
        if messages.count > 10, confirmation != .confirmed {
            pendingConfirmation = (messages, recipient, destinations)
            return .confirmationRequired(messages.count)
        }

        let routes = batchDestinations.compactMapValues { destination in
            destination.action.needsMailboxMapping ? destination.route : nil
        }
        let health = routes.isEmpty ? [:] : await automation.validate(routes: routes)
        var outcomes: [HistoryEntry] = []
        outcomes.reserveCapacity(messages.count)

        for message in messages {
            let destination = batchDestinations[message.accountIdentifier] ?? .leaveInMail
            let route = destination.route
            if destination.action.needsMailboxMapping,
               (route == nil || health[message.accountIdentifier] != .valid) {
                outcomes.append(HistoryEntry(
                    subject: message.subject,
                    accountIdentifier: message.accountIdentifier,
                    outcome: .skippedMapping,
                    detail: "The mailbox mapping for this account is unavailable."
                ))
                continue
            }

            let disposition = await automation.forwardAndSend(message, recipient: batchRecipient)
            switch disposition {
            case .accepted:
                do {
                    try await automation.cleanUp(message, action: destination.action, route: route)
                    outcomes.append(HistoryEntry(subject: message.subject, accountIdentifier: message.accountIdentifier, outcome: .sent))
                } catch {
                    outcomes.append(HistoryEntry(
                        subject: message.subject,
                        accountIdentifier: message.accountIdentifier,
                        outcome: .sentCleanupFailed,
                        detail: "Mail accepted the forward, but filing the original failed."
                    ))
                }
            case .rejected(let code):
                outcomes.append(HistoryEntry(
                    subject: message.subject,
                    accountIdentifier: message.accountIdentifier,
                    outcome: .sendFailed,
                    detail: "Mail rejected the send (error \(code))."
                ))
            case .indeterminate(let code):
                outcomes.append(HistoryEntry(
                    subject: message.subject,
                    accountIdentifier: message.accountIdentifier,
                    outcome: .sendIndeterminate,
                    detail: "Mail did not confirm the send before timeout (error \(code)). The message was not retried."
                ))
            }
        }

        let failures = outcomes.count(where: { $0.outcome.isFailure })
        if failures > 0 { await notifier.notifyFirstFailure(count: failures) }
        Telemetry.processing.info("batch count=\(outcomes.count, privacy: .public) failures=\(failures, privacy: .public)")
        return .completed(outcomes)
    }
}
