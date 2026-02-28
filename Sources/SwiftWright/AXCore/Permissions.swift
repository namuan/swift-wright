import ApplicationServices
import Foundation

/// Helpers for checking and requesting Accessibility permission.
public enum Permissions {
    /// Returns `true` if the process has been granted Accessibility access.
    public static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Prompts the user for Accessibility permission if not already granted.
    /// - Parameter showPrompt: When `true`, the system will present a permission dialog.
    /// - Returns: `true` if trusted after the check.
    @discardableResult
    public static func requestIfNeeded(showPrompt: Bool = true) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: showPrompt]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Throws ``WrightError/permissionDenied`` if the process is not trusted.
    public static func assertTrusted() throws {
        guard isTrusted else {
            throw WrightError.permissionDenied
        }
    }
}
