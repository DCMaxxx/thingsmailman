import Foundation

protocol FailureNotifying: Sendable {
    func notifyFirstFailure(count: Int) async
}
