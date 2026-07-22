import Foundation

enum MailboxMappingHealth: Hashable, Codable, Sendable {
    case valid
    case missing
    case stale(previousPath: String)
    case unavailableForValidation
    case authorizationDenied

    var needsAttention: Bool {
        switch self {
        case .missing, .stale, .authorizationDenied: true
        case .valid, .unavailableForValidation: false
        }
    }

    var label: String {
        switch self {
        case .valid: "Valid"
        case .missing: "Missing"
        case .stale: "Renamed or removed"
        case .unavailableForValidation: "Waiting for Mail"
        case .authorizationDenied: "Mail access denied"
        }
    }
}
