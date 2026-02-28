import Foundation

/// Abstraction over an accessibility tree node.
/// Both the real ``AXElement`` and test ``MockAXElement`` conform to this.
public protocol AXElementProtocol {
    var role: String? { get }
    var title: String? { get }
    /// AXDescription — the accessible label / subtitle.
    var label: String? { get }
    var identifier: String? { get }
    /// String representation of AXValue, when applicable.
    var stringValue: String? { get }
    var isEnabled: Bool { get }
    var isFocused: Bool { get }
    var children: [Self] { get }
}

public extension AXElementProtocol {
    /// Depth-first descendants (not including self).
    func descendants() -> [Self] {
        var result: [Self] = []
        var stack = children
        while !stack.isEmpty {
            let elem = stack.removeFirst()
            result.append(elem)
            stack.insert(contentsOf: elem.children, at: 0)
        }
        return result
    }

    /// Self + all descendants.
    func subtree() -> [Self] {
        var result: [Self] = [self]
        result.append(contentsOf: descendants())
        return result
    }
}
