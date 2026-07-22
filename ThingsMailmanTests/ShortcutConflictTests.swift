import AppKit
import Carbon.HIToolbox
import Testing
@testable import ThingsMailman

struct ShortcutConflictTests {
    @Test func defaultShortcutDoesNotOverlapMailCommands() {
        #expect(GlobalShortcut.default.keyCode == UInt32(kVK_Return))
        #expect(GlobalShortcut.default.modifiers == UInt32(optionKey | cmdKey))
        #expect(GlobalShortcut.default.displayName == "⌥⌘Return")
    }

    @Test func savedShortcutUsesTheActiveKeyboardLayoutInsteadOfANumericKeyCode() {
        let shortcut = GlobalShortcut(
            keyCode: UInt32(kVK_ANSI_Equal),
            modifiers: UInt32(shiftKey | cmdKey)
        )

        #expect(!shortcut.displayName.contains("Key 24"))
    }

    @Test func recordedShortcutUsesTheCurrentKeyboardLayoutCharacter() throws {
        let event = try #require(NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [.shift, .command],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "-",
            charactersIgnoringModifiers: "-",
            isARepeat: false,
            keyCode: UInt16(kVK_ANSI_Equal)
        ))

        #expect(GlobalShortcut.from(event: event)?.displayName == "⇧⌘-")
    }

}
