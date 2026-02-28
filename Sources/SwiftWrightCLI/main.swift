import Foundation
import SwiftWright

// MARK: - CLI entry point

let semaphore = DispatchSemaphore(value: 0)

Task {
    let args = Array(CommandLine.arguments.dropFirst())
    do {
        try await CLI.run(args: args)
    } catch {
        fputs("error: \(error)\n", stderr)
        semaphore.signal()
        exit(1)
    }
    semaphore.signal()
}

semaphore.wait()

// MARK: - Command implementations

enum CLI {
    static func run(args: [String]) async throws {
        guard let command = args.first else {
            printUsage()
            return
        }

        switch command {
        case "attach":
            try runAttach(args: Array(args.dropFirst()))

        case "click":
            try await runClick(args: Array(args.dropFirst()))

        case "type":
            try await runType(args: Array(args.dropFirst()))

        case "expect":
            try await runExpect(args: Array(args.dropFirst()))

        case "tree":
            try runTree(args: Array(args.dropFirst()))

        case "--help", "-h", "help":
            printUsage()

        default:
            fputs("Unknown command: \(command)\n", stderr)
            printUsage()
            exit(1)
        }
    }

    // MARK: attach

    static func runAttach(args: [String]) throws {
        guard let bundleID = args.first else {
            throw CLIError.usage("attach <bundle-id>")
        }
        let page = try Page.attach(bundleID: bundleID)
        print("Attached to \(bundleID) (pid \(page.pid))")
    }

    // MARK: click

    static func runClick(args: [String]) async throws {
        guard args.count >= 2 else {
            throw CLIError.usage("click <bundle-id> <selector>")
        }
        let bundleID = args[0]
        let selector = args[1]
        let page = try Page.attach(bundleID: bundleID)
        try await page.locator(selector).click()
        print("Clicked: \(selector)")
    }

    // MARK: type

    static func runType(args: [String]) async throws {
        guard args.count >= 3 else {
            throw CLIError.usage("type <bundle-id> <selector> <text>")
        }
        let bundleID = args[0]
        let selector = args[1]
        let text = args[2]
        let page = try Page.attach(bundleID: bundleID)
        try await page.locator(selector).type(text)
        print("Typed '\(text)' into: \(selector)")
    }

    // MARK: expect

    static func runExpect(args: [String]) async throws {
        guard args.count >= 3 else {
            throw CLIError.usage("expect <bundle-id> <selector> <condition>")
        }
        let bundleID = args[0]
        let selector = args[1]
        let condition = args[2]
        let page = try Page.attach(bundleID: bundleID)
        let locator = page.locator(selector)

        switch condition {
        case "exists":
            try await expect(locator).toExist()
            print("✓ \(selector) exists")
        case "not-exists", "notExists":
            try await expect(locator).toNotExist()
            print("✓ \(selector) does not exist")
        case "enabled":
            try await expect(locator).toBeEnabled()
            print("✓ \(selector) is enabled")
        case "focused":
            try await expect(locator).toBeFocused()
            print("✓ \(selector) is focused")
        default:
            throw CLIError.unknownCondition(condition)
        }
    }

    // MARK: tree

    static func runTree(args: [String]) throws {
        guard let bundleID = args.first else {
            throw CLIError.usage("tree <bundle-id>")
        }
        let page = try Page.attach(bundleID: bundleID)
        print(page.treeSnapshot())
    }

    // MARK: Usage

    static func printUsage() {
        print("""
        swift-wright — macOS UI automation via Accessibility APIs

        Usage: swift-wright <command> [arguments]

        Commands:
          attach <bundle-id>                          Verify attachment to a running app
          click  <bundle-id> <selector>               Click a UI element
          type   <bundle-id> <selector> <text>        Type text into a UI element
          expect <bundle-id> <selector> <condition>   Assert a condition on an element
          tree   <bundle-id>                          Print the accessibility tree

        Conditions for `expect`:
          exists       Element is present in the AX tree
          not-exists   Element is absent from the AX tree
          enabled      Element is enabled
          focused      Element has focus

        Selector examples:
          button                              Any button
          button#login                        Button with identifier "login"
          textfield[title=Username]           Text field with exact title "Username"
          window dialog button#confirm        Nested: confirm button inside a dialog
          button[title~=Save]                 Button whose title contains "Save"
        """)
    }
}

// MARK: - CLI-specific errors

enum CLIError: Error, CustomStringConvertible {
    case usage(String)
    case unknownCondition(String)

    var description: String {
        switch self {
        case .usage(let cmd):
            return "Usage: swift-wright \(cmd)"
        case .unknownCondition(let c):
            return "Unknown condition '\(c)'. Valid: exists, not-exists, enabled, focused"
        }
    }
}
