# Swift Wright

[![CI](https://github.com/namuan/swift-wright/actions/workflows/ci.yml/badge.svg)](https://github.com/namuan/swift-wright/actions/workflows/ci.yml)
[![Release](https://github.com/namuan/swift-wright/actions/workflows/release.yml/badge.svg)](https://github.com/namuan/swift-wright/actions/workflows/release.yml)
[![Swift](https://img.shields.io/badge/Swift-5.9+-F05138?logo=swift&logoColor=white)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey?logo=apple)](https://developer.apple.com/macos/)
[![License](https://img.shields.io/github/license/namuan/swift-wright)](https://github.com/namuan/swift-wright/blob/main/LICENSE)

End-to-end macOS UI automation in pure Swift, built on the Accessibility (AX) APIs.

Swift Wright gives you a [Playwright](https://playwright.dev)-style automation model — deterministic selectors, auto-waiting, and a composable assertion API — for any accessibility-enabled macOS application, without requiring access to the app's source code or test target.

---

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Permissions](#permissions)
- [Quick Start](#quick-start)
- [Selector Reference](#selector-reference)
- [API Reference](#api-reference)
  - [Page](#page)
  - [Locator](#locator)
  - [Expect](#expect)
  - [Permissions](#permissions-api)
- [CLI Reference](#cli-reference)
- [Auto-Waiting](#auto-waiting)
- [Error Handling](#error-handling)
- [Architecture](#architecture)
- [Testing](#testing)
- [Roadmap](#roadmap)

---

## Requirements

| Requirement | Version |
|---|---|
| macOS | 13.0+ |
| Swift | 5.9+ |
| Xcode | 15+ |

---

## Installation

### Swift Package Manager

Add Swift Wright to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/namuan/swift-wright", from: "1.0.0"),
],
targets: [
    .target(
        name: "MyTarget",
        dependencies: ["SwiftWright"]
    ),
]
```

Or add it in Xcode via **File → Add Package Dependencies** and enter:

```
https://github.com/namuan/swift-wright
```

Pre-built universal binaries (arm64 + x86_64) are attached to every [GitHub release](https://github.com/namuan/swift-wright/releases).

---

## Permissions

Swift Wright uses macOS Accessibility APIs and requires the **Accessibility** permission.

Grant it in **System Settings → Privacy & Security → Accessibility**, then enable your app or terminal emulator.

Check and request permission in code:

```swift
import SwiftWright

// Check only
if Permissions.isTrusted {
    // ready to automate
}

// Check and prompt if needed
Permissions.requestIfNeeded(showPrompt: true)

// Assert — throws WrightError.permissionDenied if not granted
try Permissions.assertTrusted()
```

> **Note for CLI use:** Grant Accessibility permission to the terminal app running `swift-wright` (e.g. Terminal.app or iTerm2).

---

## Quick Start

```swift
import SwiftWright

// Attach to a running app
let page = try Page.attach(bundleID: "com.apple.TextEdit")

// Or launch it
let page = try await Page.launch(bundleID: "com.apple.TextEdit")

// Click a button
try await page.locator("button[title=New Document]").click()

// Type into a text field
try await page.locator("textfield").type("Hello, Swift Wright!")

// Assert something exists
try await expect(page.locator("statictext[title~=Hello]")).toExist()

// Terminate the app
page.terminate()
```

---

## Selector Reference

Selectors describe elements in the AX tree. They compose CSS-style constructs adapted for the Accessibility API.

### Syntax

```
selector     = step (' '+ step)*
step         = role? ('#' identifier)? attr_filter*
attr_filter  = '[' key ('=' | '~=') value ']'
value        = '"' quoted_value '"' | bare_value
```

### Constructs

| Construct | Example | Matches |
|---|---|---|
| Role | `button` | Any `AXButton` element |
| Identifier | `#login` | Element with `AXIdentifier = "login"` |
| Role + ID | `button#login` | Button with that identifier |
| Attribute equality | `[title=Settings]` | Element where `AXTitle = "Settings"` |
| Attribute contains | `[title~=Settings]` | Element where `AXTitle` contains "Settings" (case-insensitive) |
| Descendant chain | `window dialog button` | Button inside a dialog inside a window |
| Quoted value | `[title="New Document"]` | Exact match, spaces allowed |

### Role Aliases

Swift Wright maps user-friendly names to AX roles:

| Alias | AX Role |
|---|---|
| `button` | `AXButton` |
| `textfield` / `input` | `AXTextField` |
| `textarea` | `AXTextArea` |
| `text` / `statictext` | `AXStaticText` |
| `window` | `AXWindow` |
| `dialog` / `sheet` | `AXSheet` |
| `checkbox` | `AXCheckBox` |
| `radiobutton` | `AXRadioButton` |
| `menu` | `AXMenu` |
| `menuitem` | `AXMenuItem` |
| `menubar` | `AXMenuBar` |
| `menubaritem` | `AXMenuBarItem` |
| `combobox` | `AXComboBox` |
| `popupbutton` | `AXPopUpButton` |
| `slider` | `AXSlider` |
| `table` | `AXTable` |
| `row` | `AXRow` |
| `cell` | `AXCell` |
| `list` | `AXList` |
| `outline` | `AXOutline` |
| `image` | `AXImage` |
| `link` | `AXLink` |
| `group` | `AXGroup` |
| `tabgroup` | `AXTabGroup` |
| `toolbar` | `AXToolbar` |
| `scrollarea` | `AXScrollArea` |
| `scrollbar` | `AXScrollBar` |
| `splitgroup` | `AXSplitGroup` |
| `application` | `AXApplication` |

Raw AX role strings (e.g. `AXButton`) are also accepted directly.

### Selector Examples

```swift
// Any button
page.locator("button")

// Button with AXIdentifier "submit"
page.locator("button#submit")

// Text field whose title is exactly "Username"
page.locator("textfield[title=Username]")

// Text field whose title contains "user" (case-insensitive)
page.locator("textfield[title~=user]")

// The confirm button inside a sheet inside a window
page.locator("window sheet button#confirm")

// Static text containing "Welcome"
page.locator("statictext[title~=Welcome]")

// A window whose title contains "Preferences"
page.locator("window[title~=Preferences]")
```

---

## API Reference

### Page

`Page` represents an attached macOS application instance. It is the root entry point for all automation.

```swift
// Attach to a running application
let page = try Page.attach(bundleID: "com.apple.TextEdit")

// Launch an application and wait for its AX tree to be ready
let page = try await Page.launch(bundleID: "com.apple.TextEdit")

// The process ID of the attached application
page.pid  // Int32

// Create a locator
let locator = page.locator("button#ok")

// Terminate the application
page.terminate()

// Print the full AX tree (useful for writing selectors)
page.printTree()

// Get the AX tree as a string (for logging or assertions)
let snapshot = page.treeSnapshot()
```

---

### Locator

`Locator` is a lazy, immutable reference to one or more elements. It performs no AX tree traversal until an action is invoked. Every action automatically waits for the element to be present and enabled.

#### Creating Locators

```swift
let button = page.locator("button#submit")

// Override the default 10s timeout for this locator
let fastLocator = page.locator("button").withTimeout(3)
```

#### Actions

All action methods are `async throws`.

```swift
// Click (waits until element is enabled)
try await locator.click()

// Double-click
try await locator.doubleClick()

// Type text (sets AXValue directly; falls back to CGEvent keyboard)
try await locator.type("Hello, world!")

// Clear the current value
try await locator.clear()

// Focus the element
try await locator.focus()

// Press a named key (with optional modifiers)
try await locator.pressKey("Return")
try await locator.pressKey("Command+A")
try await locator.pressKey("Shift+Tab")
try await locator.pressKey("Command+Shift+Z")
```

**Supported key names:** `Return`, `Enter`, `Tab`, `Escape`, `Space`, `Delete`, `Backspace`, `ArrowUp`, `ArrowDown`, `ArrowLeft`, `ArrowRight`, `Home`, `End`, `PageUp`, `PageDown`, `F1`–`F12`, and all single-character keys (a–z, 0–9, punctuation).

**Modifier prefixes:** `Command` / `Cmd`, `Shift`, `Option` / `Alt`, `Control` / `Ctrl`.

#### Reading Values

```swift
// Text content (AXTitle, AXDescription, or AXValue — whichever is populated)
let text = try await locator.textContent()

// AXValue as a String
let value = try await locator.getValue()
```

#### Querying Without Waiting

```swift
// True if the element currently exists (no waiting)
locator.isVisible()  // Bool

// True if the element currently exists and is enabled
locator.isEnabled()  // Bool

// All matching elements right now
let elements = try locator.all()  // [AXElement]

// Count of matching elements right now
let n = try locator.count()  // Int
```

---

### Expect

The `expect` function creates an `Expectation` that polls until the assertion holds or times out.

```swift
// Basic usage
try await expect(page.locator("button#ok")).toExist()

// Override the timeout for a single assertion
try await expect(page.locator("spinner")).withTimeout(2).toNotExist()
```

#### Assertions

| Method | Condition |
|---|---|
| `toExist()` | Element is present in the AX tree |
| `toNotExist()` | Element is absent from the AX tree |
| `toBeEnabled()` | `AXEnabled = true` |
| `toBeDisabled()` | `AXEnabled = false` |
| `toBeFocused()` | `AXFocused = true` |
| `toHaveText(_ text: String)` | Text content contains `text` (case-insensitive) |
| `toHaveExactText(_ text: String)` | Text content equals `text` exactly |
| `toHaveValue(_ value: String)` | `AXValue` equals `value` |
| `toContainValue(_ value: String)` | `AXValue` contains `value` (case-insensitive) |

All assertions throw `WrightError.timeout` on failure, with the selector and timeout duration included in the error message.

---

### Permissions API

```swift
// Check whether the process is trusted
Permissions.isTrusted  // Bool

// Check and optionally prompt the user
Permissions.requestIfNeeded(showPrompt: true)  // Bool

// Throw WrightError.permissionDenied if not trusted
try Permissions.assertTrusted()
```

---

## CLI Reference

The `swift-wright` command-line tool is built automatically with the package.

```
swift-wright <command> [arguments]
```

### Commands

#### `attach`
Verifies that Swift Wright can attach to a running application.

```sh
swift-wright attach com.apple.TextEdit
# Attached to com.apple.TextEdit (pid 1234)
```

#### `click`
Clicks a UI element.

```sh
swift-wright click <bundle-id> <selector>

swift-wright click com.apple.TextEdit "button[title=New Document]"
```

#### `type`
Types text into a UI element.

```sh
swift-wright type <bundle-id> <selector> <text>

swift-wright type com.apple.TextEdit "textfield" "Hello, World!"
```

#### `expect`
Asserts a condition on an element. Exits with code 1 on failure.

```sh
swift-wright expect <bundle-id> <selector> <condition>

# Conditions: exists | not-exists | enabled | focused
swift-wright expect com.apple.TextEdit "button#save" exists
swift-wright expect com.apple.TextEdit "spinner"     not-exists
swift-wright expect com.apple.TextEdit "button#ok"   enabled
```

#### `tree`
Prints the full accessibility tree of the application — useful for writing selectors.

```sh
swift-wright tree <bundle-id>

swift-wright tree com.apple.TextEdit
```

### Shell Script Example

```sh
#!/bin/sh
set -e

BUNDLE=com.example.MyApp

swift-wright attach "$BUNDLE"
swift-wright click  "$BUNDLE" "button[title=Login]"
swift-wright type   "$BUNDLE" "textfield#username" "admin"
swift-wright type   "$BUNDLE" "textfield#password" "secret"
swift-wright click  "$BUNDLE" "button#submit"
swift-wright expect "$BUNDLE" "statictext[title~=Welcome]" exists
echo "Login flow passed"
```

---

## Auto-Waiting

Every action and assertion implicitly waits. Before executing a click, type, or assertion, Swift Wright polls the AX tree until:

1. The element exists in the tree
2. The element is enabled (for actions)
3. The specific condition holds (for assertions)

The default timeout is **10 seconds**, configurable per-locator or per-expectation.

```swift
// 10-second timeout (default)
try await page.locator("button#ok").click()

// 3-second timeout for this locator
try await page.locator("button#ok").withTimeout(3).click()

// 2-second timeout for this assertion only
try await expect(page.locator("spinner")).withTimeout(2).toNotExist()
```

Polling interval is 100 ms by default (v2 will add event-driven waiting via AX notifications).

---

## Error Handling

All errors are strongly typed as `WrightError`:

```swift
public enum WrightError: Error {
    case permissionDenied
    case appNotFound(bundleID: String)
    case elementNotFound(selector: String)
    case timeout(selector: String, after: TimeInterval)
    case actionFailed(action: String, reason: String)
    case invalidSelector(String)
}
```

Example:

```swift
do {
    let page = try Page.attach(bundleID: "com.example.App")
    try await page.locator("button#submit").click()
} catch WrightError.permissionDenied {
    print("Grant Accessibility access in System Settings.")
} catch WrightError.elementNotFound(let selector) {
    print("Could not find: \(selector)")
} catch WrightError.timeout(let selector, let after) {
    print("Timed out after \(after)s waiting for: \(selector)")
} catch {
    print("Unexpected error: \(error)")
}
```

---

## Architecture

```
┌─────────────────────────────────────┐
│           Public API Layer          │
│    Page · Locator · Expect          │
├─────────────────────────────────────┤
│          Automation Layer           │
│    AutoWaiter · Actions             │
├─────────────────────────────────────┤
│         Selector Engine             │
│  SelectorParser · SelectorMatcher   │
│  (generic over AXElementProtocol)   │
├─────────────────────────────────────┤
│           AX Core Layer             │
│  AXElement · AXApplication          │
│  AXElementProtocol · Permissions    │
├─────────────────────────────────────┤
│     macOS Accessibility APIs        │
│  ApplicationServices · CGEvent      │
└─────────────────────────────────────┘
```

### Key design decisions

**`AXElementProtocol`** — The selector engine is generic over this protocol, which both `AXElement` (real AX tree) and `MockElement` (test doubles) conform to. This makes the entire selector and matching layer unit-testable without requiring Accessibility permission or a running application.

**Lazy Locators** — `Locator` holds only a selector string and a reference to the `Page`. No AX traversal happens until an action is called. This allows locators to be stored and reused freely.

**AXValue-first typing** — The `type` action sets `AXValue` directly (instant, reliable for standard text fields) before falling back to CGEvent keyboard events, matching the behavior most macOS apps expect.

**Click strategy** — `click` sends `AXPress` first (semantic, works regardless of screen position) and falls back to a CGEvent mouse click at the element's frame center.

---

## Testing

Run the unit test suite:

```sh
swift test
```

The test suite covers:

- **`SelectorParserTests`** (20 tests) — Valid and invalid selector strings, all grammar constructs, error cases
- **`SelectorMatcherTests`** (16 tests) — Role resolution, attribute filtering, descendant chaining, multi-match, using `MockElement` (no AX permission needed)
- **`WrightErrorTests`** (7 tests) — Error descriptions and `LocalizedError` conformance

Integration tests that interact with real applications require Accessibility permission and a running target app. Grant permission to the test runner and use `Page.attach(bundleID:)` to write end-to-end tests.

```swift
// Example integration test
func testLoginFlow() async throws {
    let page = try Page.attach(bundleID: "com.example.MyApp")
    try await page.locator("textfield#username").type("admin")
    try await page.locator("textfield#password").type("password")
    try await page.locator("button#login").click()
    try await expect(page.locator("statictext[title~=Welcome]")).toExist()
}
```
