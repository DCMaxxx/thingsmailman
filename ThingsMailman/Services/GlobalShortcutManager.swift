import Carbon.HIToolbox
import Foundation

private let shortcutHandler: EventHandlerUPP = { _, _, userData in
    guard let userData else { return OSStatus(eventNotHandledErr) }
    let manager = Unmanaged<GlobalShortcutManager>.fromOpaque(userData).takeUnretainedValue()
    Task { @MainActor in manager.invoke() }
    return noErr
}

@MainActor
final class GlobalShortcutManager {
    private var hotKey: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var action: (@MainActor @Sendable () -> Void)?
    private var currentShortcut: GlobalShortcut?

    init() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            shortcutHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
    }

    func register(_ shortcut: GlobalShortcut, action: @escaping @MainActor @Sendable () -> Void) -> Bool {
        let previousShortcut = currentShortcut
        if let hotKey { UnregisterEventHotKey(hotKey) }
        hotKey = nil
        guard registerRaw(shortcut) else {
            if let previousShortcut { _ = registerRaw(previousShortcut) }
            return false
        }
        currentShortcut = shortcut
        self.action = action
        return true
    }

    private func registerRaw(_ shortcut: GlobalShortcut) -> Bool {
        var reference: EventHotKeyRef?
        let identifier = EventHotKeyID(signature: MailEventCodes.fourChar("THMM"), id: 1)
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            identifier,
            GetApplicationEventTarget(),
            0,
            &reference
        )
        guard status == noErr else {
            return false
        }
        hotKey = reference
        return true
    }

    fileprivate func invoke() {
        action?()
    }
}
