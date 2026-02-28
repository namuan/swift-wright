import ApplicationServices
import CoreGraphics
import Foundation

/// A thin, value-typed wrapper around `AXUIElement`.
public struct AXElement: AXElementProtocol {
    /// The underlying Core Foundation reference.
    public let ref: AXUIElement

    public init(_ ref: AXUIElement) {
        self.ref = ref
    }

    // MARK: - Raw attribute access

    /// Reads a typed attribute value from the AX tree.
    public func attribute<T>(_ key: String) -> T? {
        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(ref, key as CFString, &raw) == .success,
              let value = raw else { return nil }
        return value as? T
    }

    // MARK: - AXElementProtocol

    public var role: String? { attribute(kAXRoleAttribute) }
    public var title: String? { attribute(kAXTitleAttribute) }
    public var label: String? { attribute(kAXDescriptionAttribute) }
    public var identifier: String? { attribute(kAXIdentifierAttribute) }

    public var stringValue: String? {
        attribute(kAXValueAttribute) as String?
    }

    public var isEnabled: Bool {
        (attribute(kAXEnabledAttribute) as Bool?) ?? false
    }

    public var isFocused: Bool {
        (attribute(kAXFocusedAttribute) as Bool?) ?? false
    }

    public var children: [AXElement] {
        guard let refs: [AXUIElement] = attribute(kAXChildrenAttribute) else { return [] }
        return refs.map(AXElement.init)
    }

    // MARK: - Additional attributes

    public var frame: CGRect? {
        axGeometry("AXFrame")
    }

    public var position: CGPoint? {
        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(ref, "AXPosition" as CFString, &raw) == .success,
              let axVal = raw, CFGetTypeID(axVal) == AXValueGetTypeID() else { return nil }
        var point = CGPoint.zero
        AXValueGetValue(axVal as! AXValue, .cgPoint, &point)   // safe: type checked above
        return point
    }

    public var size: CGSize? {
        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(ref, "AXSize" as CFString, &raw) == .success,
              let axVal = raw, CFGetTypeID(axVal) == AXValueGetTypeID() else { return nil }
        var sz = CGSize.zero
        AXValueGetValue(axVal as! AXValue, .cgSize, &sz)        // safe: type checked above
        return sz
    }

    private func axGeometry(_ key: String) -> CGRect? {
        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(ref, key as CFString, &raw) == .success,
              let axVal = raw, CFGetTypeID(axVal) == AXValueGetTypeID() else { return nil }
        var rect = CGRect.zero
        AXValueGetValue(axVal as! AXValue, .cgRect, &rect)      // safe: type checked above
        return rect
    }

    // MARK: - Actions

    /// Performs a named AX action on this element.
    @discardableResult
    public func performAction(_ action: String) -> Bool {
        return AXUIElementPerformAction(ref, action as CFString) == .success
    }

    /// Sets the AXValue attribute.
    @discardableResult
    public func setValue(_ value: CFTypeRef) -> Bool {
        return AXUIElementSetAttributeValue(ref, kAXValueAttribute as CFString, value) == .success
    }

    /// Sets an arbitrary attribute.
    @discardableResult
    public func setAttribute(_ key: String, value: CFTypeRef) -> Bool {
        return AXUIElementSetAttributeValue(ref, key as CFString, value) == .success
    }

    // MARK: - Debug

    /// Returns a human-readable snapshot of this element's key properties.
    public func snapshot(indent: Int = 0) -> String {
        let pad = String(repeating: "  ", count: indent)
        var parts: [String] = []
        if let r = role { parts.append("role=\(r)") }
        if let t = title { parts.append("title=\(t)") }
        if let id = identifier { parts.append("#\(id)") }
        if let v = stringValue { parts.append("value=\(v)") }
        var result = pad + "[\(parts.joined(separator: " "))]"
        for child in children {
            result += "\n" + child.snapshot(indent: indent + 1)
        }
        return result
    }
}

extension AXElement: Equatable {
    public static func == (lhs: AXElement, rhs: AXElement) -> Bool {
        CFEqual(lhs.ref, rhs.ref)
    }
}
