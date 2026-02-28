import Foundation

/// Parses a selector string into a ``ParsedSelector``.
///
/// **Grammar (v1)**
/// ```
/// selector     ::= step (' '+ step)*
/// step         ::= role? ('#' identifier)? attr_filter*
/// role         ::= [a-zA-Z][a-zA-Z0-9_-]*
/// identifier   ::= [a-zA-Z0-9_-]+
/// attr_filter  ::= '[' key ('~=' | '=') value ']'
/// key          ::= [a-zA-Z][a-zA-Z0-9_-]*
/// value        ::= quoted_string | bare_value
/// quoted_string ::= '"' [^"]* '"'
/// bare_value   ::= [^\]]+
/// ```
public enum SelectorParser {

    // MARK: - Public entry point

    public static func parse(_ raw: String) throws -> ParsedSelector {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw WrightError.invalidSelector("Selector must not be empty")
        }

        var steps: [SelectorStep] = []
        var scanner = Scanner(trimmed)

        // Each iteration parses one step; steps are separated by whitespace.
        while !scanner.isAtEnd {
            let step = try parseStep(&scanner)
            steps.append(step)
            scanner.skipWhitespace()
        }

        guard !steps.isEmpty else {
            throw WrightError.invalidSelector("Selector produced no steps: '\(raw)'")
        }

        return ParsedSelector(steps: steps, raw: raw)
    }

    // MARK: - Step parsing

    private static func parseStep(_ scanner: inout Scanner) throws -> SelectorStep {
        var step = SelectorStep()

        // Optional role (bare word not starting with '#' or '[')
        if let role = scanner.scanRole() {
            step.role = role.lowercased()
        }

        // Optional #identifier
        if scanner.peek() == "#" {
            scanner.advance()
            guard let id = scanner.scanIdentifier() else {
                throw WrightError.invalidSelector("Expected identifier after '#'")
            }
            step.identifier = id
        }

        // Zero or more attribute filters
        while scanner.peek() == "[" {
            let filter = try parseAttrFilter(&scanner)
            step.attributes.append(filter)
        }

        // A step must have at least one constraint
        guard step.role != nil || step.identifier != nil || !step.attributes.isEmpty else {
            let ctx = scanner.remainingPrefix(10)
            throw WrightError.invalidSelector("Empty selector step near '\(ctx)'")
        }

        return step
    }

    // MARK: - Attribute filter parsing

    private static func parseAttrFilter(_ scanner: inout Scanner) throws -> AttrFilter {
        guard scanner.peek() == "[" else {
            throw WrightError.invalidSelector("Expected '[' to start attribute filter")
        }
        scanner.advance() // consume '['

        guard let key = scanner.scanIdentifier() else {
            throw WrightError.invalidSelector("Expected attribute key inside '[]'")
        }

        let op: AttrOp
        if scanner.scan(string: "~=") {
            op = .contains
        } else if scanner.scan(string: "=") {
            op = .equals
        } else {
            throw WrightError.invalidSelector("Expected '=' or '~=' after attribute key '\(key)'")
        }

        let value = try parseAttrValue(&scanner)

        guard scanner.peek() == "]" else {
            throw WrightError.invalidSelector("Expected ']' to close attribute filter for '\(key)'")
        }
        scanner.advance() // consume ']'

        return AttrFilter(key: key, value: value, op: op)
    }

    private static func parseAttrValue(_ scanner: inout Scanner) throws -> String {
        if scanner.peek() == "\"" {
            // Quoted string
            scanner.advance() // consume opening quote
            var chars: [Character] = []
            while let ch = scanner.peek(), ch != "\"" {
                chars.append(ch)
                scanner.advance()
            }
            guard scanner.peek() == "\"" else {
                throw WrightError.invalidSelector("Unterminated quoted string in attribute value")
            }
            scanner.advance() // consume closing quote
            return String(chars)
        } else {
            // Bare value — everything up to ']'
            var chars: [Character] = []
            while let ch = scanner.peek(), ch != "]" {
                chars.append(ch)
                scanner.advance()
            }
            if chars.isEmpty {
                throw WrightError.invalidSelector("Empty attribute value")
            }
            return String(chars)
        }
    }
}

// MARK: - Scanner helper

/// A simple forward-only character scanner.
private struct Scanner {
    private let chars: [Character]
    private var index: Int = 0

    init(_ string: String) {
        self.chars = Array(string)
    }

    var isAtEnd: Bool { index >= chars.count }

    func peek() -> Character? {
        guard index < chars.count else { return nil }
        return chars[index]
    }

    mutating func advance() {
        index += 1
    }

    mutating func skipWhitespace() {
        while let ch = peek(), ch.isWhitespace { advance() }
    }

    /// Scans a role token: a word made of letters/digits/hyphens/underscores that
    /// is NOT preceded by '#' or '[' (those are handled separately).
    /// Returns `nil` if the next character doesn't start a role.
    mutating func scanRole() -> String? {
        guard let first = peek(), first.isLetter else { return nil }
        var result: [Character] = []
        while let ch = peek(), ch.isLetter || ch.isNumber || ch == "-" || ch == "_" {
            result.append(ch)
            advance()
        }
        return result.isEmpty ? nil : String(result)
    }

    /// Scans an identifier (letters, digits, hyphens, underscores).
    mutating func scanIdentifier() -> String? {
        guard let first = peek(), first.isLetter || first.isNumber || first == "_" else { return nil }
        var result: [Character] = []
        while let ch = peek(), ch.isLetter || ch.isNumber || ch == "-" || ch == "_" {
            result.append(ch)
            advance()
        }
        return result.isEmpty ? nil : String(result)
    }

    /// Tries to scan the exact string `s`. Returns `true` and advances if matched.
    mutating func scan(string s: String) -> Bool {
        let target = Array(s)
        guard index + target.count <= chars.count else { return false }
        for (i, ch) in target.enumerated() {
            guard chars[index + i] == ch else { return false }
        }
        index += target.count
        return true
    }

    /// Returns up to `n` characters of remaining input (for error messages).
    func remainingPrefix(_ n: Int) -> String {
        let end = min(index + n, chars.count)
        return String(chars[index..<end])
    }
}
