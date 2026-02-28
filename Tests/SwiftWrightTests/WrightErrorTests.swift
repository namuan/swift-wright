import XCTest
@testable import SwiftWright

final class WrightErrorTests: XCTestCase {

    func testPermissionDeniedDescription() {
        let err = WrightError.permissionDenied
        XCTAssertTrue(err.description.contains("Accessibility permission denied"))
    }

    func testAppNotFoundDescription() {
        let err = WrightError.appNotFound(bundleID: "com.example.app")
        XCTAssertTrue(err.description.contains("com.example.app"))
    }

    func testElementNotFoundDescription() {
        let err = WrightError.elementNotFound(selector: "button#login")
        XCTAssertTrue(err.description.contains("button#login"))
    }

    func testTimeoutDescription() {
        let err = WrightError.timeout(selector: "textfield", after: 5.0)
        XCTAssertTrue(err.description.contains("textfield"))
        XCTAssertTrue(err.description.contains("5.0"))
    }

    func testActionFailedDescription() {
        let err = WrightError.actionFailed(action: "click", reason: "no frame")
        XCTAssertTrue(err.description.contains("click"))
        XCTAssertTrue(err.description.contains("no frame"))
    }

    func testInvalidSelectorDescription() {
        let err = WrightError.invalidSelector("bad##selector")
        XCTAssertTrue(err.description.contains("bad##selector"))
    }

    func testLocalizedError() {
        let err = WrightError.permissionDenied as Error
        XCTAssertNotNil(err.localizedDescription)
    }
}
