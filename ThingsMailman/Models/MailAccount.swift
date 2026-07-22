import Foundation

struct MailAccount: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
}
