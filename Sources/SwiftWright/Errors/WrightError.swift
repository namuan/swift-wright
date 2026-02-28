import Foundation

/// All errors thrown by SwiftWright.
public enum WrightError: Error, CustomStringConvertible {
    case permissionDenied
    case appNotFound(bundleID: String)
    case elementNotFound(selector: String)
    case timeout(selector: String, after: TimeInterval)
    case actionFailed(action: String, reason: String)
    case invalidSelector(String)

    public var description: String {
        switch self {
        case .permissionDenied:
            return "Accessibility permission denied. Grant access in System Settings → Privacy & Security → Accessibility."
        case .appNotFound(let id):
            return "Application not found: \(id)"
        case .elementNotFound(let sel):
            return "Element not found: \(sel)"
        case .timeout(let sel, let t):
            return "Timeout after \(t)s waiting for: \(sel)"
        case .actionFailed(let action, let reason):
            return "Action '\(action)' failed: \(reason)"
        case .invalidSelector(let s):
            return "Invalid selector: \(s)"
        }
    }
}

extension WrightError: LocalizedError {
    public var errorDescription: String? { description }
}
