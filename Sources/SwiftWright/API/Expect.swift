import Foundation

// MARK: - Entry point

/// Creates an ``Expectation`` for `locator`, enabling assertion chaining.
///
/// ```swift
/// try await expect(page.locator("button#submit")).toBeEnabled()
/// try await expect(page.locator("#status")).toHaveText("Success")
/// ```
public func expect(_ locator: Locator) -> Expectation {
    Expectation(locator: locator)
}

// MARK: - Expectation

/// A set of async assertions that poll until the condition holds or timeout elapses.
///
/// All assertion methods throw ``WrightError/timeout`` on failure, including a
/// description of the selector and the waited condition.
public struct Expectation {
    public let locator: Locator
    /// How long to poll before failing.
    public var timeout: TimeInterval

    public init(locator: Locator, timeout: TimeInterval? = nil) {
        self.locator = locator
        self.timeout = timeout ?? locator.timeout
    }

    /// Returns a copy with a different timeout.
    public func withTimeout(_ seconds: TimeInterval) -> Expectation {
        Expectation(locator: locator, timeout: seconds)
    }

    // MARK: - Existence

    /// Asserts the element exists in the AX tree.
    public func toExist() async throws {
        try await poll(description: "exists") { elem in elem != nil }
    }

    /// Asserts the element does **not** exist in the AX tree.
    public func toNotExist() async throws {
        try await pollAbsence(description: "not exist")
    }

    // MARK: - State

    /// Asserts the element is enabled (`AXEnabled = true`).
    public func toBeEnabled() async throws {
        try await poll(description: "enabled") { $0?.isEnabled == true }
    }

    /// Asserts the element is disabled (`AXEnabled = false`).
    public func toBeDisabled() async throws {
        try await poll(description: "disabled") { $0?.isEnabled == false }
    }

    /// Asserts the element has focus (`AXFocused = true`).
    public func toBeFocused() async throws {
        try await poll(description: "focused") { $0?.isFocused == true }
    }

    // MARK: - Text / Value

    /// Asserts the element's text content contains `text` (case-insensitive).
    public func toHaveText(_ text: String) async throws {
        try await poll(description: "text contains '\(text)'") { elem in
            guard let e = elem else { return false }
            let content = e.title ?? e.label ?? e.stringValue ?? ""
            return content.localizedCaseInsensitiveContains(text)
        }
    }

    /// Asserts the element's text content equals `text` exactly.
    public func toHaveExactText(_ text: String) async throws {
        try await poll(description: "text equals '\(text)'") { elem in
            guard let e = elem else { return false }
            let content = e.title ?? e.label ?? e.stringValue ?? ""
            return content == text
        }
    }

    /// Asserts the element's `AXValue` equals `value`.
    public func toHaveValue(_ value: String) async throws {
        try await poll(description: "value equals '\(value)'") { elem in
            elem?.stringValue == value
        }
    }

    /// Asserts the element's `AXValue` contains `value` (case-insensitive).
    public func toContainValue(_ value: String) async throws {
        try await poll(description: "value contains '\(value)'") { elem in
            guard let v = elem?.stringValue else { return false }
            return v.localizedCaseInsensitiveContains(value)
        }
    }

    // MARK: - Polling helpers

    private func poll(description: String, _ condition: (AXElement?) -> Bool) async throws {
        try await AutoWaiter.waitUntil(timeout: timeout, selector: locator.selector) {
            let elem = try? locator.resolve()
            return condition(elem)
        }
    }

    private func pollAbsence(description: String) async throws {
        try await AutoWaiter.waitUntil(timeout: timeout, selector: locator.selector) {
            (try? locator.resolve()) == nil
        }
    }
}
