import Foundation

enum MailboxRouteValidator {
    static func health(
        for routes: [String: MailboxRoute],
        availableRoutes: Set<MailboxRoute>
    ) -> [String: MailboxMappingHealth] {
        routes.mapValues { availableRoutes.contains($0) ? .valid : .missing }
    }
}
