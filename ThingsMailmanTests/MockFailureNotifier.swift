@testable import ThingsMailman

actor MockFailureNotifier: FailureNotifying {
    private(set) var requests: [Int] = []

    func notifyFirstFailure(count: Int) {
        requests.append(count)
    }
}
