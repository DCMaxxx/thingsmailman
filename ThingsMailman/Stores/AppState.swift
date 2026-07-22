import AppKit
import Observation

@MainActor
@Observable
final class AppState {
    let preferences: PreferencesStore
    let mappingHealth: MappingHealthStore
    let history: SessionHistory

    private let automation: any MailAutomating
    private let addressStore: any ThingsAddressStoring
    private let launchAtLogin: any LaunchAtLoginControlling
    private let coordinator: ProcessingCoordinator
    private let shortcutManager: GlobalShortcutManager

    var thingsAddress = ""
    var mailAuthorization: MailAuthorizationState = .notDetermined
    var accounts: [MailAccount] = []
    var mailboxesByAccount: [String: [MailboxDescriptor]] = [:]
    var isBusy = false
    private(set) var isRefreshingMailSetup = false
    private(set) var menuBarActivity: MenuBarActivity = .idle
    var shortcutConflict = false
    var requestedSetupStep: SetupStep?
    private(set) var hasStarted = false
    private var menuBarActivityID = 0

    init(
        automation: any MailAutomating = MailAutomationClient(),
        addressStore: any ThingsAddressStoring = UserDefaultsThingsAddressStore(),
        notifier: any FailureNotifying = FailureNotifier(),
        launchAtLogin: any LaunchAtLoginControlling = LaunchAtLoginService(),
        preferences: PreferencesStore = PreferencesStore(),
        mappingHealth: MappingHealthStore = MappingHealthStore(),
        history: SessionHistory = SessionHistory(),
        shortcutManager: GlobalShortcutManager = GlobalShortcutManager()
    ) {
        self.automation = automation
        self.addressStore = addressStore
        self.launchAtLogin = launchAtLogin
        self.preferences = preferences
        self.mappingHealth = mappingHealth
        self.history = history
        self.shortcutManager = shortcutManager
        coordinator = ProcessingCoordinator(automation: automation, notifier: notifier)
    }

    var isAddressValid: Bool { ThingsAddressValidator.isValid(thingsAddress) }
    var setupAccounts: [MailAccount] {
        var result = accounts
        let localIdentifier = MailboxScope.onMyMac.persistenceKey
        if !(mailboxesByAccount[localIdentifier] ?? []).isEmpty
            || preferences.accountDestinations[localIdentifier] != nil {
            result.append(MailAccount(id: localIdentifier, name: "On My Mac"))
        }
        return result
    }

    var menuBarPresentation: MenuBarPresentation {
        MenuBarPresentation(activity: menuBarActivity, health: mappingHealth.healthByAccount)
    }

    var menuBarSymbol: String {
        menuBarPresentation.symbol
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        thingsAddress = (try? await addressStore.loadAddress()) ?? ""
        registerCurrentShortcut()
        await refreshMailSetup()
        Telemetry.lifecycle.info("started setupComplete=\(self.preferences.isSetupComplete, privacy: .public)")
    }

    func requestMailAuthorization() async {
        mailAuthorization = await automation.determineAuthorization(askUser: true)
        if mailAuthorization == .authorized { await refreshMailSetup() }
    }

    func refreshMailSetup() async {
        guard !isRefreshingMailSetup else { return }
        isRefreshingMailSetup = true
        defer { isRefreshingMailSetup = false }
        await refreshMailState()
        await loadMailboxes()
    }

