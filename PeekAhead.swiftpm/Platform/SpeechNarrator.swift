import AVFoundation

/// Reads story text aloud with the on-device system voice and reports each word as it is spoken.
///
/// Uses the `.playback` audio category with the `.spokenAudio` mode: narration only ever starts when the
/// child taps Read, and it should be heard even when the device's silent switch is on.
@MainActor
final class SpeechNarrator: NSObject, Narrating {
    /// The grown-up's narration speed, read each time narration starts (0.9× the system rate by default).
    private let speed: @MainActor () -> NarrationSpeed
    private let synthesizer = AVSpeechSynthesizer()
    private var continuation: AsyncStream<NarrationEvent>.Continuation?
    /// Kept alive while speaking, so a late callback from an older utterance can be told apart.
    private var currentUtterance: AVSpeechUtterance?

    init(speed: @escaping @MainActor () -> NarrationSpeed = { .calm }) {
        self.speed = speed
        super.init()
        synthesizer.delegate = self
    }

    func narrate(_ text: String, language: String) -> AsyncStream<NarrationEvent> {
        stop()
        activateAudioSession()

        let (stream, continuation) = AsyncStream<NarrationEvent>.makeStream()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * speed().rateFactor
        utterance.preUtteranceDelay = 0.15
        if utterance.voice == nil {
            Log.narration.notice("No voice for \(language, privacy: .public); using the system default")
        }

        self.continuation = continuation
        currentUtterance = utterance
        synthesizer.speak(utterance)
        return stream
    }

    func stop() {
        currentUtterance = nil
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        end(with: .cancelled)
    }

    fileprivate func deliver(_ event: NarrationEvent, from utterance: ObjectIdentifier) {
        guard let current = currentUtterance, ObjectIdentifier(current) == utterance else { return }
        switch event {
        case .finished, .cancelled:
            currentUtterance = nil
            end(with: event)
        case .started, .willSpeak:
            continuation?.yield(event)
        }
    }

    private func end(with event: NarrationEvent) {
        continuation?.yield(event)
        continuation?.finish()
        continuation = nil
    }

    private func activateAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            Log.narration.error("Audio session failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}

// Delegate callbacks are not guaranteed to arrive on the main actor, so each one hops there explicitly.
extension SpeechNarrator: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.deliver(.started, from: id) }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        guard let range = Range<Int>(characterRange) else { return }
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.deliver(.willSpeak(utf16Range: range), from: id) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.deliver(.finished, from: id) }
    }
}
