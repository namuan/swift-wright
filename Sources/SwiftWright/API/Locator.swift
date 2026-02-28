import Foundation

/// A lazy, immutable reference to one or more elements matching a selector.
///
/// `Locator` does not perform AX tree traversal until an action is invoked.
/// Every action automatically waits for the element to be present and enabled
/// before executing (see ``AutoWaiter``).
///
/// ```swift
/// let page = try await Page.attach(bundleID: "com.example.App")
/// try await page.locator("button#submit").click()
/// try await page.locator("textfield#email").type("user@example.com")
/// ```
public struct Locator {
    /// The raw selector string.
    public let selector: String
    /// The page this locator is bound to.
    public let page: Page
    /// Maximum time to wait for the element before throwing ``WrightError/timeout``.
    public var timeout: TimeInterval

    // MARK: - Init

    init(selector: String, page: Page, timeout: TimeInterval = 10) {
        self.selector = selector
        self.page = page
        self.timeout = timeout
    }

    /// Returns a copy of this locator with a different timeout.
    public func withTimeout(_ seconds: TimeInterval) -> Locator {
        Locator(selector: selector, page: page, timeout: seconds)
    }

    // MARK: - Element resolution

    /// Resolves the selector against the current AX tree. Throws if not found.
    func resolve() throws -> AXElement {
        let parsed = try SelectorParser.parse(selector)
        let root = page.app.element
        guard let found = SelectorMatcher.findFirst(selector: parsed, in: root) else {
            throw WrightError.elementNotFound(selector: selector)
        }
        return found
    }

    /// Waits until `condition` is satisfied, then returns the element.
    func waitForElement(
        condition: @escaping (AXElement) -> Bool = { _ in true }
    ) async throws -> AXElement {
        try await AutoWaiter.waitFor(timeout: timeout, selector: selector) { () -> AXElement? in
            guard let elem = try? self.resolve() else { return nil }
            return condition(elem) ? elem : nil
        }
    }

    // MARK: - Actions

    /// Clicks the element (waits until enabled).
    public func click() async throws {
        let elem = try await waitForElement(condition: { $0.isEnabled })
        try Actions.click(elem)
    }

    /// Double-clicks the element.
    public func doubleClick() async throws {
        let elem = try await waitForElement(condition: { $0.isEnabled })
        try Actions.doubleClick(elem)
    }

    /// Types `text` into the element (waits until enabled).
    ///
    /// This does **not** clear the existing value first. Call ``clear()`` before
    /// `type` if you need a clean field.
    public func type(_ text: String) async throws {
        let elem = try await waitForElement(condition: { $0.isEnabled })
        try Actions.type(elem, text: text)
    }

    /// Clears the current value of the element.
    public func clear() async throws {
        let elem = try await waitForElement(condition: { $0.isEnabled })
        try Actions.clear(elem)
    }

    /// Focuses the element.
    public func focus() async throws {
        let elem = try await waitForElement()
        try Actions.focus(elem)
    }

    /// Sends a key press to the element.
    ///
    /// Use modifier prefixes separated by `+`, e.g. `"Command+A"`, `"Shift+Tab"`.
    public func pressKey(_ key: String) async throws {
        let elem = try await waitForElement(condition: { $0.isEnabled })
        try Actions.pressKey(elem, key: key)
    }

    // MARK: - Queries (no waiting)

    /// Returns `true` if the element currently exists in the AX tree.
    public func isVisible() -> Bool {
        (try? resolve()) != nil
    }

    /// Returns `true` if the element currently exists and is enabled.
    public func isEnabled() -> Bool {
        (try? resolve())?.isEnabled == true
    }

    // MARK: - Value access (with waiting)

    /// Returns the text content of the element (title, label, or value).
    public func textContent() async throws -> String {
        let elem = try await waitForElement()
        return elem.title ?? elem.label ?? elem.stringValue ?? ""
    }

    /// Returns the AXValue of the element as a String, if any.
    public func getValue() async throws -> String? {
        let elem = try await waitForElement()
        return elem.stringValue
    }

    // MARK: - All matches

    /// Returns all elements matching this locator's selector.
    public func all() throws -> [AXElement] {
        let parsed = try SelectorParser.parse(selector)
        return SelectorMatcher.find(selector: parsed, in: page.app.element)
    }

    /// Returns the number of elements currently matching this locator.
    public func count() throws -> Int {
        (try? all())?.count ?? 0
    }
}
