import Foundation

struct MailboxRoute: Hashable, Codable, Sendable, Identifiable {
    var scope: MailboxScope
    var components: [String]

    var id: String { "\(scope.persistenceKey)/\(encodedPath)" }
    var displayPath: String { components.joined(separator: " / ") }
    var encodedPath: String { components.map(Self.encodeComponent).joined(separator: "/") }

    init(scope: MailboxScope, components: [String]) {
        self.scope = scope
        self.components = components
    }

    init?(scope: MailboxScope, encodedPath: String) {
        let decoded = encodedPath.split(separator: "/", omittingEmptySubsequences: false).map {
            Self.decodeComponent(String($0))
        }
        guard !decoded.isEmpty, decoded.allSatisfy({ !$0.isEmpty }) else { return nil }
        self.init(scope: scope, components: decoded)
    }

    static func encodeComponent(_ value: String) -> String {
        value.replacing("%", with: "%25").replacing("/", with: "%2F")
    }

    static func decodeComponent(_ value: String) -> String {
        value.replacing("%2F", with: "/").replacing("%2f", with: "/").replacing("%25", with: "%")
    }
}
