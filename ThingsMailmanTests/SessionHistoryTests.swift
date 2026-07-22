import Foundation
import Testing
@testable import ThingsMailman

@MainActor
struct SessionHistoryTests {
    @Test func keepsLatestTwentyInMemoryOnly() {
        let history = SessionHistory()
        history.record((0..<25).map { HistoryEntry(subject: "Message \($0)", accountIdentifier: "account", outcome: .sent) })
        #expect(history.entries.count == 20)
        #expect(history.entries.first?.subject == "Message 24")

        let newSession = SessionHistory()
        #expect(newSession.entries.isEmpty)
    }

    @Test func clearRemovesSessionEntries() {
        let history = SessionHistory()
        history.record([HistoryEntry(subject: "Hello", accountIdentifier: "account", outcome: .sent)])
        history.clear()
        #expect(history.entries.isEmpty)
    }
}
