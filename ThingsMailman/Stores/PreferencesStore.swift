import Foundation
import Observation

@MainActor
@Observable
final class PreferencesStore {
    private enum Key {
        static let accountDestinations = "accountDestinations"
        static let shortcut = "globalShortcut"
        static let launchAtLogin = "launchAtLogin"
        static let setupComplete = "setupComplete"
    }

    private let defaults: UserDefaults

    var accountDestinations: [String: MailAccountDestination] {
        didSet { save(accountDestinations, key: Key.accountDestinations) }
    }
    var shortcut: GlobalShortcut { didSet { save(shortcut, key: Key.shortcut) } }
    var launchAtLogin: Bool { didSet { defaults.set(launchAtLogin, forKey: Key.launchAtLogin) } }
    var isSetupComplete: Bool { didSet { defaults.set(isSetupComplete, forKey: Key.setupComplete) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        accountDestinations = Self.decode(
            [String: MailAccountDestination].self,
            from: defaults.data(forKey: Key.accountDestinations)
        ) ?? [:]
        let storedShortcut = Self.decode(GlobalShortcut.self, from: defaults.data(forKey: Key.shortcut))
        shortcut = storedShortcut ?? .default
        launchAtLogin = defaults.object(forKey: Key.launchAtLogin) as? Bool ?? true
        isSetupComplete = defaults.bool(forKey: Key.setupComplete)
    }

    var activeMappings: [String: MailboxRoute] {
        accountDestinations.compactMapValues { destination in
            destination.action.needsMailboxMapping ? destination.route : nil
        }
    }

    func destination(for accountIdentifier: String) -> MailAccountDestination {
        accountDestinations[accountIdentifier] ?? .leaveInMail
    }

    func setAction(_ action: PostSendAction, for accountIdentifier: String) {
        var destination = destination(for: accountIdentifier)
        destination.action = action
        if !action.needsMailboxMapping { destination.route = nil }
        accountDestinations[accountIdentifier] = destination
    }

    func setRoute(_ route: MailboxRoute?, for accountIdentifier: String) {
        var destination = destination(for: accountIdentifier)
        destination.route = route
        accountDestinations[accountIdentifier] = destination
    }

    func ensureDestinations(for accounts: [MailAccount]) {
        for account in accounts where accountDestinations[account.id] == nil {
            accountDestinations[account.id] = .leaveInMail
        }
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        defaults.set(try? JSONEncoder().encode(value), forKey: key)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
