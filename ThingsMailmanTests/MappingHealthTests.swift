import Foundation
import Testing
@testable import ThingsMailman

@MainActor
struct MappingHealthTests {
    @Test func unavailablePreservesLastKnownWarning() {
        let defaults = isolatedDefaults()
        let store = MappingHealthStore(defaults: defaults)
        store.replace(with: ["work": .stale(previousPath: "Archive")])
        store.markUnavailablePreservingWarnings(for: ["work"])
        #expect(store.healthByAccount["work"] == .stale(previousPath: "Archive"))
    }

    @Test func successfulRevalidationClearsWarningPresentation() {
        let warning = MenuBarPresentation(activity: .idle, health: ["work": .missing])
        #expect(warning.symbol == "exclamationmark.triangle")
        #expect(warning.showsMailboxReview)
        #expect(warning.affectedAccounts == ["work"])

        let valid = MenuBarPresentation(activity: .idle, health: ["work": .valid])
        #expect(valid.symbol == "envelope.badge.fill")
        #expect(!valid.showsMailboxReview)
    }

    @Test func busyStateDoesNotShowIdleWarningSymbol() {
        let state = MenuBarPresentation(activity: .forwarding, health: ["work": .missing])
        #expect(state.symbol == "arrow.triangle.2.circlepath")
        #expect(state.showsMailboxReview)
    }

    @Test func sentStateUsesConfirmationBeforeReturningToBranding() {
        let sent = MenuBarPresentation(activity: .sent, health: [:])
        #expect(sent.symbol == "checkmark.circle")
    }

    private func isolatedDefaults() -> UserDefaults {
        let suite = "MappingHealthTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}
