import Foundation
import Observation

@MainActor
@Observable
final class SessionHistory {
    private(set) var entries: [HistoryEntry] = []
    let capacity: Int

    init(capacity: Int = 20) {
        self.capacity = capacity
    }

    func record(_ newEntries: [HistoryEntry]) {
        entries.insert(contentsOf: newEntries.reversed(), at: 0)
        if entries.count > capacity {
            entries.removeLast(entries.count - capacity)
        }
    }

    func clear() {
        entries.removeAll(keepingCapacity: true)
    }
}
