import XCTest
@testable import SwiftWright

// MARK: - Mock element

/// A test double for ``AXElementProtocol`` that allows arbitrary tree construction.
struct MockElement: AXElementProtocol {
    var role: String?
    var title: String?
    var label: String?
    var identifier: String?
    var stringValue: String?
    var isEnabled: Bool = true
    var isFocused: Bool = false
    var children: [MockElement] = []
}

// MARK: - Tests

final class SelectorMatcherTests: XCTestCase {

    // MARK: - Role matching

    func testMatchByRole() throws {
        let root = MockElement(role: "AXApplication", children: [
            MockElement(role: "AXButton"),
            MockElement(role: "AXTextField"),
        ])
        let sel = try SelectorParser.parse("button")
        let results = SelectorMatcher.find(selector: sel, in: root)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].role, "AXButton")
    }

    func testMatchByRoleAlias() throws {
        // "input" should map to AXTextField
        let root = MockElement(role: "AXApplication", children: [
            MockElement(role: "AXTextField"),
        ])
        let sel = try SelectorParser.parse("input")
        let results = SelectorMatcher.find(selector: sel, in: root)
        XCTAssertEqual(results.count, 1)
    }

    func testMatchByIdentifier() throws {
        let root = MockElement(role: "AXApplication", children: [
            MockElement(role: "AXButton", identifier: "login"),
            MockElement(role: "AXButton", identifier: "cancel"),
        ])
        let sel = try SelectorParser.parse("#login")
        let results = SelectorMatcher.find(selector: sel, in: root)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].identifier, "login")
    }

    func testMatchByRoleAndIdentifier() throws {
        let root = MockElement(role: "AXApplication", children: [
            MockElement(role: "AXButton", identifier: "login"),
            MockElement(role: "AXTextField", identifier: "login"),
        ])
        let sel = try SelectorParser.parse("button#login")
        let results = SelectorMatcher.find(selector: sel, in: root)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].role, "AXButton")
    }

    func testMatchByAttributeEquality() throws {
        let root = MockElement(role: "AXApplication", children: [
            MockElement(role: "AXButton", title: "Settings"),
            MockElement(role: "AXButton", title: "Cancel"),
        ])
        let sel = try SelectorParser.parse("button[title=Settings]")
        let results = SelectorMatcher.find(selector: sel, in: root)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].title, "Settings")
    }

    func testMatchByAttributeContains() throws {
        let root = MockElement(role: "AXApplication", children: [
            MockElement(role: "AXButton", title: "Open Settings"),
            MockElement(role: "AXButton", title: "Cancel"),
        ])
        let sel = try SelectorParser.parse("button[title~=Settings]")
        let results = SelectorMatcher.find(selector: sel, in: root)
        XCTAssertEqual(results.count, 1)
    }

    func testAttributeContainsCaseInsensitive() throws {
        let root = MockElement(role: "AXApplication", children: [
            MockElement(role: "AXButton", title: "SAVE FILE"),
        ])
        let sel = try SelectorParser.parse("button[title~=save]")
        let results = SelectorMatcher.find(selector: sel, in: root)
        XCTAssertEqual(results.count, 1)
    }

    // MARK: - Descendant chaining

    func testDescendantMatch() throws {
        let button = MockElement(role: "AXButton", identifier: "ok")
        let dialog = MockElement(role: "AXSheet", children: [button])
        let window = MockElement(role: "AXWindow", children: [dialog])
        let root = MockElement(role: "AXApplication", children: [window])

        let sel = try SelectorParser.parse("window dialog button")
        let results = SelectorMatcher.find(selector: sel, in: root)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].role, "AXButton")
    }

    func testDescendantWithIdentifier() throws {
        let button = MockElement(role: "AXButton", identifier: "confirm")
        let dialog = MockElement(role: "AXSheet", children: [button])
        let window = MockElement(role: "AXWindow", children: [dialog])
        let root   = MockElement(role: "AXApplication", children: [window])

        let sel = try SelectorParser.parse("window dialog button#confirm")
        let results = SelectorMatcher.find(selector: sel, in: root)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].identifier, "confirm")
    }

    func testNoMatchReturnsEmpty() throws {
        let root = MockElement(role: "AXApplication", children: [
            MockElement(role: "AXButton"),
        ])
        let sel = try SelectorParser.parse("textfield")
        let results = SelectorMatcher.find(selector: sel, in: root)
        XCTAssertTrue(results.isEmpty)
    }

    func testMultipleMatches() throws {
        let root = MockElement(role: "AXApplication", children: [
            MockElement(role: "AXButton", title: "A"),
            MockElement(role: "AXButton", title: "B"),
            MockElement(role: "AXButton", title: "C"),
        ])
        let sel = try SelectorParser.parse("button")
        let results = SelectorMatcher.find(selector: sel, in: root)
        XCTAssertEqual(results.count, 3)
    }

    func testFindFirst() throws {
        let root = MockElement(role: "AXApplication", children: [
            MockElement(role: "AXButton", title: "First"),
            MockElement(role: "AXButton", title: "Second"),
        ])
        let sel = try SelectorParser.parse("button")
        let first = SelectorMatcher.findFirst(selector: sel, in: root)
        XCTAssertNotNil(first)
        XCTAssertEqual(first?.title, "First")
    }

    // MARK: - Role alias coverage

    func testRoleAliasesMap() {
        XCTAssertEqual(SelectorMatcher.resolveRole("button"),    "AXButton")
        XCTAssertEqual(SelectorMatcher.resolveRole("textfield"), "AXTextField")
        XCTAssertEqual(SelectorMatcher.resolveRole("input"),     "AXTextField")
        XCTAssertEqual(SelectorMatcher.resolveRole("window"),    "AXWindow")
        XCTAssertEqual(SelectorMatcher.resolveRole("dialog"),    "AXSheet")
        XCTAssertEqual(SelectorMatcher.resolveRole("text"),      "AXStaticText")
        XCTAssertEqual(SelectorMatcher.resolveRole("link"),      "AXLink")
        XCTAssertEqual(SelectorMatcher.resolveRole("menu"),      "AXMenu")
    }

    func testUnknownRolePassThrough() {
        // If there's no alias, the raw value is returned unchanged.
        XCTAssertEqual(SelectorMatcher.resolveRole("AXCustomWidget"), "AXCustomWidget")
    }

    // MARK: - Subtree helpers

    func testDescendants() {
        let leaf1 = MockElement(role: "AXButton")
        let leaf2 = MockElement(role: "AXTextField")
        let mid   = MockElement(role: "AXGroup", children: [leaf1, leaf2])
        let root  = MockElement(role: "AXWindow", children: [mid])

        let descendants = root.descendants()
        XCTAssertEqual(descendants.count, 3) // mid, leaf1, leaf2
    }

    func testSubtree() {
        let child = MockElement(role: "AXButton")
        let root  = MockElement(role: "AXWindow", children: [child])
        XCTAssertEqual(root.subtree().count, 2) // root + child
    }
}