    func refreshMailState() async {
        guard await automation.isMailRunning() else {
            mailAuthorization = .mailNotRunning
            mappingHealth.markUnavailablePreservingWarnings(for: preferences.activeMappings.keys)
            Telemetry.automation.info("mail_state running=false")
            return
        }
        mailAuthorization = await automation.determineAuthorization(askUser: false)
        Telemetry.automation.info("mail_state authorization=\(self.mailAuthorization.rawValue, privacy: .public)")
        guard mailAuthorization == .authorized else {
            let denied: MailboxMappingHealth = mailAuthorization == .denied ? .authorizationDenied : .unavailableForValidation
            var health = preferences.activeMappings.mapValues { _ in denied }
            for account in accounts
            where preferences.destination(for: account.id).action.needsMailboxMapping {
                health[account.id] = denied
            }
            mappingHealth.replace(with: health)
            return
        }
        do {
            accounts = try await automation.discoverAccounts()
        } catch {
            accounts = []
            let code: Int
            if let automationError = error as? MailAutomationError,
               case .eventFailed(let eventCode) = automationError {
                code = eventCode
            } else {
                code = (error as NSError).code
            }
            Telemetry.automation.error("account_discovery_failed code=\(code, privacy: .public)")
        }
        preferences.ensureDestinations(for: accounts)
        Telemetry.automation.info("mail_discovery accounts=\(self.accounts.count, privacy: .public)")
        await validateMappings()
    }

    func loadMailboxes() async {
        guard mailAuthorization == .authorized else { return }
        var discovered: [String: [MailboxDescriptor]] = [:]
        discovered[MailboxScope.onMyMac.persistenceKey] = (try? await automation.discoverMailboxes(for: nil)) ?? []
        for account in accounts {
            discovered[account.id] = (try? await automation.discoverMailboxes(for: account)) ?? []
        }
        mailboxesByAccount = discovered
        let mailboxCount = discovered.values.reduce(0) { $0 + $1.count }
        Telemetry.automation.info("mailbox_discovery scopes=\(discovered.count, privacy: .public) mailboxes=\(mailboxCount, privacy: .public)")
    }

    func validateMappings() async {
        let previous = mappingHealth.healthByAccount
        var updated = await automation.validate(routes: preferences.activeMappings)
        for account in setupAccounts {
            if preferences.destination(for: account.id).action.needsMailboxMapping,
               preferences.activeMappings[account.id] == nil {
                updated[account.id] = .missing
            }
        }
        for (account, health) in updated where health == .unavailableForValidation && (previous[account]?.needsAttention ?? false) {
            updated[account] = previous[account]
        }
        for (account, health) in updated where health == .missing && previous[account] == .valid {
            updated[account] = .stale(previousPath: preferences.activeMappings[account]?.displayPath ?? "Unknown")
        }
        mappingHealth.replace(with: updated)
        let warnings = updated.values.count(where: \.needsAttention)
        Telemetry.automation.info("mapping_validation routes=\(updated.count, privacy: .public) warnings=\(warnings, privacy: .public)")
    }

    func saveSetup() async {
        guard isAddressValid, mailAuthorization == .authorized else { return }
        do {
            try await persistAddress()
            preferences.isSetupComplete = true
            try await launchAtLogin.setEnabled(preferences.launchAtLogin)
        } catch {
            showAlert(title: "Couldn’t save setup", message: error.localizedDescription)
        }
    }

    func saveAddress() async {
        guard preferences.isSetupComplete, isAddressValid else { return }
        do {
            try await persistAddress()
        } catch {
            showAlert(title: "Couldn’t save address", message: error.localizedDescription)
        }
    }

    func updateLaunchAtLogin() async {
        guard preferences.isSetupComplete else { return }
        do { try await launchAtLogin.setEnabled(preferences.launchAtLogin) }
        catch { showAlert(title: "Launch at Login", message: error.localizedDescription) }
    }

    func updateShortcut(_ candidate: GlobalShortcut) {
        let previous = preferences.shortcut
        let accepted = shortcutManager.register(candidate) { [weak self] in
            Task { await self?.invoke(trigger: .hotkey) }
        }
        if accepted {
            preferences.shortcut = candidate
            shortcutConflict = false
        } else {
            preferences.shortcut = previous
            shortcutConflict = true
        }
    }

    func updateDestinationAction(_ action: PostSendAction, for accountIdentifier: String) {
        preferences.setAction(action, for: accountIdentifier)
        Task { await validateMappings() }
    }

    func updateDestinationRoute(_ route: MailboxRoute?, for accountIdentifier: String) {
        preferences.setRoute(route, for: accountIdentifier)
        Task { await validateMappings() }
    }

