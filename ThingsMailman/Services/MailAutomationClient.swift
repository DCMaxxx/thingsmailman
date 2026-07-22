import AppKit
import Carbon
import Foundation

actor MailAutomationClient: MailAutomating {
    private let mailBundleIdentifier = "com.apple.mail"
    private let timeout: TimeInterval = 30
    private var mailboxSpecifiers: [MailboxRoute: NSAppleEventDescriptor] = [:]

    func isMailRunning() -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: mailBundleIdentifier).isEmpty
    }

    func isMailFrontmost() -> Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == mailBundleIdentifier
    }

    func determineAuthorization(askUser: Bool) -> MailAuthorizationState {
        guard isMailRunning() else { return .mailNotRunning }
        var target = AEAddressDesc()
        let bytes = Array(mailBundleIdentifier.utf8)
        let creationStatus = bytes.withUnsafeBytes { pointer in
            AECreateDesc(DescType(typeApplicationBundleID), pointer.baseAddress, bytes.count, &target)
        }
        guard creationStatus == noErr else { return .denied }
        defer { AEDisposeDesc(&target) }
        let status = AEDeterminePermissionToAutomateTarget(
            &target,
            AEEventClass(typeWildCard),
            AEEventID(typeWildCard),
            askUser
        )
        switch status {
        case noErr: return .authorized
        case OSStatus(errAEEventNotPermitted): return .denied
        default: return askUser ? .denied : .notDetermined
        }
    }

    func selectedMessages() throws -> [MessageReference] {
        guard isMailRunning() else { throw MailAutomationError.mailNotRunning }
        var selection = try get(MailEventBuilder.property(MailEventCodes.selectionProperty))
        if selection.numberOfItems == 0 {
            let viewer = MailEventBuilder.object(desiredClass: MailEventCodes.messageViewerClass, index: 1)
            if let viewerSelection = try? get(MailEventBuilder.property(MailEventCodes.selectedMessagesProperty, of: viewer)) {
                selection = viewerSelection
            }
        }
        guard selection.numberOfItems > 0 else { return [] }
        return try (1...selection.numberOfItems).compactMap { index in
            guard let descriptor = selection.atIndex(index) else { return nil }
            let subject = try stringProperty(MailEventCodes.subjectProperty, of: descriptor) ?? "(No Subject)"
            guard let mailbox = try? get(MailEventBuilder.property(MailEventCodes.mailboxProperty, of: descriptor)) else {
                return MessageReference(token: descriptor.data, subject: subject, accountIdentifier: "local")
            }
            let accountID: String
            if let account = try? get(MailEventBuilder.property(MailEventCodes.accountProperty, of: mailbox)),
               let identifier = try? stringProperty(MailEventCodes.identifierProperty, of: account) {
                accountID = identifier
            } else {
                accountID = "local"
            }
            return MessageReference(token: descriptor.data, subject: subject, accountIdentifier: accountID)
        }
    }

    func discoverAccounts() throws -> [MailAccount] {
        let descriptors = try get(MailEventBuilder.every(MailEventCodes.accountClass))
        Telemetry.automation.info("account_references count=\(descriptors.numberOfItems, privacy: .public)")
        guard descriptors.numberOfItems > 0 else { return [] }
        return try (1...descriptors.numberOfItems).compactMap { index in
            guard let descriptor = descriptors.atIndex(index),
                  let id = try stringProperty(MailEventCodes.identifierProperty, of: descriptor),
                  let name = try stringProperty(MailEventCodes.nameProperty, of: descriptor) else { return nil }
            Telemetry.automation.info("account_properties index=\(index, privacy: .public) decoded=true")
            return MailAccount(id: id, name: name)
        }
    }

    func discoverMailboxes(for account: MailAccount?) throws -> [MailboxDescriptor] {
        let container = account.map { MailEventBuilder.object(desiredClass: MailEventCodes.accountClass, id: $0.id) }
        let scope: MailboxScope = account.map { .account(identifier: $0.id) } ?? .onMyMac
        mailboxSpecifiers = mailboxSpecifiers.filter { $0.key.scope != scope }
        var discovered: [MailboxDescriptor] = []
        try appendMailboxes(in: container, account: account, prefix: [], depth: 0, result: &discovered)
        return discovered
    }

    func validate(routes: [String: MailboxRoute]) -> [String: MailboxMappingHealth] {
        guard isMailRunning() else {
            return routes.mapValues { _ in .unavailableForValidation }
        }
        let authorization = determineAuthorization(askUser: false)
        guard authorization == .authorized else {
            return routes.mapValues { _ in authorization == .denied ? .authorizationDenied : .unavailableForValidation }
        }
        do {
            let accounts = try discoverAccounts()
            var availableRoutes: Set<MailboxRoute> = []
            let requestedScopes = Set(routes.values.map(\.scope))

            if requestedScopes.contains(.onMyMac) {
                availableRoutes.formUnion(try discoverMailboxes(for: nil).map(\.route))
            }

            for case .account(let identifier) in requestedScopes {
                guard let account = accounts.first(where: { $0.id == identifier }) else { continue }
                availableRoutes.formUnion(try discoverMailboxes(for: account).map(\.route))
            }

            return MailboxRouteValidator.health(for: routes, availableRoutes: availableRoutes)
        } catch {
            return routes.mapValues { _ in .unavailableForValidation }
        }
    }

    func forwardAndSend(_ message: MessageReference, recipient: String) -> SendDisposition {
        var stage = "restore_message"
        do {
            let source = try restoreToken(message.token)
            stage = "create_forward"
            let forward = try MailEventBuilder.event(eventClass: MailEventCodes.mail, eventID: MailEventCodes.forward)
            forward.setParam(source, forKeyword: keyDirectObject)
            forward.setParam(.init(boolean: false), forKeyword: MailEventCodes.openingWindowParameter)
            let outgoing = try send(forward)

            stage = "add_recipient"
            let create = try MailEventBuilder.event(eventClass: MailEventCodes.core, eventID: MailEventCodes.create)
            create.setParam(.init(typeCode: MailEventCodes.recipientClass), forKeyword: keyAEObjectClass)
            create.setParam(
                MailEventBuilder.insertionEnd(of: outgoing),
                forKeyword: MailEventCodes.insertHereParameter
            )
            let properties = NSAppleEventDescriptor.record()
            properties.setDescriptor(.init(string: recipient), forKeyword: MailEventCodes.addressProperty)
            create.setParam(properties, forKeyword: keyAEPropData)
            _ = try send(create)

            stage = "send_forward"
            let sendEvent = try MailEventBuilder.event(eventClass: MailEventCodes.message, eventID: MailEventCodes.send)
            sendEvent.setParam(outgoing, forKeyword: keyDirectObject)
            let result = try send(sendEvent)
            return result.booleanValue ? .accepted : .rejected(code: 0)
        } catch let error as MailAutomationError {
            let publicCode = if case .eventFailed(let code) = error { code } else { -1 }
            Telemetry.automation.error("forward_failed stage=\(stage, privacy: .public) code=\(publicCode, privacy: .public)")
            if case .eventFailed(let code) = error, code == errAETimeout { return .indeterminate(code: code) }
            if case .eventFailed(let code) = error { return .rejected(code: code) }
            return .rejected(code: -1)
        } catch {
            Telemetry.automation.error("forward_failed stage=\(stage, privacy: .public) code=-1")
            return .rejected(code: -1)
        }
    }

    func cleanUp(_ message: MessageReference, action: PostSendAction, route: MailboxRoute?) throws {
        switch action {
        case .leave:
            return
        case .trash:
            let event = try MailEventBuilder.event(eventClass: MailEventCodes.core, eventID: MailEventCodes.delete)
            event.setParam(try restoreToken(message.token), forKeyword: AEKeyword(keyDirectObject))
            _ = try send(event)
        case .archive, .move:
            guard let route else { throw MailAutomationError.mailboxNotFound }
            let event = try MailEventBuilder.event(eventClass: MailEventCodes.core, eventID: MailEventCodes.move)
            event.setParam(try restoreToken(message.token), forKeyword: AEKeyword(keyDirectObject))
            event.setParam(try resolvedMailboxDescriptor(for: route), forKeyword: MailEventCodes.insertHereParameter)
            _ = try send(event)
        }
    }

    private func appendMailboxes(
        in container: NSAppleEventDescriptor?,
        account: MailAccount?,
        prefix: [String],
        depth: Int,
        result: inout [MailboxDescriptor]
    ) throws {
        guard depth < 12 else { return }
        let list = try get(MailEventBuilder.every(MailEventCodes.mailboxClass, of: container))
        guard list.numberOfItems > 0 else { return }
        for index in 1...list.numberOfItems {
            guard let descriptor = list.atIndex(index),
                  let name = try stringProperty(MailEventCodes.nameProperty, of: descriptor) else { continue }
            if account == nil,
               (try? get(MailEventBuilder.property(MailEventCodes.accountProperty, of: descriptor))) != nil {
                continue
            }
            let components = prefix + [name]
            let scope: MailboxScope = account.map { .account(identifier: $0.id) } ?? .onMyMac
            let mailbox = MailboxDescriptor(
                id: "\(scope.persistenceKey)/\(components.joined(separator: "/"))",
                scope: scope,
                components: components
            )
            mailboxSpecifiers[mailbox.route] = descriptor
            result.append(mailbox)
            try? appendMailboxes(in: descriptor, account: account, prefix: components, depth: depth + 1, result: &result)
        }
    }

    private func resolvedMailboxDescriptor(for route: MailboxRoute) throws -> NSAppleEventDescriptor {
        if let descriptor = mailboxSpecifiers[route] { return descriptor }

        switch route.scope {
        case .onMyMac:
            _ = try discoverMailboxes(for: nil)
        case .account(let identifier):
            guard let account = try discoverAccounts().first(where: { $0.id == identifier }) else {
                throw MailAutomationError.mailboxNotFound
            }
            _ = try discoverMailboxes(for: account)
        }

        guard let descriptor = mailboxSpecifiers[route] else { throw MailAutomationError.mailboxNotFound }
        return descriptor
    }

    private func stringProperty(_ property: DescType, of container: NSAppleEventDescriptor) throws -> String? {
        try get(MailEventBuilder.property(property, of: container)).stringValue
    }

    private func get(_ object: NSAppleEventDescriptor) throws -> NSAppleEventDescriptor {
        let event = try MailEventBuilder.event(eventClass: MailEventCodes.core, eventID: MailEventCodes.getData)
        event.setParam(object, forKeyword: keyDirectObject)
        return try send(event)
    }

    private func send(_ event: NSAppleEventDescriptor) throws -> NSAppleEventDescriptor {
        do {
            let reply = try event.sendEvent(options: [.waitForReply, .dontRecord], timeout: timeout)
            return try MailEventBuilder.result(from: reply)
        } catch let error as MailAutomationError {
            if case .eventFailed(let code) = error {
                Telemetry.automation.error("Apple Event failed code=\(code, privacy: .public)")
                if code == Int(errAEEventNotPermitted) { throw MailAutomationError.authorizationDenied }
            }
            throw error
        } catch let error as NSError {
            Telemetry.automation.error("Apple Event failed code=\(error.code, privacy: .public)")
            if error.code == Int(errAEEventNotPermitted) { throw MailAutomationError.authorizationDenied }
            throw MailAutomationError.eventFailed(code: error.code)
        }
    }

    private func restoreToken(_ data: Data) throws -> NSAppleEventDescriptor {
        guard let descriptor = NSAppleEventDescriptor(descriptorType: OSType(typeObjectSpecifier), data: data) else {
            throw MailAutomationError.malformedReply
        }
        return descriptor
    }
}
