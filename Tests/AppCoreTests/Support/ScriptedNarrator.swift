import Foundation

@testable import AppCore

/// A narrator whose events are sent by the test, one at a time.
@MainActor
final class ScriptedNarrator: Narrating {
    private(set) var spokenTexts: [String] = []
    private(set) var stopCount = 0
    private var continuation: AsyncStream<NarrationEvent>.Continuation?

    func narrate(_ text: String, language: String) -> AsyncStream<NarrationEvent> {
        spokenTexts.append(text)
        let (stream, continuation) = AsyncStream<NarrationEvent>.makeStream()
        self.continuation = continuation
        return stream
    }

    func stop() {
        stopCount += 1
        continuation?.yield(.cancelled)
        continuation?.finish()
        continuation = nil
    }

    func send(_ event: NarrationEvent) {
        continuation?.yield(event)
    }

    func finish() {
        continuation?.yield(.finished)
        continuation?.finish()
        continuation = nil
    }
}

/// Lets queued main-actor work run until `condition` holds, or fails after a bounded number of turns.
@MainActor
func waitUntil(_ condition: () -> Bool, turns: Int = 100) async -> Bool {
    for _ in 0..<turns {
        if condition() { return true }
        await Task.yield()
    }
    return condition()
}
