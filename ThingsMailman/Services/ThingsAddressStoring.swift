import Foundation

protocol ThingsAddressStoring: Sendable {
    func loadAddress() async throws -> String?
    func saveAddress(_ address: String) async throws
}
