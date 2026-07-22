import Foundation
import UserNotifications

actor FailureNotifier: FailureNotifying {
    private var hasRequestedAuthorization = false

    func notifyFirstFailure(count: Int) async {
        let center = UNUserNotificationCenter.current()
        if !hasRequestedAuthorization {
            hasRequestedAuthorization = true
            guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
        }
        let content = UNMutableNotificationContent()
        content.title = "Things Mailman needs attention"
        content.body = "\(count) message\(count == 1 ? "" : "s") could not be fully processed."
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try? await center.add(request)
    }
}
