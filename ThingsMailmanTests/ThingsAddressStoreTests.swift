import Foundation
import Testing
@testable import ThingsMailman

struct ThingsAddressStoreTests {
    @Test func persistsAddressInSandboxedPreferences() async {
        let suite = "ThingsAddressStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        let store = UserDefaultsThingsAddressStore(defaults: defaults)

        await store.saveAddress("private@things.email")

        #expect(await store.loadAddress() == "private@things.email")
    }
}
