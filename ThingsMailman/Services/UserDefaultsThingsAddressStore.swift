import Foundation

actor UserDefaultsThingsAddressStore: ThingsAddressStoring {
    private let defaults: UserDefaults
    private let key = "thingsEmailAddress"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadAddress() -> String? {
        defaults.string(forKey: key)
    }

    func saveAddress(_ address: String) {
        defaults.set(address, forKey: key)
    }
}
