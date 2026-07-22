import Foundation

enum MailboxScope: Hashable, Codable, Sendable {
    case account(identifier: String)
    case onMyMac

    var persistenceKey: String {
        switch self {
        case .account(let identifier): "account:\(identifier)"
        case .onMyMac: "local"
        }
    }

    var displayName: String {
        switch self {
        case .account: "Account"
        case .onMyMac: "On My Mac"
        }
    }
}
