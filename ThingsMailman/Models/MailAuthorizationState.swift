import Foundation

enum MailAuthorizationState: String, Codable, Sendable {
    case notDetermined
    case authorized
    case denied
    case mailNotRunning

    var title: String {
        switch self {
        case .notDetermined: "Not requested"
        case .authorized: "Authorized"
        case .denied: "Denied"
        case .mailNotRunning: "Mail isn’t open"
        }
    }
}
