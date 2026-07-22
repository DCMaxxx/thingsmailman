import Foundation

enum ThingsAddressValidator {
    static func isValid(_ value: String) -> Bool {
        let address = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let parts = address.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty else { return false }
        return parts[1] == "things.email"
    }
}
