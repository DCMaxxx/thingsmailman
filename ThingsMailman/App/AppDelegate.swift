import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var mailActivationHandler: (@MainActor @Sendable () -> Void)?
    var appActivationHandler: (@MainActor @Sendable () -> Void)?
    var appReopenHandler: (@MainActor @Sendable () -> Void)?
    private var observer: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSApp.activate(ignoringOtherApps: true)
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier == "com.apple.mail" else { return }
            Task { @MainActor in self?.mailActivationHandler?() }
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        appActivationHandler?()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        appReopenHandler?()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let observer { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
    }
}
