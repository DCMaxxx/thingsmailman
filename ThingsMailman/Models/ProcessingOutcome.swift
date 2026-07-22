import Foundation

enum ProcessingOutcome: String, Codable, Sendable {
    case sent
    case skippedMapping
    case sendFailed
    case sendIndeterminate
    case sentCleanupFailed

    var title: String {
        switch self {
        case .sent: "Sent"
        case .skippedMapping: "Skipped — mailbox"
        case .sendFailed: "Send failed"
        case .sendIndeterminate: "Send indeterminate"
        case .sentCleanupFailed: "Sent — cleanup failed"
        }
    }

    var isFailure: Bool { self != .sent && self != .skippedMapping }

    var isHistoryInteractive: Bool { self != .sent }

    var offersMailboxReview: Bool { self == .skippedMapping }

    var systemImage: String {
        switch self {
        case .sent: "checkmark.circle.fill"
        case .skippedMapping: "arrow.right.circle"
        case .sendFailed: "xmark.circle.fill"
        case .sendIndeterminate: "questionmark.circle.fill"
        case .sentCleanupFailed: "exclamationmark.circle.fill"
        }
    }
}
