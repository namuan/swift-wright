import Foundation

// MARK: - AST node types for the selector grammar

/// A comparison operator used in attribute filters.
public enum AttrOp: Equatable {
    /// Strict equality: `[title=Settings]`
    case equals
    /// Case-insensitive substring match: `[title~=Settings]`
    case contains
}

/// A single attribute filter within a selector step.
public struct AttrFilter: Equatable {
    /// The AX attribute name being tested (e.g. `title`, `value`, `name`).
    public let key: String
    /// The expected value.
    public let value: String
    /// The comparison operator.
    public let op: AttrOp
}

/// One step in a descendant selector chain.
/// Example: `button#confirm[title~=OK]` becomes a single `SelectorStep`.
public struct SelectorStep: Equatable {
    /// Role to match (already lowercased; will be resolved to AXRole by the matcher).
    /// `nil` means match any role.
    public var role: String?
    /// Identifier to match (from `#id`). `nil` means match any identifier.
    public var identifier: String?
    /// Attribute filters to satisfy.
    public var attributes: [AttrFilter]

    public init(role: String? = nil, identifier: String? = nil, attributes: [AttrFilter] = []) {
        self.role = role
        self.identifier = identifier
        self.attributes = attributes
    }
}

/// The fully-parsed representation of a selector string.
public struct ParsedSelector: Equatable {
    /// Ordered steps. A descendant relationship exists between consecutive steps.
    public let steps: [SelectorStep]
    /// The original selector string (for error messages).
    public let raw: String
}
