import SwiftUI

@main
struct ThingsMailmanApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var state = AppState()

    var body: some Scene {
        Window("Things Mailman", id: "setup") {
            SetupStatusView(state: state)
                .task { await configureApplication() }
        }
        .defaultSize(width: 620, height: 600)
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuContentView(state: state)
        } label: {
            MenuBarLabelView(state: state)
        }
        .menuBarExtraStyle(.menu)
    }

    private func configureApplication() async {
        let isFirstStart = !state.hasStarted
        appDelegate.mailActivationHandler = { [weak state] in
            Task { await state?.refreshMailState() }
        }
        appDelegate.appActivationHandler = { [weak state] in
            Task { await state?.refreshMailSetup() }
        }
        appDelegate.appReopenHandler = showSetupWindow
        await state.start()
        if isFirstStart && state.preferences.isSetupComplete {
            for window in NSApp.windows where window.title == "Things Mailman" {
                window.orderOut(nil)
            }
        }
    }

    private func showSetupWindow() {
        for window in NSApp.windows where window.title == "Things Mailman" {
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }
}
