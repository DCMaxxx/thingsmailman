import Foundation
import Testing
@testable import ThingsMailman

@MainActor
struct AccountDestinationTests {
    @Test func accountsKeepIndependentFilingDestinations() {
        let store = PreferencesStore(defaults: isolatedDefaults())
        let archive = MailboxRoute(scope: .account(identifier: "work"), components: ["Archive"])

        store.setAction(.archive, for: "work")
        store.setRoute(archive, for: "work")
        store.setAction(.trash, for: "personal")

        #expect(store.destination(for: "work") == MailAccountDestination(action: .archive, route: archive))
        #expect(store.destination(for: "personal") == MailAccountDestination(action: .trash, route: nil))
        #expect(store.activeMappings == ["work": archive])
    }

    @Test func switchingToNonMailboxActionClearsTheFolder() {
        let store = PreferencesStore(defaults: isolatedDefaults())
        let route = MailboxRoute(scope: .account(identifier: "work"), components: ["Later"])
        store.setAction(.move, for: "work")
        store.setRoute(route, for: "work")

        store.setAction(.leave, for: "work")

        #expect(store.destination(for: "work") == .leaveInMail)
        #expect(store.activeMappings.isEmpty)
    }

    @Test func newAccountsDefaultToLeavingMessagesInMail() {
        let store = PreferencesStore(defaults: isolatedDefaults())

        store.ensureDestinations(for: [MailAccount(id: "work", name: "Work")])

        #expect(store.destination(for: "work") == .leaveInMail)
    }

    @Test func destinationsPersistAcrossStoreInstances() {
        let defaults = isolatedDefaults()
        let route = MailboxRoute(scope: .account(identifier: "work"), components: ["Archive"])
        let firstStore = PreferencesStore(defaults: defaults)
        firstStore.setAction(.archive, for: "work")
        firstStore.setRoute(route, for: "work")

        let restoredStore = PreferencesStore(defaults: defaults)

        #expect(restoredStore.destination(for: "work") == MailAccountDestination(action: .archive, route: route))
    }

    private func isolatedDefaults() -> UserDefaults {
        let suite = "AccountDestinationTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}
