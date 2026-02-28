## 1. Abstract

This RFC proposes the full feature set, architecture, APIs, and implementation plan for **Swift Wright**, a Playwright-inspired automation framework for macOS applications built on top of the macOS Accessibility (AX) APIs. The system enables black-box UI automation for Swift and non-Swift macOS applications with modern ergonomics, deterministic selectors, auto-waiting, and optional multi-language control.

---

## 2. Motivation

Current macOS UI testing solutions present several limitations:

* XCUITest is tightly coupled to Xcode and Apple platforms
* Limited extensibility and non-ergonomic APIs
* Poor support for cross-application automation
* No Playwright-style selector or auto-waiting model

Swift Wright aims to:

* Provide a **modern UI automation model** for macOS
* Enable **headless and CI-friendly** execution
* Expose **first-class Accessibility semantics**

---

## 3. Goals and Non-Goals

### 3.1 Goals

* Deterministic, AX-backed selector engine
* Auto-waiting by default
* Black-box automation (no app instrumentation required)
* Swift-native core with stable public APIs
* Optional remote control via JSON-RPC
* Ability to automate *any* accessibility-enabled macOS app

### 3.2 Non-Goals

* Replacing XCUITest for iOS
* Visual/screenshot-based testing
* OCR-based automation
* Supporting non-macOS platforms

---

## 4. System Architecture

### 4.1 Layered Design

1. **AX Core Layer**

   * Raw Accessibility API wrappers
   * Permission handling
   * AX notifications

2. **Query & Selector Layer**

   * Selector grammar
   * AST and matcher
   * Tree traversal

3. **Automation Layer**

   * Actions (click, type, select)
   * Auto-wait logic
   * Error handling

4. **Public API Layer**

   * Page / Locator / Expectation APIs

5. **Transport Layer (Optional)**

   * CLI
   * JSON-RPC server

---

## 5. Selector Engine

### 5.1 Grammar (v1)

Supported constructs:

* Role selectors: `button`, `window`, `textfield`
* Identifier selector: `#login`
* Attribute equality: `[title=Settings]`
* Attribute containment: `[title~=Settings]`
* Descendant chaining: `window dialog button#confirm`

### 5.2 Selector Semantics

* All selectors are **deterministic**
* Matching is strict unless `~=` is used
* First match wins (v1)

### 5.3 Planned Extensions

* `:has-text("text")`
* `nth(n)`
* `first()` / `last()`
* OR selectors: `button, link`

---

## 6. AX Mapping

| Selector Concept | AX Attribute            |
| ---------------- | ----------------------- |
| Role             | AXRole                  |
| #id              | AXIdentifier            |
| name             | AXTitle / AXDescription |
| value            | AXValue                 |

Role aliases will be defined (e.g. `input → AXTextField`).

---

## 7. Auto-Waiting Model

### 7.1 Default Behavior

All actions and assertions implicitly wait for:

* Element existence
* Element visibility
* Element enabled state

### 7.2 Wait Conditions

* `exists`
* `visible`
* `enabled`
* `value == expected`

### 7.3 Implementation

* Polling-based (v1)
* Event-driven (AX notifications) in v2

---

## 8. Actions API

### 8.1 Supported Actions (v1)

* click
* doubleClick
* type
* clear
* pressKey
* select
* focus

### 8.2 Failure Semantics

* Action retries until timeout
* Detailed error on failure

---

## 9. Assertions & Expectations

### 9.1 Expect API

Examples:

* `expect(locator).toExist()`
* `expect(locator).toHaveText("Welcome")`
* `expect(window).toBeFocused()`

### 9.2 Assertion Failures

* Include selector
* Include AX snapshot (debug mode)

---

## 10. Page & Locator Model

### 10.1 Page

Represents a single attached application instance.

Responsibilities:

* Root AX tree
* Global queries
* App lifecycle (launch, terminate)

### 10.2 Locator

* Lazy evaluation
* Immutable
* Auto-waiting

---

## 11. Error Model

### 11.1 Error Types

* PermissionDenied
* AppNotFound
* ElementNotFound
* Timeout
* ActionFailed
* InvalidSelector

Errors are structured and serializable.

---

## 12. CLI Interface

### 12.1 Commands

* attach <bundle-id>
* click <selector>
* type <selector> <text>
* expect <selector> exists

### 12.2 Use Cases

* CI smoke tests
* Debugging selectors
* Manual automation

---

## 13. JSON-RPC Protocol (v1)

### 13.1 Transport

* STDIN / STDOUT
* WebSocket (optional)

### 13.2 Example

```
{"id":1,"method":"click","params":{"selector":"button#login"}}
```

---

## 14. Security & Permissions

* Requires Accessibility permission
* No sandbox escape
* Explicit user consent

---

## 15. Performance Considerations

* AX tree caching
* Selector pruning
* Bounded retries

---

## 16. Testing Strategy

* Unit tests for selector parsing
* Mock AX layer
* Golden selector tests
* End-to-end automation tests

---

## 17. Roadmap

### v1 (MVP)

* Core AX wrapper
* Selector engine
* Click/type actions
* Auto-wait polling
* CLI

### v2

* AX notifications
* Rich selectors
* JSON-RPC server

### v3

* Node.js client
* Parallel sessions
* Debug inspector

---

## 18. Open Questions

* First-match vs multi-match semantics
* Snapshot debugging format
* Selector backward compatibility

---

## 19. Conclusion

MacPlaywright provides a modern, extensible foundation for macOS UI automation using Accessibility APIs. This RFC defines a clear, phased path toward a Playwright-class experience while respecting macOS platform constraints.
