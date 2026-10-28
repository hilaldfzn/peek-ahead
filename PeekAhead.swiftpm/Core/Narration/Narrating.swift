import Foundation

/// Progress of one narration, in the order it happens.
enum NarrationEvent: Equatable, Sendable {
    case started
    /// The narrator is about to speak the text at these UTF-16 offsets.
    case willSpeak(utf16Range: Range<Int>)
    case finished
    case cancelled
}

/// Reads text aloud. The app uses `SpeechNarrator` (AVFoundation); tests use a scripted fake.
@MainActor
protocol Narrating: AnyObject {
    /// Starts reading `text` and streams its progress. Starting a new narration cancels the current one.
    func narrate(_ text: String, language: String) -> AsyncStream<NarrationEvent>
    /// Stops reading immediately. Safe to call when nothing is being read.
    func stop()
}
