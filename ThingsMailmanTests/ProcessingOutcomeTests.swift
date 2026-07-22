import Testing
@testable import ThingsMailman

struct ProcessingOutcomeTests {
    @Test func sentHistoryEntriesAreInformational() {
        #expect(!ProcessingOutcome.sent.isHistoryInteractive)
        #expect(!ProcessingOutcome.sent.offersMailboxReview)
    }

    @Test func skippedHistoryEntriesOfferMailboxReview() {
        #expect(ProcessingOutcome.skippedMapping.isHistoryInteractive)
        #expect(ProcessingOutcome.skippedMapping.offersMailboxReview)
    }

    @Test func failuresRemainInteractiveWithoutMailboxReview() {
        let failures: [ProcessingOutcome] = [.sendFailed, .sendIndeterminate, .sentCleanupFailed]

        for failure in failures {
            #expect(failure.isHistoryInteractive)
            #expect(!failure.offersMailboxReview)
        }
    }
}
