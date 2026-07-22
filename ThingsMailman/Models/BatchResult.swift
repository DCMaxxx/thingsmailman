import Foundation

enum BatchResult: Sendable, Equatable {
    case completed([HistoryEntry])
    case confirmationRequired(Int)
    case emptySelection
    case mailNotRunning
    case mailNotFrontmost
    case tooMany(Int)
    case alreadyProcessing
    case missingAddress
    case authorizationDenied
}
