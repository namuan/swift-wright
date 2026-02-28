import Foundation

/// Polling-based auto-waiter used by ``Locator`` and ``Expectation``.
///
/// Every action and assertion in SwiftWright implicitly waits via this mechanism
/// before interacting with an element or asserting its state.
public enum AutoWaiter {

    // MARK: - Core polling loop

    /// Polls `condition` every `pollInterval` until it returns a non-nil value or
    /// `timeout` elapses.
    ///
    /// - Parameters:
    ///   - timeout: Maximum total wait time in seconds.
    ///   - pollInterval: Delay between polls in seconds (default 100 ms).
    ///   - selector: The selector string, used only for the error message.
    ///   - condition: A closure that returns a value on success or `nil` to retry.
    /// - Returns: The first non-nil value returned by `condition`.
    /// - Throws: ``WrightError/timeout(_:after:)`` if the deadline passes without success.
    @discardableResult
    public static func waitFor<T>(
        timeout: TimeInterval,
        pollInterval: TimeInterval = 0.1,
        selector: String,
        _ condition: () throws -> T?
    ) async throws -> T {
        let deadline = Date().addingTimeInterval(timeout)
        var lastError: Error?

        while Date() < deadline {
            do {
                if let result = try condition() {
                    return result
                }
            } catch {
                lastError = error
            }
            try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }

        // Prefer a richer upstream error if we have one.
        if let err = lastError { throw err }
        throw WrightError.timeout(selector: selector, after: timeout)
    }

    /// Polls `condition` expecting `true` (for assertion-style waits).
    public static func waitUntil(
        timeout: TimeInterval,
        pollInterval: TimeInterval = 0.1,
        selector: String,
        _ condition: () throws -> Bool
    ) async throws {
        try await waitFor(timeout: timeout, pollInterval: pollInterval, selector: selector) {
            try condition() ? true : nil
        }
    }
}
