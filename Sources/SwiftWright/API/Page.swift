import AppKit
import Foundation

/// Represents a single attached macOS application instance.
///
/// `Page` is the top-level entry point for SwiftWright automation. It wraps
/// an ``AXApplication`` and provides ``Locator`` factories and app lifecycle
/// controls analogous to Playwright's `Page` type.
///
/// ```swift
/// let page = try await Page.attach(bundleID: "com.apple.TextEdit")
/// try await page.locator("button[title=New Document]").click()
/// ```
public final class Page {
    let app: AXApplication

    /// The process identifier of the attached application.
    public var pid: pid_t { app.pid }

    init(app: AXApplication) {
        self.app = app
    }

    // MARK: - Factories

    /// Attaches to an already-running application.
    ///
    /// - Parameter bundleID: The CFBundleIdentifier (e.g. `"com.apple.TextEdit"`).
    /// - Throws: ``WrightError/permissionDenied`` if Accessibility is not granted.
    ///           ``WrightError/appNotFound(bundleID:)`` if the app is not running.
    public static func attach(bundleID: String) throws -> Page {
        let axApp = try AXApplication.attach(bundleID: bundleID)
        return Page(app: axApp)
    }

    /// Launches an application and returns a `Page` once its AX tree is available.
    ///
    /// - Parameter bundleID: The CFBundleIdentifier of the application to launch.
    public static func launch(bundleID: String) async throws -> Page {
        let axApp = try await AXApplication.launch(bundleID: bundleID)
        return Page(app: axApp)
    }

    // MARK: - Locators

    /// Returns a lazy ``Locator`` for the given selector.
    ///
    /// The locator does **not** perform any AX tree traversal until an action
    /// or assertion is invoked on it.
    ///
    /// - Parameter selector: A selector string, e.g. `"button#login"` or
    ///   `"window dialog textfield[title=Username]"`.
    public func locator(_ selector: String) -> Locator {
        Locator(selector: selector, page: self)
    }

    // MARK: - App lifecycle

    /// Terminates the attached application.
    public func terminate() {
        app.terminate()
    }

    // MARK: - AX tree inspection

    /// Prints the full accessibility tree of the application to stdout.
    /// Useful for debugging selectors.
    public func printTree() {
        print(app.element.snapshot())
    }

    /// Returns the raw accessibility tree snapshot as a string.
    public func treeSnapshot() -> String {
        app.element.snapshot()
    }
}
