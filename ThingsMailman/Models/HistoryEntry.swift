import Foundation

struct HistoryEntry: Identifiable, Hashable, Sendable {
    let id: UUID
    let date: Date
    let subject: String
    let accountIdentifier: String
    let outcome: ProcessingOutcome
    let detail: String?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        subject: String,
        accountIdentifier: String,
        outcome: ProcessingOutcome,
        detail: String? = nil
    ) {
        self.id = id
        self.date = date
        self.subject = subject
        self.accountIdentifier = accountIdentifier
        self.outcome = outcome
        self.detail = detail
    }

    var menuSubject: String {
        let limit = 21
        return subject.count > limit ? "\(subject.prefix(limit - 1))…" : subject
    }
}
