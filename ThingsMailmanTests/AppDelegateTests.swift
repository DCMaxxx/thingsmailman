import AppKit
import Testing
@testable import ThingsMailman

@MainActor
struct AppDelegateTests {
    @Test func becomingActiveRequestsAStateRefresh() {
        let delegate = AppDelegate()
        var refreshRequested = false
        delegate.appActivationHandler = { refreshRequested = true }

        delegate.applicationDidBecomeActive(Notification(name: NSApplication.didBecomeActiveNotification))

        #expect(refreshRequested)
    }

    @Test func reopeningRequestsTheSetupWindow() {
        let delegate = AppDelegate()
        var setupRequested = false
        delegate.appReopenHandler = { setupRequested = true }

        let shouldHandle = delegate.applicationShouldHandleReopen(
            NSApplication.shared,
            hasVisibleWindows: false
        )

        #expect(setupRequested)
        #expect(shouldHandle)
    }
}
