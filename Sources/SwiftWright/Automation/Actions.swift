import ApplicationServices
import CoreGraphics
import Foundation

/// Low-level actions performed on ``AXElement`` instances.
///
/// Actions are called by ``Locator`` after the element has been found and
/// verified to be in the correct state. All functions throw ``WrightError``
/// on failure.
public enum Actions {

    // MARK: - Click

    /// Performs a single click on `element`.
    ///
    /// Tries `AXPress` first; falls back to a CGEvent mouse click at the
    /// element's frame centre.
    public static func click(_ element: AXElement) throws {
        if element.performAction(kAXPressAction) { return }
        guard let frame = element.frame else {
            throw WrightError.actionFailed(action: "click",
                reason: "AXPress failed and element has no accessible frame")
        }
        cgMouseClick(at: CGPoint(x: frame.midX, y: frame.midY))
    }

    /// Performs a double-click on `element`.
    public static func doubleClick(_ element: AXElement) throws {
        guard let frame = element.frame else {
            throw WrightError.actionFailed(action: "doubleClick",
                reason: "Element has no accessible frame")
        }
        let center = CGPoint(x: frame.midX, y: frame.midY)
        cgMouseClick(at: center, clickCount: 2)
    }

    // MARK: - Text input

    /// Types `text` into `element`.
    ///
    /// Prefers setting `AXValue` directly (instant and reliable for text fields).
    /// Falls back to focusing the element and posting CGEvent keyboard events.
    public static func type(_ element: AXElement, text: String) throws {
        // Direct AXValue approach (works for most text fields).
        if element.setValue(text as CFString) { return }

        // Fallback: focus the element then emit keyboard events.
        try focus(element)
        try cgType(text: text)
    }

    /// Clears the current text value of `element`.
    public static func clear(_ element: AXElement) throws {
        guard element.setValue("" as CFString) else {
            throw WrightError.actionFailed(action: "clear",
                reason: "Could not set AXValue to empty string")
        }
    }

    /// Focuses `element` by setting `AXFocused = true`.
    public static func focus(_ element: AXElement) throws {
        let result = AXUIElementSetAttributeValue(
            element.ref,
            kAXFocusedAttribute as CFString,
            kCFBooleanTrue
        )
        guard result == .success else {
            throw WrightError.actionFailed(action: "focus",
                reason: "AXError code \(result.rawValue)")
        }
    }

    /// Selects all text in `element` (Command+A).
    public static func selectAll(_ element: AXElement) throws {
        try focus(element)
        try pressKey(virtualKey: 0, flags: .maskCommand)   // Cmd+A
    }

    // MARK: - Key press

    /// Presses a named key with optional modifier flags.
    ///
    /// Supported key names (case-insensitive):
    /// `Return`, `Tab`, `Escape`, `Space`, `Delete`, `Backspace`,
    /// `ArrowUp`, `ArrowDown`, `ArrowLeft`, `ArrowRight`,
    /// `Home`, `End`, `PageUp`, `PageDown`, `F1`–`F12`.
    ///
    /// Modifiers can be prepended with `+`:
    /// e.g. `"Command+A"`, `"Shift+Tab"`, `"Command+Shift+Z"`.
    public static func pressKey(_ element: AXElement, key: String) throws {
        try focus(element)
        let (vk, flags) = try parseKey(key)
        try pressKey(virtualKey: vk, flags: flags)
    }

    // MARK: - Private helpers

    private static func cgMouseClick(at point: CGPoint, clickCount: Int = 1) {
        let source = CGEventSource(stateID: .hidSystemState)
        for _ in 0..<clickCount {
            let down = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown,
                               mouseCursorPosition: point, mouseButton: .left)
            let up = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp,
                             mouseCursorPosition: point, mouseButton: .left)
            down?.post(tap: .cghidEventTap)
            up?.post(tap: .cghidEventTap)
        }
    }

    private static func cgType(text: String) throws {
        let source = CGEventSource(stateID: .hidSystemState)
        for scalar in text.unicodeScalars {
            guard scalar.value <= UInt16.max else { continue }
            let uni = [UniChar(scalar.value)]
            let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
            down?.keyboardSetUnicodeString(stringLength: uni.count, unicodeString: uni)
            let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
            up?.keyboardSetUnicodeString(stringLength: uni.count, unicodeString: uni)
            down?.post(tap: .cghidEventTap)
            up?.post(tap: .cghidEventTap)
        }
    }

    private static func pressKey(virtualKey: CGKeyCode, flags: CGEventFlags) throws {
        let source = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: true)
        let up   = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: false)
        down?.flags = flags
        up?.flags = flags
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    // MARK: - Key name parsing

    private static let namedKeys: [String: CGKeyCode] = [
        "return":    36,
        "enter":     36,
        "tab":       48,
        "space":     49,
        "delete":    51,
        "backspace": 51,
        "escape":    53,
        "arrowleft":  123,
        "arrowright": 124,
        "arrowdown":  125,
        "arrowup":    126,
        "home":      115,
        "end":       119,
        "pageup":    116,
        "pagedown":  121,
        "f1":  122, "f2":  120, "f3":  99,  "f4":  118,
        "f5":  96,  "f6":  97,  "f7":  98,  "f8":  100,
        "f9":  101, "f10": 109, "f11": 103, "f12": 111,
        // Single-letter keys (US QWERTY virtual key codes)
        "a": 0,  "s": 1,  "d": 2,  "f": 3,  "h": 4,  "g": 5,
        "z": 6,  "x": 7,  "c": 8,  "v": 9,  "b": 11, "q": 12,
        "w": 13, "e": 14, "r": 15, "y": 16, "t": 17,
        "1": 18, "2": 19, "3": 20, "4": 21, "6": 22, "5": 23,
        "=": 24, "9": 25, "7": 26, "-": 27, "8": 28, "0": 29,
        "]": 30, "o": 31, "u": 32, "[": 33, "i": 34, "p": 35,
        "l": 37, "j": 38, "'": 39, "k": 40, ";": 41, "\\": 42,
        ",": 43, "/": 44, "n": 45, "m": 46, ".": 47,
    ]

    private static let modifierNames: [String: CGEventFlags] = [
        "command": .maskCommand,
        "cmd":     .maskCommand,
        "shift":   .maskShift,
        "option":  .maskAlternate,
        "alt":     .maskAlternate,
        "control": .maskControl,
        "ctrl":    .maskControl,
    ]

    private static func parseKey(_ raw: String) throws -> (CGKeyCode, CGEventFlags) {
        let parts = raw.split(separator: "+", omittingEmptySubsequences: true).map {
            $0.trimmingCharacters(in: .whitespaces).lowercased()
        }
        guard !parts.isEmpty else {
            throw WrightError.actionFailed(action: "pressKey", reason: "Empty key string")
        }

        var flags: CGEventFlags = []
        var keyPart: String?

        for part in parts {
            if let mod = modifierNames[part] {
                flags.insert(mod)
            } else {
                guard keyPart == nil else {
                    throw WrightError.actionFailed(action: "pressKey",
                        reason: "Multiple key parts in '\(raw)'")
                }
                keyPart = part
            }
        }

        guard let key = keyPart else {
            throw WrightError.actionFailed(action: "pressKey",
                reason: "No key found in '\(raw)'")
        }

        guard let vk = namedKeys[key] else {
            throw WrightError.actionFailed(action: "pressKey",
                reason: "Unknown key '\(key)'. Supported: \(namedKeys.keys.sorted().joined(separator: ", "))")
        }

        return (vk, flags)
    }
}
