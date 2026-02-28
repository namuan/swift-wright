import ApplicationServices
import AppKit
import Foundation

/// Wraps the application-level `AXUIElement` and provides app-specific queries.
public final class AXApplication {
    public let element: AXElement
    public let pid: pid_t

    public init(pid: pid_t) {
        self.pid = pid
        self.element = AXElement(AXUIElementCreateApplication(pid))
    }

    // MARK: - Windows

    public var windows: [AXElement] {
        guard let refs: [AXUIElement] = element.attribute(kAXWindowsAttribute) else {
            return element.children.filter { $0.role == kAXWindowRole }
        }
        return refs.map(AXElement.init)
    }

    public var mainWindow: AXElement? {
        guard let ref: AXUIElement = element.attribute(kAXMainWindowAttribute) else { return nil }
        return AXElement(ref)
    }

    public var focusedWindow: AXElement? {
        guard let ref: AXUIElement = element.attribute(kAXFocusedWindowAttribute) else { return nil }
        return AXElement(ref)
    }

    public var focusedElement: AXElement? {
        guard let ref: AXUIElement = element.attribute(kAXFocusedUIElementAttribute) else { return nil }
        return AXElement(ref)
    }

    // MARK: - Factories

    /// Attaches to an already-running application by bundle identifier.
    public static func attach(bundleID: String) throws -> AXApplication {
        try Permissions.assertTrusted()
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        guard let app = apps.first else {
            throw WrightError.appNotFound(bundleID: bundleID)
        }
        return AXApplication(pid: app.processIdentifier)
    }

    /// Launches and attaches to an application by bundle identifier.
    public static func launch(bundleID: String) async throws -> AXApplication {
        try Permissions.assertTrusted()
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            throw WrightError.appNotFound(bundleID: bundleID)
        }
        let config = NSWorkspace.OpenConfiguration()
        let running = try await NSWorkspace.shared.openApplication(at: url, configuration: config)
        // Brief grace period for the app to initialize its AX tree.
        try await Task.sleep(nanoseconds: 500_000_000)
        return AXApplication(pid: running.processIdentifier)
    }

    /// Terminates the application.
    public func terminate() {
        if let app = NSRunningApplication(processIdentifier: pid) {
            app.terminate()
        }
    }
}
