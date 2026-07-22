import Foundation
import Observation

@MainActor
@Observable
final class MappingHealthStore {
    private let defaults: UserDefaults
    private let key = "mappingHealth"

    private(set) var healthByAccount: [String: MailboxMappingHealth]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        healthByAccount = Self.load(from: defaults.data(forKey: key))
    }

    var needsAttention: Bool { healthByAccount.values.contains(where: \.needsAttention) }

    var affectedAccounts: [String] {
        healthByAccount.filter { $0.value.needsAttention }.map(\.key).sorted()
    }

    func replace(with health: [String: MailboxMappingHealth]) {
        healthByAccount = health
        defaults.set(try? JSONEncoder().encode(health), forKey: key)
    }

    func markUnavailablePreservingWarnings(for accountIdentifiers: some Sequence<String>) {
        for identifier in accountIdentifiers where !(healthByAccount[identifier]?.needsAttention ?? false) {
            healthByAccount[identifier] = .unavailableForValidation
        }
        defaults.set(try? JSONEncoder().encode(healthByAccount), forKey: key)
    }

    private static func load(from data: Data?) -> [String: MailboxMappingHealth] {
        guard let data else { return [:] }
        return (try? JSONDecoder().decode([String: MailboxMappingHealth].self, from: data)) ?? [:]
    }
}
