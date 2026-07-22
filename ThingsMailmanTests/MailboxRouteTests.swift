import Testing
@testable import ThingsMailman

struct MailboxRouteTests {
    @Test func pathEncodingRoundTripsSeparatorsAndPercents() {
        let original = MailboxRoute(scope: .onMyMac, components: ["Projects/2026", "100% Ready"])
        #expect(original.encodedPath == "Projects%2F2026/100%25 Ready")
        #expect(MailboxRoute(scope: .onMyMac, encodedPath: original.encodedPath) == original)
    }

    @Test func emptyComponentsAreRejected() {
        #expect(MailboxRoute(scope: .onMyMac, encodedPath: "Archive/") == nil)
    }

    @Test func everyDiscoveredFolderRouteValidatesAcrossAccounts() {
        let first = MailboxRoute(scope: .account(identifier: "icloud"), components: ["Archive"])
        let second = MailboxRoute(scope: .account(identifier: "work"), components: ["Messages envoyés"])
        let missing = MailboxRoute(scope: .account(identifier: "work"), components: ["Removed"])

        let health = MailboxRouteValidator.health(
            for: ["icloud": first, "work": second, "old": missing],
            availableRoutes: [first, second]
        )

        #expect(health["icloud"] == .valid)
        #expect(health["work"] == .valid)
        #expect(health["old"] == .missing)
    }
}
