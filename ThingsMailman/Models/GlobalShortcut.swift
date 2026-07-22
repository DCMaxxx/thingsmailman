import AppKit
import Carbon.HIToolbox
import Foundation

struct GlobalShortcut: Hashable, Codable, Sendable {
    var keyCode: UInt32
    var modifiers: UInt32
    var keyCharacter: String?

    init(keyCode: UInt32, modifiers: UInt32, keyCharacter: String? = nil) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.keyCharacter = keyCharacter
    }

    static let `default` = GlobalShortcut(
        keyCode: UInt32(kVK_Return),
        modifiers: UInt32(optionKey | cmdKey)
    )

    var displayName: String {
        var pieces: [String] = []
        if modifiers & UInt32(controlKey) != 0 { pieces.append("⌃") }
        if modifiers & UInt32(optionKey) != 0 { pieces.append("⌥") }
        if modifiers & UInt32(shiftKey) != 0 { pieces.append("⇧") }
        if modifiers & UInt32(cmdKey) != 0 { pieces.append("⌘") }
        pieces.append(
            Self.normalizedKeyCharacter(keyCharacter)
                ?? Self.currentKeyboardCharacter(for: keyCode)
                ?? Self.keyName(for: keyCode)
        )
        return pieces.joined()
    }

    static func from(event: NSEvent) -> GlobalShortcut? {
        let relevant = event.modifierFlags.intersection([.control, .option, .shift, .command])
        guard !relevant.isEmpty else { return nil }
        var carbon: UInt32 = 0
        if relevant.contains(.control) { carbon |= UInt32(controlKey) }
        if relevant.contains(.option) { carbon |= UInt32(optionKey) }
        if relevant.contains(.shift) { carbon |= UInt32(shiftKey) }
        if relevant.contains(.command) { carbon |= UInt32(cmdKey) }
        return GlobalShortcut(
            keyCode: UInt32(event.keyCode),
            modifiers: carbon,
            keyCharacter: event.characters(byApplyingModifiers: [])
        )
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.keyCode == rhs.keyCode && lhs.modifiers == rhs.modifiers
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(keyCode)
        hasher.combine(modifiers)
    }

    private static func normalizedKeyCharacter(_ value: String?) -> String? {
        guard let value, !value.isEmpty,
              value.rangeOfCharacter(from: .controlCharacters) == nil else { return nil }
        return value.uppercased()
    }

    private static func currentKeyboardCharacter(for code: UInt32) -> String? {
        guard let event = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "",
            charactersIgnoringModifiers: "",
            isARepeat: false,
            keyCode: UInt16(code)
        ) else { return nil }
        return normalizedKeyCharacter(event.characters(byApplyingModifiers: []))
    }

    private static func keyName(for code: UInt32) -> String {
        let names: [Int: String] = [
            kVK_ANSI_A: "A", kVK_ANSI_B: "B", kVK_ANSI_C: "C", kVK_ANSI_D: "D",
            kVK_ANSI_E: "E", kVK_ANSI_F: "F", kVK_ANSI_G: "G", kVK_ANSI_H: "H",
            kVK_ANSI_I: "I", kVK_ANSI_J: "J", kVK_ANSI_K: "K", kVK_ANSI_L: "L",
            kVK_ANSI_M: "M", kVK_ANSI_N: "N", kVK_ANSI_O: "O", kVK_ANSI_P: "P",
            kVK_ANSI_Q: "Q", kVK_ANSI_R: "R", kVK_ANSI_S: "S", kVK_ANSI_T: "T",
            kVK_ANSI_U: "U", kVK_ANSI_V: "V", kVK_ANSI_W: "W", kVK_ANSI_X: "X",
            kVK_ANSI_Y: "Y", kVK_ANSI_Z: "Z"
        ]
        if let name = names[Int(code)] { return name }
        if Int(code) == kVK_Space { return "Space" }
        if Int(code) == kVK_Return { return "Return" }
        return "Key \(code)"
    }
}
