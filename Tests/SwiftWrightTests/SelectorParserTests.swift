import XCTest
@testable import SwiftWright

final class SelectorParserTests: XCTestCase {

    // MARK: - Valid selectors

    func testSimpleRole() throws {
        let sel = try SelectorParser.parse("button")
        XCTAssertEqual(sel.steps.count, 1)
        XCTAssertEqual(sel.steps[0].role, "button")
        XCTAssertNil(sel.steps[0].identifier)
        XCTAssertTrue(sel.steps[0].attributes.isEmpty)
    }

    func testIdentifierOnly() throws {
        let sel = try SelectorParser.parse("#login")
        XCTAssertEqual(sel.steps.count, 1)
        XCTAssertNil(sel.steps[0].role)
        XCTAssertEqual(sel.steps[0].identifier, "login")
    }

    func testRoleAndIdentifier() throws {
        let sel = try SelectorParser.parse("button#submit")
        XCTAssertEqual(sel.steps.count, 1)
        XCTAssertEqual(sel.steps[0].role, "button")
        XCTAssertEqual(sel.steps[0].identifier, "submit")
    }

    func testAttributeEquality() throws {
        let sel = try SelectorParser.parse("[title=Settings]")
        XCTAssertEqual(sel.steps.count, 1)
        XCTAssertEqual(sel.steps[0].attributes.count, 1)
        let attr = sel.steps[0].attributes[0]
        XCTAssertEqual(attr.key, "title")
        XCTAssertEqual(attr.value, "Settings")
        XCTAssertEqual(attr.op, .equals)
    }

    func testAttributeContains() throws {
        let sel = try SelectorParser.parse("[title~=Settings]")
        XCTAssertEqual(sel.steps[0].attributes[0].op, .contains)
        XCTAssertEqual(sel.steps[0].attributes[0].value, "Settings")
    }

    func testQuotedAttributeValue() throws {
        let sel = try SelectorParser.parse("[title=\"Hello World\"]")
        XCTAssertEqual(sel.steps[0].attributes[0].value, "Hello World")
    }

    func testFullStep() throws {
        let sel = try SelectorParser.parse("button#confirm[title~=OK]")
        XCTAssertEqual(sel.steps.count, 1)
        let step = sel.steps[0]
        XCTAssertEqual(step.role, "button")
        XCTAssertEqual(step.identifier, "confirm")
        XCTAssertEqual(step.attributes[0].key, "title")
        XCTAssertEqual(step.attributes[0].value, "OK")
        XCTAssertEqual(step.attributes[0].op, .contains)
    }

    func testDescendantChain() throws {
        let sel = try SelectorParser.parse("window dialog button")
        XCTAssertEqual(sel.steps.count, 3)
        XCTAssertEqual(sel.steps[0].role, "window")
        XCTAssertEqual(sel.steps[1].role, "dialog")
        XCTAssertEqual(sel.steps[2].role, "button")
    }

    func testComplexChain() throws {
        let sel = try SelectorParser.parse("window[title=My App] dialog button#confirm")
        XCTAssertEqual(sel.steps.count, 3)
        XCTAssertEqual(sel.steps[0].role, "window")
        XCTAssertEqual(sel.steps[0].attributes[0].key, "title")
        XCTAssertEqual(sel.steps[0].attributes[0].value, "My App")
        XCTAssertEqual(sel.steps[2].identifier, "confirm")
    }

    func testMultipleAttributes() throws {
        let sel = try SelectorParser.parse("button[title=OK][value~=yes]")
        XCTAssertEqual(sel.steps[0].attributes.count, 2)
        XCTAssertEqual(sel.steps[0].attributes[0].key, "title")
        XCTAssertEqual(sel.steps[0].attributes[1].key, "value")
    }

    func testLeadingTrailingWhitespace() throws {
        let sel = try SelectorParser.parse("  button  ")
        XCTAssertEqual(sel.steps.count, 1)
        XCTAssertEqual(sel.steps[0].role, "button")
    }

    func testRolesAreLowercased() throws {
        let sel = try SelectorParser.parse("Button")
        XCTAssertEqual(sel.steps[0].role, "button")
    }

    func testHyphenatedIdentifier() throws {
        let sel = try SelectorParser.parse("#my-button-id")
        XCTAssertEqual(sel.steps[0].identifier, "my-button-id")
    }

    func testRawPreserved() throws {
        let raw = "window button#ok"
        let sel = try SelectorParser.parse(raw)
        XCTAssertEqual(sel.raw, raw)
    }

    // MARK: - Invalid selectors

    func testEmptySelectorThrows() {
        XCTAssertThrowsError(try SelectorParser.parse("")) { error in
            guard case WrightError.invalidSelector = error else {
                XCTFail("Expected invalidSelector, got \(error)")
                return
            }
        }
    }

    func testWhitespaceSelectorThrows() {
        XCTAssertThrowsError(try SelectorParser.parse("   "))
    }

    func testMissingIdentifierAfterHashThrows() {
        XCTAssertThrowsError(try SelectorParser.parse("#"))
    }

    func testUnclosedBracketThrows() {
        XCTAssertThrowsError(try SelectorParser.parse("[title=foo"))
    }

    func testMissingOperatorThrows() {
        XCTAssertThrowsError(try SelectorParser.parse("[titlefoo]"))
    }

    func testUnclosedQuoteThrows() {
        XCTAssertThrowsError(try SelectorParser.parse("[title=\"unclosed]"))
    }
}
