import Foundation

struct MessageReference: Hashable, Sendable, Identifiable {
    let id: UUID
    let token: Data
    let subject: String
    let accountIdentifier: String

    init(id: UUID = UUID(), token: Data, subject: String, accountIdentifier: String) {
        self.id = id
        self.token = token
        self.subject = subject
        self.accountIdentifier = accountIdentifier
    }
}
