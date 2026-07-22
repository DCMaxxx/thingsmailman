import Foundation

protocol LaunchAtLoginControlling: Sendable {
    func setEnabled(_ enabled: Bool) async throws
}