    func openMailPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func openMail() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.mail"),
              NSWorkspace.shared.open(url) else {
            showAlert(
                title: "Couldn’t open Mail",
                message: "Open Mail manually, then return to Things Mailman."
            )
            return
        }
    }

    func invoke(trigger: BatchTrigger) async {
        guard !isBusy else { return }
        isBusy = true
        menuBarActivityID += 1
        let activityID = menuBarActivityID
        menuBarActivity = .forwarding
        let started = ContinuousClock.now
        let result = await coordinator.process(
            trigger: trigger,
            recipient: thingsAddress,
            destinations: preferences.accountDestinations
        )
        let finalResult: BatchResult
        if case .confirmationRequired(let count) = result, confirmLargeBatch(count: count) {
            finalResult = await coordinator.process(
                trigger: trigger,
                confirmation: .confirmed,
                recipient: thingsAddress,
                destinations: preferences.accountDestinations
            )
        } else {
            finalResult = result
        }

        let elapsed = started.duration(to: .now)
        if elapsed < .seconds(2) {
            try? await Task.sleep(for: .seconds(2) - elapsed)
        }

        handle(finalResult)
        isBusy = false
        if finalResult.hasAcceptedSend {
            menuBarActivity = .sent
            try? await Task.sleep(for: .seconds(3))
            if menuBarActivityID == activityID { menuBarActivity = .idle }
        } else if menuBarActivityID == activityID {
            menuBarActivity = .idle
        }
    }

    @discardableResult
    func showHistoryDetail(_ entry: HistoryEntry) -> Bool {
        let message = [entry.subject, entry.accountIdentifier, entry.detail]
            .compactMap { $0 }
            .joined(separator: "\n\n")

        guard entry.outcome.offersMailboxReview else {
            showAlert(title: entry.outcome.title, message: message)
            return false
        }

        let alert = NSAlert()
        alert.messageText = entry.outcome.title
        alert.informativeText = message
        alert.addButton(withTitle: "Review Mailboxes…")
        alert.addButton(withTitle: "Dismiss")
        return alert.runModal() == .alertFirstButtonReturn
    }

    private func registerCurrentShortcut() {
        shortcutConflict = !shortcutManager.register(preferences.shortcut) { [weak self] in
            Task { await self?.invoke(trigger: .hotkey) }
        }
    }

    private func handle(_ result: BatchResult) {
        switch result {
        case .completed(let entries):
            history.record(entries)
        case .confirmationRequired:
            break
        case .emptySelection:
            preflightAlert("No messages selected", "Select messages in Mail, then try again.")
        case .mailNotRunning:
            preflightAlert("Mail isn’t running", "Open Mail and select the messages you want to send.")
        case .mailNotFrontmost:
            break
        case .tooMany(let count):
            preflightAlert("Too many messages", "Select 100 or fewer messages. Nothing was sent from this \(count)-message selection.")
        case .alreadyProcessing:
            break
        case .missingAddress:
            preflightAlert("Things address missing", "Open Setup and enter your private @things.email address.")
        case .authorizationDenied:
            preflightAlert("Mail access required", "Allow Things Mailman to control Mail in System Settings.")
        }
    }

    private func confirmLargeBatch(count: Int) -> Bool {
        let alert = NSAlert()
        alert.messageText = "Send \(count) messages to Things?"
        alert.informativeText = "Each selected message will be forwarded separately."
        alert.addButton(withTitle: "Send")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }

    private func preflightAlert(_ title: String, _ message: String) {
        showAlert(title: title, message: message)
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func persistAddress() async throws {
        try await addressStore.saveAddress(
            thingsAddress.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        )
    }
}

private extension BatchResult {
    var hasAcceptedSend: Bool {
        guard case .completed(let entries) = self else { return false }
        return entries.contains { entry in
            entry.outcome == .sent || entry.outcome == .sentCleanupFailed
        }
    }
}
